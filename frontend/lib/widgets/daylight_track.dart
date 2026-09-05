import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class DaylightTrack extends StatelessWidget {
  final WeatherData weather;

  const DaylightTrack({super.key, required this.weather});

  double _calculateDayProgress() {
    // A simplified version that calculates progress based on current time
    // For demo purposes, we will return 50 if times aren't parsed correctly.
    final now = DateTime.now();
    
    int? parseTime(String timeStr) {
      try {
        final parts = timeStr.split(RegExp(r'[:\s]'));
        if (parts.length < 3) return null;
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        String ampm = parts[2].toUpperCase();
        if (ampm == 'AM' && hour == 12) hour = 0;
        if (ampm == 'PM' && hour != 12) hour += 12;
        return hour * 60 + minute;
      } catch (e) {
        return null;
      }
    }

    final start = parseTime(weather.sunrise);
    final end = parseTime(weather.sunset);
    if (start == null || end == null || end <= start) return 50.0;
    
    final current = now.hour * 60 + now.minute;
    if (current <= start) return 0.0;
    if (current >= end) return 100.0;
    
    return ((current - start) / (end - start)) * 100.0;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateDayProgress();
    
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sunrise, size: 20, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sunrise', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                      Text(weather.sunrise, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Sunset', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
                      Text(weather.sunset, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(LucideIcons.sunset, size: 20, color: AppColors.primary),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              return SizedBox(
                height: 24,
                width: trackWidth,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 4,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: AppColors.border.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Container(
                      height: 4,
                      width: trackWidth * (progress / 100),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Positioned(
                      left: (trackWidth * (progress / 100)) - 12,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Theme.of(context).cardColor, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
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
