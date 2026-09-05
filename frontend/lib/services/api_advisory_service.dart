import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class ApiAdvisoryService {
  static Future<List<Advisory>> getAdvisory(String domain, double lat, double lon) async {
    try {
      final uri = Uri.parse('${Config.apiBaseUrl}/api/v1/advisory');
      
      final requestBody = json.encode({
        'domain': domain,
        'location': {
          'latitude': lat,
          'longitude': lon
        },
        'time_range': 'today'
      });

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        return [
          Advisory(
            id: 'api_advisory_$domain',
            category: domain,
            location: data['location']?['name'] ?? 'Selected Location',
            title: data['summary'] ?? 'Advisory',
            details: (data['recommendations'] as List<dynamic>?)?.join('\n\n') ?? 'No specific recommendations at this time.',
            rainProbability: 0,
            tempRange: 'N/A'
          )
        ];
      } else {
        throw Exception('Failed to load advisory');
      }
    } catch (e) {
      debugPrint('ApiAdvisoryService Error: $e');
      rethrow;
    }
  }

  static String _getIconForDomain(String domain) {
    switch (domain.toLowerCase()) {
      case 'agriculture': return 'agriculture';
      case 'marine': return 'directions_boat';
      case 'aviation': return 'flight';
      case 'urban': return 'location_city';
      case 'disaster': return 'warning';
      default: return 'info';
    }
  }

  static int _getColorForDomain(String domain) {
    switch (domain.toLowerCase()) {
      case 'agriculture': return 0xFF4CAF50;
      case 'marine': return 0xFF2196F3;
      case 'aviation': return 0xFF9C27B0;
      case 'urban': return 0xFFFF9800;
      case 'disaster': return 0xFFF44336;
      default: return 0xFF607D8B;
    }
  }
}
