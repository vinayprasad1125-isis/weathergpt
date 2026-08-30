import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiClimateService {
  static Future<Map<String, dynamic>> getClimateTrend(double lat, double lon) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/api/v1/climate/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "location": {
            "latitude": lat,
            "longitude": lon,
            "name": "Local"
          },
          "time_range": {
            "start": "2014-01-01",
            "end": "2023-12-31"
          },
          "parameter": "temperature",
          "analysis": "trend"
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Climate Service error: $e');
    }
    throw Exception('Failed to load climate data');
  }
}
