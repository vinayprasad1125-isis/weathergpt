import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class WeatherMetricsGrid extends StatelessWidget {
  final WeatherData weather;

  const WeatherMetricsGrid({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      {'label': 'Humidity', 'value': '${weather.humidity}%', 'note': weather.humidity > 70 ? 'Moist air' : 'Comfortable', 'icon': LucideIcons.droplets},
      {'label': 'Wind', 'value': '${weather.windSpeed} km/h', 'note': 'From ${weather.windDirection}', 'icon': LucideIcons.wind},
      {'label': 'Visibility', 'value': '${weather.visibility} km', 'note': weather.visibility < 5 ? 'Reduced' : 'Good', 'icon': LucideIcons.eye},
      {'label': 'Pressure', 'value': '${weather.pressure} hPa', 'note': 'Sea level', 'icon': LucideIcons.gauge},
      {'label': 'UV index', 'value': '${weather.uvIndex}', 'note': weather.uvIndex >= 6 ? 'Protection needed' : 'Moderate', 'icon': LucideIcons.waves},
      {'label': 'Cloud cover', 'value': '${weather.cloudCoverage}%', 'note': weather.condition, 'icon': LucideIcons.cloudRain},
      {'label': 'Rain chance', 'value': '${weather.precipitationProb}%', 'note': 'Next period', 'icon': LucideIcons.umbrella},
      {'label': 'Wind bearing', 'value': weather.windDirection, 'note': 'Surface wind', 'icon': LucideIcons.compass},
    ];

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('At a glance', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                  Text('Conditions around you', style: Theme.of(context).textTheme.displaySmall),
                ],
              ),
              Text('Updated from service', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              mainAxisExtent: 90,
            ),
            itemCount: metrics.length,
            itemBuilder: (context, index) {
              final metric = metrics[index];
              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(metric['icon'] as IconData, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(metric['label'] as String, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(metric['value'] as String, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(metric['note'] as String, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontSize: 10), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
