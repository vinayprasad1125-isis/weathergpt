import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  // Use Mac's local WiFi IP so the Android app can connect over WiFi (no USB required).
  // Both Mac and Android must be on the same WiFi network.
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    // Fallback for Android/iOS - updated to current local IP (192.168.1.4)
    return 'http://192.168.1.4:8000';
  }

  static const String _envOwmApiKey = String.fromEnvironment(
    'OWM_API_KEY',
    defaultValue: '2368d7321df517b74335df5232c7e298',
  );

  static String get owmApiKey {
    if (_envOwmApiKey == 'your_key' || _envOwmApiKey.isEmpty) {
      return '2368d7321df517b74335df5232c7e298';
    }
    return _envOwmApiKey;
  }

  static const String _envNewsDataApiKey = String.fromEnvironment(
    'NEWSDATA_API_KEY',
    defaultValue: 'pub_6425cbd7c58c4645987dff6c64f7f32b',
  );

  static String get newsDataApiKey {
    if (_envNewsDataApiKey == 'your_key' || _envNewsDataApiKey.isEmpty) {
      return 'pub_6425cbd7c58c4645987dff6c64f7f32b';
    }
    return _envNewsDataApiKey;
  }

  // RainViewer public API — no key required
  static const String rainviewerApiUrl =
      'https://api.rainviewer.com/public/weather-maps.json';
}
