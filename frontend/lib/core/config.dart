class Config {
  // Use localhost via adb reverse tcp:8000 tcp:8000 on Android
  static String get apiBaseUrl {
    return 'http://localhost:8000';
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
