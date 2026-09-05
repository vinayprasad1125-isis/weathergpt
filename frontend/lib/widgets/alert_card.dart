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

  void _showDetails(BuildContext context, Color bgColor) {
    if (onPress != null) {
      onPress!();
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: bgColor, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        alert.type,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                    ),
                    IconButton(
                      icon: Icon(LucideIcons.x, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: bgColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: bgColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${alert.severity.toUpperCase()} SEVERITY',
                        style: TextStyle(color: bgColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (alert.source == 'NDMA SACHET')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NDMA SACHET',
                          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailRow(icon: LucideIcons.mapPin, label: 'Location', value: alert.location, context: context),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(icon: LucideIcons.clock, label: 'Time', value: alert.time, context: context),
                const SizedBox(height: AppSpacing.sm),
                _DetailRow(icon: LucideIcons.info, label: 'Status', value: alert.status, context: context),
                const SizedBox(height: AppSpacing.md),
                Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                Text('Description', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(alert.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.md),
                Text('Recommended Action', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(alert.recommendedAction, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getSeverityColor(alert.severity);

    return InkWell(
      onTap: () => _showDetails(context, bgColor),
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
                Expanded(
                  child: Text(
                    '${alert.severity.toUpperCase()} WEATHER ALERT',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: bgColor),
                  ),
                ),
                if (alert.source == 'NDMA SACHET')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NDMA SACHET',
                      style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (alert.isDemo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'DEMO',
                      style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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
              decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final BuildContext context;

  const _DetailRow({required this.icon, required this.label, required this.value, required this.context});

  @override
  Widget build(BuildContext _) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
