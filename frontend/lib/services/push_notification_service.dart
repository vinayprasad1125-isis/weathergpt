import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 2. Get the token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await sendTokenToBackend(token);
      }

      // 3. Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token Refreshed: $newToken');
        sendTokenToBackend(newToken);
      });

      // 4. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint('Message also contained a notification: ${message.notification}');
          // Ideally show a local notification or SnackBar here
        }
      });

      // 5. Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
  }

  static Future<void> sendTokenToBackend(String token) async {
    try {
      final url = Uri.parse('${Config.apiBaseUrl}/api/v1/users/fcm-token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          // We don't have standard bearer auth implemented in the backend mock for this,
          // so we just hit the endpoint for prototype purposes.
        },
        body: jsonEncode({'fcm_token': token}),
      );
      if (response.statusCode == 200) {
        debugPrint("Successfully saved FCM token to backend");
      } else {
        debugPrint("Failed to save FCM token: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending FCM token to backend: $e");
    }
  }
}
