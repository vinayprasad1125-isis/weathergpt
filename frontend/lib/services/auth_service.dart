import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static String? _token;

  static Future<String?> getToken() async {
    if (_token != null) return _token;

    try {
      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'ngrok-skip-browser-warning': 'true',
        },
        body: {'username': 'user', 'password': 'password'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _token = data['access_token'];
        return _token;
      } else {
        debugPrint('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error during login: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    _token = null;
  }
}
