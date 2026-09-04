import 'package:flutter_test/flutter_test.dart';
import 'package:weathergpt_flutter/core/constants.dart';
import 'package:weathergpt_flutter/models/news_article.dart';
import 'package:weathergpt_flutter/services/api_news_service.dart';

void main() {
  group('NewsArticle Model', () {
    test('parses json correctly with full fields', () {
      final json = {
        'title': 'Heavy rains in Chennai',
        'description': 'IMD issues orange alert for coastal Tamil Nadu.',
        'image_url': 'https://example.com/image.jpg',
        'source_id': 'hindu',
        'source_name': 'The Hindu',
        'link': 'https://example.com/article1',
        'pubDate': '2025-09-04 12:00:00',
      };

      final article = NewsArticle.fromJson(json);

      expect(article.title, 'Heavy rains in Chennai');
      expect(article.description, 'IMD issues orange alert for coastal Tamil Nadu.');
      expect(article.imageUrl, 'https://example.com/image.jpg');
      expect(article.sourceId, 'hindu');
      expect(article.sourceName, 'The Hindu');
      expect(article.link, 'https://example.com/article1');
      expect(article.publishedAt, isNotNull);
      expect(article.publishedAt?.year, 2025);
    });

    test('parses json with null/missing optional fields safely', () {
      final json = <String, dynamic>{
        'title': 'Monsoon update',
      };

      final article = NewsArticle.fromJson(json);

      expect(article.title, 'Monsoon update');
      expect(article.description, isNull);
      expect(article.imageUrl, isNull);
      expect(article.sourceId, isNull);
      expect(article.sourceName, isNull);
      expect(article.link, isNull);
      expect(article.publishedAt, isNull);
    });
  });

  group('Shared Indian States Constants', () {
    test('contains expected states', () {
      expect(AppConstants.indianStates.containsKey('Tamil Nadu'), isTrue);
      expect(AppConstants.indianStates.containsKey('Kerala'), isTrue);
      expect(AppConstants.indianStates.containsKey('Maharashtra'), isTrue);
      expect(AppConstants.indianStates.containsKey('Delhi'), isTrue);
      expect(AppConstants.indianStates.length, greaterThanOrEqualTo(30));
    });
  });

  group('ApiNewsService Demo & Cache', () {
    test('getDemoArticles returns relevant articles containing state name', () {
      final articles = ApiNewsService.getDemoArticles('Karnataka');
      expect(articles, isNotEmpty);
      expect(articles.every((a) => a.title.contains('Karnataka') || (a.description?.contains('Karnataka') ?? false)), isTrue);
    });
  });
}
