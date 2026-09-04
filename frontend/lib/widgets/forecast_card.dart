import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ForecastCard extends StatelessWidget {
  final ForecastData data;

  const ForecastCard({super.key, required this.data});

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'cloud-sun': return LucideIcons.cloudSun;
      case 'cloud-rain': return LucideIcons.cloudRain;
      case 'cloud-lightning': return LucideIcons.cloudLightning;
      case 'cloud': return LucideIcons.cloud;
      case 'sun': return LucideIcons.sun;
      default: return LucideIcons.cloudSun;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Forecast', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          ...data.daily.take(7).map((day) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 2, child: Text(day.day, style: Theme.of(context).textTheme.bodyLarge)),
                Expanded(
                  child: Center(
                    child: Icon(_getIcon(day.icon), color: AppColors.primary, size: 24),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text('${day.minTemp}°', textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [AppColors.info, AppColors.secondary],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        child: Text('${day.maxTemp}°', textAlign: TextAlign.left, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
