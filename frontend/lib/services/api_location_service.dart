import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiLocationService {
  static Future<List<Location>> searchLocations(String query) async {
    try {
      final uri = Uri.parse('${Config.apiBaseUrl}/api/v1/location/search?q=$query');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        return results.map((json) => Location(
          id: '${json['latitude']}_${json['longitude']}',
          city: json['name'] ?? 'Unknown',
          state: json['region'],
          country: json['country'] ?? 'Unknown',
          latitude: (json['latitude'] as num).toDouble(),
          longitude: (json['longitude'] as num).toDouble(),
          isCurrentLocation: false,
        )).toList();
      } else {
        throw Exception('Failed to load locations');
      }
    } catch (e) {
      debugPrint('ApiLocationService Error: $e');
      rethrow;
    }
  }
}
