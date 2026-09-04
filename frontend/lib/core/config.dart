import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Config {
  // Use localhost via adb reverse tcp:8000 tcp:8000
  static String get apiBaseUrl {
    return 'http://localhost:8000';
  }
}
