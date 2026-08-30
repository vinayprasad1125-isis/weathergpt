import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AlertCard extends StatelessWidget {
  final WeatherAlert alert;
  final VoidCallback? onPress;

  const AlertCard({super.key, required this.alert, this.onPress});

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'Extreme':
        return AppColors.alertExtreme;
      case 'Severe':
        return AppColors.alertSevere;
      case 'Moderate':
        return AppColors.alertModerate;
      case 'Minor':
        return AppColors.alertMinor;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getSeverityColor(alert.severity);

    return InkWell(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: bgColor, width: 6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.alertTriangle, color: bgColor, size: 20),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${alert.severity.toUpperCase()} WEATHER ALERT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: bgColor),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(alert.type, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.xs),
            Text(alert.location, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              alert.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'View details →',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      ),
    );
  }
}
