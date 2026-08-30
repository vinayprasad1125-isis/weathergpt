import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiNwpService {
  static Future<Map<String, dynamic>> getForecast(String model, double lat, double lon) async {
    try {
      final uri = Uri.parse('${Config.apiBaseUrl}/api/v1/nwp/forecast?model=$model&lat=$lat&lon=$lon');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load NWP forecast');
      }
    } catch (e) {
      debugPrint('ApiNwpService Error: $e');
      rethrow;
    }
  }
}
