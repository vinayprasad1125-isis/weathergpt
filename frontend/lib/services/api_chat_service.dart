import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../core/config.dart';
import 'package:flutter/foundation.dart';
import '../mock/mock_data.dart';
import 'auth_service.dart';
import 'location_store.dart';

class ApiChatService {
  static Future<List<ChatMessage>> sendMessage(String message, String languageCode) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication required. No JWT token found.');
      }

      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/chat');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'message': message,
          'location': LocationStore.chatLocationPayload,
          'language': languageCode
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<ChatMessage> responses = [];
        
        // Add natural language text response
        responses.add(ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}1',
          role: 'assistant',
          content: data['message'] ?? "Here is the weather information you requested.",
          timestamp: DateTime.now().toIso8601String(),
          type: 'text',
        ));
        
        // Depending on intent, we can also inject a weather card if we have structured data
        if (data['query'] != null && data['weather_data'] != null) {
           final intent = data['query']['intent'];
           if (intent == 'current_weather' || intent == 'forecast' || intent == 'temperature' || intent == 'precipitation') {
             // We can optionally implement a real parser here to inject a card 
             // using the real weather_data. For now, since we removed the mock, 
             // we will just rely on the text response to avoid showing fake data.
           }
        }

        return responses;
      } else if (response.statusCode == 401) {
        debugPrint('Chat API Unauthorized: ${response.statusCode}');
        await AuthService.logout();
        throw Exception('Session expired. Please log in again.');
      } else {
        debugPrint('Chat API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load chat data');
      }
    } catch (e) {
      debugPrint('Error sending chat: $e');
      rethrow;
    }
  }
}
