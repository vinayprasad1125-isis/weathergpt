import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiGisService {
  static Future<Map<String, dynamic>> getGisLayer(String layer, double lat, double lon) async {
    try {
      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/gis/layers/$layer?lat=$lat&lon=$lon');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('GIS API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load GIS data');
      }
    } catch (e) {
      debugPrint('Error fetching GIS layer: $e');
      rethrow;
    }
  }
}
