import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/weather_card.dart';
import '../widgets/forecast_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/headers.dart';
import '../widgets/weather_background.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherData? _weather;
  ForecastData? _forecast;
  List<WeatherAlert> _alerts = [];
  bool _isLoading = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weather = await WeatherService.getCurrentWeather();
      final forecast = await WeatherService.getForecast();
      final alerts = await AlertService.getActiveAlerts();

      if (mounted) {
        setState(() {
          _weather = weather;
          _forecast = forecast;
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Unable to retrieve real-time weather data. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: '🌦 WeatherGPT'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
        backgroundColor: AppColors.primary,
        tooltip: 'Ask WeatherGPT',
        child: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 26),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WeatherBackground(
              temperature: _weather?.currentTemp,
            ),
          ),
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.error),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(LucideIcons.refreshCw),
                          label: const Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_weather != null) WeatherCard(data: _weather!),
                  if (_alerts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        children: _alerts.map((alert) => AlertCard(alert: alert)).toList(),
                      ),
                    ),
                  if (_forecast != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Today\'s Forecast'),
                          ForecastCard(data: _forecast!),
                        ],
                      ),
                    ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
