import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class HourlyRibbon extends StatefulWidget {
  final List<HourlyForecast> hourly;

  const HourlyRibbon({super.key, required this.hourly});

  @override
  State<HourlyRibbon> createState() => _HourlyRibbonState();
}

class _HourlyRibbonState extends State<HourlyRibbon> {
  int _selectedIndex = 0;

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
    if (widget.hourly.isEmpty) return const SizedBox();

    final activeHour = widget.hourly[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Next hours', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                    Text('How the afternoon unfolds', style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: widget.hourly.length,
                  itemBuilder: (context, index) {
                    final hour = widget.hourly[index];
                    final isActive = index == _selectedIndex;
                    String displayTime = hour.time;
                    if (displayTime.contains('T')) {
                      displayTime = displayTime.split('T')[1].substring(0, 5); // Just HH:mm
                    }
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: Container(
                        width: 70,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: isActive ? null : Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(displayTime, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isActive ? Colors.white : AppColors.textSecondary, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                            const SizedBox(height: AppSpacing.xs),
                            Icon(_getIcon(hour.icon), color: isActive ? Colors.white : AppColors.primary, size: 28),
                            const SizedBox(height: AppSpacing.xs),
                            Text('${hour.temp}°', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isActive ? Colors.white : AppColors.text, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(_getIcon(activeHour.icon), size: 36, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(activeHour.time.contains('T') ? activeHour.time.split('T')[1].substring(0, 5) : activeHour.time, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: AppSpacing.sm),
                                Text(activeHour.condition, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text('Conditions change slightly. Chance of rain: ${activeHour.precipitationProb}%', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text('${activeHour.temp}°', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
