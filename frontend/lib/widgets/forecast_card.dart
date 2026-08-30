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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hourly Forecast', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: data.hourly.map((hour) {
                  String displayTime = hour.time;
                  if (displayTime.contains('T')) {
                    displayTime = displayTime.split('T')[1];
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: Column(
                      children: [
                        Text(displayTime, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.xs),
                        Icon(_getIcon(hour.icon), color: AppColors.info, size: 24),
                        const SizedBox(height: AppSpacing.xs),
                        Text('${hour.temp}°', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(color: AppColors.border),
            ),
            Text('Daily Forecast', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.sm),
            ...data.daily.take(3).map((day) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(day.day, style: Theme.of(context).textTheme.bodyLarge)),
                  Row(
                    children: [
                      Icon(_getIcon(day.icon), color: AppColors.info, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${day.maxTemp}° / ${day.minTemp}°',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
