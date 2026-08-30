import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/services.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('7-Day Forecast', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<ForecastData>(
        future: _forecastFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No forecast available.'));
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
                _buildHourlySection(data.hourly),
                const SizedBox(height: 24),
                const Text('Daily Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildDailySection(data.daily),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHourlySection(List<HourlyForecast> hourly) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourly.length,
        itemBuilder: (context, index) {
          final item = hourly[index];
          // Time parsing assumes format like "2023-10-25T14:00"
          String displayTime = item.time;
          if (displayTime.contains('T')) {
            displayTime = displayTime.split('T')[1];
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(displayTime, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
                const SizedBox(height: 12),
                Icon(_getIconData(item.icon), color: Colors.blue, size: 28),
                const SizedBox(height: 12),
                Text('${item.temp}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                if (item.precipitationProb > 0)
                  Text('${item.precipitationProb}%', style: const TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailySection(List<DailyForecast> daily) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: daily.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.black12),
        itemBuilder: (context, index) {
          final item = daily[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(item.day, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Icon(_getIconData(item.icon), color: Colors.blue, size: 24),
                      if (item.precipitationProb > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text('${item.precipitationProb}%', style: const TextStyle(color: Colors.blue, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${item.minTemp}°', style: const TextStyle(color: Colors.black54, fontSize: 16)),
                      const SizedBox(width: 12),
                      Text('${item.maxTemp}°', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
