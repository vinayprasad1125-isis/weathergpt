import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../models/news_article.dart';
import '../services/api_news_service.dart';
import '../services/demo_alert_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/headers.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  String? _selectedState;
  List<NewsArticle> _articles = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetched;

  @override
  void initState() {
    super.initState();
    // Listen for demo mode toggles so the list updates immediately.
    DemoAlertManager.instance.isDemoMode.addListener(_onDemoModeChanged);
  }

  @override
  void dispose() {
    DemoAlertManager.instance.isDemoMode.removeListener(_onDemoModeChanged);
    super.dispose();
  }

  void _onDemoModeChanged() {
    if (_selectedState != null) _fetchNews(forceRefresh: true);
  }

  Future<void> _fetchNews({bool forceRefresh = false}) async {
    final state = _selectedState;
    if (state == null) return;

    // In demo mode, return fake articles without hitting the API.
    if (DemoAlertManager.instance.isDemoMode.value) {
      setState(() {
        _articles = ApiNewsService.getDemoArticles(state);
        _isLoading = false;
        _error = null;
        _lastFetched = DateTime.now();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final articles = await ApiNewsService.fetchNewsForState(
        state,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _isLoading = false;
        _lastFetched = ApiNewsService.lastFetched(state);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const AppHeader(
        title: '📰 Weather News',
      ),
      body: Column(
        children: [
          // ── State Dropdown ──────────────────────────────────────────────────
          Container(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text(
                              'Select Indian State',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            value: _selectedState,
                            icon: const Icon(LucideIcons.chevronDown, size: 20),
                            onChanged: (state) {
                              if (state == null) return;
                              setState(() {
                                _selectedState = state;
                                _articles = [];
                                _error = null;
                              });
                              _fetchNews();
                            },
                            items: AppConstants.indianStates.keys
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    if (_selectedState != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.refreshCw, size: 18),
                          tooltip: 'Refresh news',
                          onPressed: _isLoading ? null : () => _fetchNews(forceRefresh: true),
                        ),
                      ),
                    ],
                  ],
                ),
                // Last updated label
                if (_lastFetched != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${_timeAgo(_lastFetched)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.right,
                  ),
                ],
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────────
          Expanded(child: _buildBody(isDark, cardColor)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, Color cardColor) {
    // No state selected
    if (_selectedState == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.newspaper, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'Select a state to view weather news',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Loading
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Fetching $_selectedState weather news…',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Error
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.cloudOff, size: 64, color: AppColors.error.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'Weather news is temporarily unavailable.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _fetchNews(forceRefresh: true),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty
    if (_articles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.searchX, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text(
                'No recent weather news found for $_selectedState.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _fetchNews(forceRefresh: true),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Article list
    final isDemoMode = DemoAlertManager.instance.isDemoMode.value;
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _articles.length + 1, // +1 for the header subtitle
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Latest weather news for $_selectedState',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                if (isDemoMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.warning.withOpacity(0.5)),
                    ),
                    child: Text(
                      'DEMO MODE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
              ],
            ),
          );
        }
        return _NewsCard(
          article: _articles[index - 1],
          isDark: isDark,
          cardColor: cardColor,
        );
      },
    );
  }
}

// ─── News Card Widget ──────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool isDark;
  final Color cardColor;

  const _NewsCard({required this.article, required this.isDark, required this.cardColor});

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open article link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl != null && article.imageUrl!.isNotEmpty;
    final hasLink = article.link != null && article.link!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.07) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Article image
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                article.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    height: 180,
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  article.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Description
                if (article.description != null && article.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    article.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Source & time row
                Row(
                  children: [
                    const Icon(LucideIcons.newspaper, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        article.sourceName ?? article.sourceId ?? 'Unknown source',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (article.publishedAt != null) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.clock, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        _timeAgo(article.publishedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),

                // Read More button
                if (hasLink) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _openLink(context, article.link!),
                      icon: const Icon(LucideIcons.externalLink, size: 15),
                      label: const Text('Read More'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: AppColors.primary, width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
