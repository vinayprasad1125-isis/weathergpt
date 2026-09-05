import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../models/news_article.dart';

/// In-memory cache entry to avoid redundant API calls.
class _CacheEntry {
  final List<NewsArticle> articles;
  final DateTime fetchedAt;
  _CacheEntry(this.articles) : fetchedAt = DateTime.now();

  bool get isStale =>
      DateTime.now().difference(fetchedAt).inMinutes > 15;
}

class ApiNewsService {
  static const String _baseUrl = 'https://newsdata.io/api/1/news';

  /// Weather-related keywords for the query.
  static const List<String> _weatherKeywords = [
    'weather',
    'rainfall',
    'cyclone',
    'storm',
    'monsoon',
    'heatwave',
    'flood',
    'warning',
    'IMD',
    'precipitation',
  ];

  // In-memory cache keyed by state name.
  static final Map<String, _CacheEntry> _cache = {};

  /// Returns the cached articles for [state] if they exist and are not stale.
  static List<NewsArticle>? getCached(String state) {
    final entry = _cache[state];
    if (entry != null && !entry.isStale) return entry.articles;
    return null;
  }

  /// Timestamp of last successful fetch for [state].
  static DateTime? lastFetched(String state) => _cache[state]?.fetchedAt;

  /// Fetches weather news for the given Indian [state] from NewsData.io.
  /// Throws on network errors or non-200 responses.
  static Future<List<NewsArticle>> fetchNewsForState(String state, {bool forceRefresh = false}) async {
    // Use cache unless stale or refresh forced
    if (!forceRefresh) {
      final cached = getCached(state);
      if (cached != null) return cached;
    }

    final apiKey = Config.newsDataApiKey;
    if (apiKey.isEmpty) {
      throw Exception('NEWSDATA_API_KEY is not configured. '
          'Run with --dart-define=NEWSDATA_API_KEY=your_key');
    }

    // NewsData.io free tier limits the 'q' parameter to 100 characters.
    // We use high-impact weather terms alongside the state name.
    const keywords = ['weather', 'rain', 'cyclone', 'monsoon', 'flood'];
    final keywordClause = keywords.join(' OR ');
    final query = '"$state" AND ($keywordClause)';

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'apikey': apiKey,
      'q': query,
      'country': 'in',
      'language': 'en',
    });

    debugPrint('[NewsService] GET $uri');

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('NewsData.io returned ${response.statusCode}: ${response.body}');
    }

    final body = json.decode(response.body) as Map<String, dynamic>;

    if (body['status'] != 'success') {
      final msg = body['results']?.toString() ?? 'Unknown error';
      throw Exception('NewsData.io error: $msg');
    }

    final rawArticles = (body['results'] as List?) ?? [];

    final articles = rawArticles
        .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
        .where((a) => _isRelevant(a, state))
        .toList();

    _cache[state] = _CacheEntry(articles);
    return articles;
  }

  /// Simple relevance check: article title or description must mention the state
  /// (case-insensitive) or a weather keyword.
  static bool _isRelevant(NewsArticle article, String state) {
    final stateLower = state.toLowerCase();
    final titleLower = (article.title).toLowerCase();
    final descLower = (article.description ?? '').toLowerCase();
    final combined = '$titleLower $descLower';

    // Must mention the state explicitly to avoid showing irrelevant national news.
    // Previously, it allowed any article mentioning "India" and a weather keyword,
    // which caused news about other states to bleed in.
    return combined.contains(stateLower);
  }

  /// Returns demo articles for when Demo Mode is on.
  static List<NewsArticle> getDemoArticles(String state) {
    return [
      NewsArticle(
        title: '[DEMO] Heavy rainfall warning issued for $state',
        description:
            'The India Meteorological Department (IMD) has issued a heavy rainfall warning for several districts in $state. '
            'Residents are advised to stay indoors and avoid flood-prone areas.',
        imageUrl: null,
        sourceId: 'demo_imd',
        sourceName: 'IMD (Demo)',
        link: 'https://mausam.imd.gov.in',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NewsArticle(
        title: '[DEMO] Cyclone alert: $state coast on high alert',
        description:
            'A deep depression in the Bay of Bengal is expected to intensify into a cyclone, posing a threat to the $state coastline. '
            'Fishermen have been warned not to venture out to sea.',
        imageUrl: null,
        sourceId: 'demo_ndtv',
        sourceName: 'NDTV Weather (Demo)',
        link: 'https://mausam.imd.gov.in',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NewsArticle(
        title: '[DEMO] Monsoon update: $state receives above-normal rainfall this season',
        description:
            'According to IMD data, $state has received 120% of normal monsoon rainfall this season, '
            'leading to improved reservoir levels but also flash flood concerns.',
        imageUrl: null,
        sourceId: 'demo_toi',
        sourceName: 'Times of India (Demo)',
        link: 'https://mausam.imd.gov.in',
        publishedAt: DateTime.now().subtract(const Duration(hours: 10)),
      ),
    ];
  }
}
