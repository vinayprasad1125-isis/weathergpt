import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../main.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  late Future<ForecastData> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = WeatherService.getForecast();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'sun':
        return LucideIcons.sun;
      case 'cloud':
        return LucideIcons.cloud;
      case 'cloud-rain':
        return LucideIcons.cloudRain;
      case 'cloud-lightning':
        return LucideIcons.cloudLightning;
      case 'cloud-snow':
        return LucideIcons.cloudSnow;
      default:
        return LucideIcons.cloudSun;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigator()),
              );
            }
          },
        ),
        title: Text(
          '7-Day Forecast',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
        centerTitle: true,
      ),
      body: FutureBuilder<ForecastData>(
        future: _forecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.error),
              ),
            );
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text('No forecast available.', style: theme.textTheme.bodyLarge),
            );
          }

          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _forecastFuture = WeatherService.getForecast();
              });
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHourlySection(context, data.hourly),
                const SizedBox(height: 24),
                Text(
                  'Daily Forecast',
                  style: theme.textTheme.displaySmall,
                ),
                const SizedBox(height: 12),
                _buildDailySection(context, data.daily),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourlySection(BuildContext context, List<HourlyForecast> hourly) {
    final theme = Theme.of(context);
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final item = hourly[index];
          String displayTime = item.time;
          if (displayTime.contains('T')) {
            displayTime = displayTime.split('T')[1];
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Icon(_getIconData(item.icon), color: AppColors.primary, size: 28),
                const SizedBox(height: 12),
                Text(
                  '${item.temp}°',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.precipitationProb}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySection(BuildContext context, List<DailyForecast> daily) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daily.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: AppColors.divider,
        ),
        itemBuilder: (context, index) {
          final item = daily[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    item.day,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Icon(_getIconData(item.icon), color: AppColors.primary, size: 24),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${item.precipitationProb}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${item.minTemp}°',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${item.maxTemp}°',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
