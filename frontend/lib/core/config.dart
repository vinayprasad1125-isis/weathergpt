class Config {
  // Use Mac's local WiFi IP so the Android app can connect over WiFi (no USB required).
  // Run `ipconfig getifaddr en0` on Mac to get this IP.
  // Both Mac and Android must be on the same WiFi network.
  static String get apiBaseUrl {
    return 'http://10.45.253.73:8000';
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
