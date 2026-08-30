import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData data;

  const WeatherCard({super.key, required this.data});

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'cloud-sun':
        return LucideIcons.cloudSun;
      case 'cloud-rain':
        return LucideIcons.cloudRain;
      case 'cloud-lightning':
        return LucideIcons.cloudLightning;
      case 'cloud':
        return LucideIcons.cloud;
      case 'sun':
        return LucideIcons.sun;
      default:
        return LucideIcons.cloudSun;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.location.city,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.surface),
            ),
            Text(
              data.condition,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.surface.withOpacity(0.9)),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${data.currentTemp}°C',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.surface),
                    ),
                    Text(
                      'Feels like ${data.feelsLike}°C',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface.withOpacity(0.8)),
                    ),
                  ],
                ),
                Icon(_getIcon(data.icon), size: 48, color: AppColors.surface),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.surface.withOpacity(0.2))),
              ),
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  Text('💧 ${data.humidity}%', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface)),
                  const SizedBox(width: AppSpacing.lg),
                  Text('💨 ${data.windSpeed} km/h', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.surface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
