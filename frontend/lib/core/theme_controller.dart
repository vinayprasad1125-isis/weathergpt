import 'dart:async';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  Timer? _themeTimer;
  ThemeMode _currentThemeMode = ThemeMode.light;

  ThemeMode get currentThemeMode => _currentThemeMode;

  ThemeController() {
    _evaluateTheme();
  }

  /// Determines if the current local time is Day or Night.
  /// Day: 06:00:00 to 17:59:59
  /// Night: 18:00:00 to 05:59:59
  bool get _isDayTime {
    final now = DateTime.now();
    return now.hour >= 6 && now.hour < 18;
  }

  /// Evaluates the current theme based on the clock and sets up a timer
  /// for the exact moment the next transition should happen.
  void _evaluateTheme() {
    final bool isDay = _isDayTime;
    final ThemeMode newMode = isDay ? ThemeMode.light : ThemeMode.dark;

    if (_currentThemeMode != newMode) {
      _currentThemeMode = newMode;
      notifyListeners();
    }

    _scheduleNextUpdate();
  }

  /// Calculates the duration until the next 6:00 AM or 6:00 PM and schedules a timer.
  void _scheduleNextUpdate() {
    _themeTimer?.cancel();

    final now = DateTime.now();
    late DateTime nextTransition;

    if (now.hour >= 6 && now.hour < 18) {
      // It is currently day. Next transition is today at 18:00 (6 PM)
      nextTransition = DateTime(now.year, now.month, now.day, 18, 0, 0);
    } else {
      // It is currently night.
      if (now.hour >= 18) {
        // Night before midnight. Next transition is tomorrow at 06:00 (6 AM)
        nextTransition = DateTime(now.year, now.month, now.day + 1, 6, 0, 0);
      } else {
        // Night after midnight. Next transition is today at 06:00 (6 AM)
        nextTransition = DateTime(now.year, now.month, now.day, 6, 0, 0);
      }
    }

    final Duration timeUntilTransition = nextTransition.difference(now);

    // Schedule the timer exactly when the transition should happen.
    // We add a tiny buffer (100ms) to ensure the clock has rolled over when the timer fires.
    _themeTimer = Timer(timeUntilTransition + const Duration(milliseconds: 100), () {
      _evaluateTheme();
    });
  }

  /// Public method to force a re-evaluation of the theme.
  /// Should be called when the app resumes from the background.
  void checkAndScheduleThemeUpdate() {
    _evaluateTheme();
  }

  /// Sets the theme mode manually, overriding the automatic time-based system
  /// until the next scheduled time boundary or app restart.
  void setManualThemeMode(ThemeMode mode) {
    if (_currentThemeMode != mode) {
      _currentThemeMode = mode;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _themeTimer?.cancel();
    super.dispose();
  }
}
