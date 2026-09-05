import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiWeatherService {
  static Future<WeatherData> getCurrentWeather({String? city, double? lat, double? lon}) async {
    try {
      String query = '';
      List<String> queryParams = [];
      if (city != null) {
        queryParams.add('city=${Uri.encodeComponent(city)}');
      }
      if (lat != null && lon != null) {
        queryParams.add('lat=$lat&lon=$lon');
      }
      query = queryParams.join('&');
      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/weather/current?$query');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'];
        final loc = data['location'];
        final sun = data['sun'];

        return WeatherData(
          location: Location(
            id: 'api-loc',
            city: loc['name'],
            country: loc['country'],
            latitude: loc['latitude'],
            longitude: loc['longitude'],
            isCurrentLocation: true,
          ),
          currentTemp: (current['temperature'] as num).round(),
          feelsLike: (current['feels_like'] as num).round(),
          condition: current['condition'],
          humidity: (current['humidity'] as num).round(),
          windSpeed: (current['wind_speed'] as num).round(),
          windDirection: current['wind_direction'],
          visibility: (current['visibility'] as num).round(),
          pressure: (current['pressure'] as num).round(),
          uvIndex: (current['uv_index'] as num).round(),
          sunrise: sun['sunrise'],
          sunset: sun['sunset'],
          cloudCoverage: (current['cloud_cover'] as num).round(),
          precipitationProb: (current['precipitation_probability'] as num?)?.round() ?? 0,
          icon: _mapConditionToIcon(current['condition']),
        );
      } else {
        debugPrint('Weather API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
      rethrow;
    }
  }

  static String _mapConditionToIcon(String condition) {
    final lower = condition.toLowerCase();
    if (lower.contains('rain')) return 'cloud-rain';
    if (lower.contains('snow')) return 'cloud-snow';
    if (lower.contains('thunderstorm')) return 'cloud-lightning';
    if (lower.contains('cloud') || lower.contains('overcast')) return 'cloud';
    if (lower.contains('clear')) return 'sun';
    return 'cloud-sun';
  }

  static Future<ForecastData> getForecast(String city) async {
    try {
      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/weather/forecast?city=${Uri.encodeComponent(city)}');
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final List<HourlyForecast> hourly = (data['hourly'] as List).map((h) => HourlyForecast(
          time: h['time'],
          temp: (h['temperature'] as num).round(),
          condition: h['condition'],
          icon: _mapConditionToIcon(h['condition']),
          precipitationProb: (h['precipitation_probability'] as num).round(),
        )).toList();

        final List<DailyForecast> daily = (data['daily'] as List).map((d) => DailyForecast(
          date: d['date'],
          day: _getDayOfWeek(d['date']),
          minTemp: (d['temperature_min'] as num).round(),
          maxTemp: (d['temperature_max'] as num).round(),
          condition: d['condition'],
          icon: _mapConditionToIcon(d['condition']),
          precipitationProb: (d['precipitation_probability'] as num).round(),
        )).toList();

        return ForecastData(
          hourly: hourly,
          daily: daily,
        );
      } else {
        debugPrint('Weather Forecast API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
      rethrow;
    }
  }

  static String _getDayOfWeek(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } catch (e) {
      return dateString.substring(0, 10);
    }
  }
}
