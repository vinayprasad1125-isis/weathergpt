import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/headers.dart';

class AdvisoriesScreen extends StatefulWidget {
  const AdvisoriesScreen({super.key});

  @override
  State<AdvisoriesScreen> createState() => _AdvisoriesScreenState();
}

class _AdvisoriesScreenState extends State<AdvisoriesScreen> {
  List<Advisory> _advisories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAdvisories();
  }

  Future<void> _loadAdvisories() async {
    try {
      final advisories = await AdvisoryService.getAdvisories();
      if (mounted) {
        setState(() {
          _advisories = advisories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to load advisories.";
        });
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'agriculture':
        return LucideIcons.leaf;
      case 'aviation':
        return LucideIcons.plane;
      case 'marine':
        return LucideIcons.anchor;
      case 'urban':
        return LucideIcons.building;
      case 'disaster':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.info;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'agriculture':
        return Colors.green;
      case 'aviation':
        return Colors.blue;
      case 'marine':
        return Colors.teal;
      case 'urban':
        return Colors.purple;
      case 'disaster':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Advisories'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                      const SizedBox(height: AppSpacing.md),
                      Text(_errorMessage!, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : _advisories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.checkCircle,
                            size: 64,
                            color: AppColors.success.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Active Advisories',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are no advisories for your area at this time.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
                      itemCount: _advisories.length,
                      itemBuilder: (context, index) {
                        final advisory = _advisories[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(advisory.category).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(advisory.category),
                                        color: _getCategoryColor(advisory.category),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            advisory.title,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '${advisory.category} • ${advisory.location}',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  advisory.details,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  children: [
                                    Icon(LucideIcons.thermometer, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(advisory.tempRange, style: TextStyle(color: AppColors.textSecondary)),
                                    const SizedBox(width: AppSpacing.md),
                                    Icon(LucideIcons.cloudRain, size: 16, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text('${advisory.rainProbability}% Rain', style: TextStyle(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
