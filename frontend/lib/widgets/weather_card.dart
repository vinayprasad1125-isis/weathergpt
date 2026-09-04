import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class WeatherCard extends StatelessWidget {
  final WeatherData data;

  const WeatherCard({super.key, required this.data});

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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 16, color: AppColors.text),
                  const SizedBox(width: 4),
                  Text(
                    data.location.city,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.card.withValues(alpha: 0.3)),
                ),
                child: const Text('Current observation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Icon(_getIcon(data.icon), size: 48, color: AppColors.text),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.condition,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      'Latest available conditions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.currentTemp}°',
                style: const TextStyle(fontSize: 84, fontWeight: FontWeight.bold, height: 1.0, letterSpacing: -2),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Feels like ${data.feelsLike}°C',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'High humidity is adding to the warmth.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.text.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
