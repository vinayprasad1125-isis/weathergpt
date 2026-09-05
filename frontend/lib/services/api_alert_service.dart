import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiAlertService {
  static Future<List<WeatherAlert>> getActiveAlerts([String? locationId, double? lat, double? lon]) async {
    try {
      final queryParams = <String, String>{};
      if (lat != null) queryParams['lat'] = lat.toString();
      if (lon != null) queryParams['lon'] = lon.toString();
      
      final uri = Uri.parse('${Config.apiBaseUrl}/api/v1/alerts').replace(queryParameters: queryParams);
      
      final response = await http.get(uri, headers: Config.apiHeaders).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => WeatherAlert(
          id: json['id'] ?? '',
          severity: json['severity'] ?? 'INFO',
          type: json['event_type'] ?? 'unknown',
          location: json['location']?['name'] ?? 'Unknown',
          time: json['issued_at'] ?? '',
          description: json['description'] ?? '',
          recommendedAction: (json['recommended_actions'] as List?)?.join('\n') ?? '',
          source: json['source']?['name'] ?? 'Unknown',
          status: json['status'] ?? 'ACTIVE',
        )).toList();
      } else {
        throw Exception('Failed to load active alerts');
      }
    } catch (e) {
      debugPrint('ApiAlertService Error: $e');
      rethrow;
    }
  }
}
