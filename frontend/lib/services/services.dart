import 'dart:async';
import '../models/models.dart';
import '../mock/mock_data.dart';
import 'api_weather_service.dart';
import 'api_chat_service.dart';
import 'api_alert_service.dart';
import 'api_location_service.dart';
import 'api_advisory_service.dart';
import 'package:flutter/foundation.dart';

class WeatherService {
  static Future<WeatherData> getCurrentWeather([String? locationId]) async {
    try {
      return await ApiWeatherService.getCurrentWeather(city: 'Chennai');
    } catch (e) {
      debugPrint('Error getting current weather, falling back to mock data: $e');
      return mockWeatherData;
    }
  }

  static Future<ForecastData> getForecast([String? locationId]) async {
    try {
      return await ApiWeatherService.getForecast('Chennai');
    } catch (e) {
      debugPrint('Error getting forecast, falling back to mock data: $e');
      return mockForecastData;
    }
  }

  static Future<List<Location>> searchLocations(String query) async {
    try {
      return await ApiLocationService.searchLocations(query);
    } catch (e) {
      debugPrint('Error searching locations: $e');
      rethrow;
    }
  }
}

class AlertService {
  static Future<List<WeatherAlert>> getActiveAlerts([String? locationId]) async {
    try {
      return await ApiAlertService.getActiveAlerts(locationId, 13.0827, 80.2707);
    } catch (e) {
      debugPrint('Error fetching active alerts, falling back to mock data: $e');
      return mockAlerts; 
    }
  }
}

class AdvisoryService {
  static Future<List<Advisory>> getAdvisories([String? locationId]) async {
    try {
      // Fetch multiple domains to populate the UI screen. Assuming Chennai for demo.
      final ag = await ApiAdvisoryService.getAdvisory('agriculture', 13.0827, 80.2707);
      final av = await ApiAdvisoryService.getAdvisory('aviation', 13.0827, 80.2707);
      final mar = await ApiAdvisoryService.getAdvisory('marine', 13.0827, 80.2707);
      final urb = await ApiAdvisoryService.getAdvisory('urban', 13.0827, 80.2707);
      final dis = await ApiAdvisoryService.getAdvisory('disaster', 13.0827, 80.2707);
      return [...ag, ...av, ...mar, ...urb, ...dis];
    } catch (e) {
      debugPrint('Error getting advisories, falling back to mock data: $e');
      return mockAdvisories;
    }
  }
}

class ClimateService {
  static Future<ClimateData> getClimateTrends([String? locationId]) async {
    // Note: Typically ClimateService would call an API, but since this wasn't implemented 
    // to call the API in this file earlier, we will just throw an unimplemented error
    // until it's connected (api_climate_service is used directly in screens).
    throw Exception('Not implemented in services.dart');
  }
}

class ChatService {
  static Future<List<ChatMessage>> sendMessage(String message, String languageCode) async {
    try {
      return await ApiChatService.sendMessage(message, languageCode);
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      rethrow;
    }
  }
}
