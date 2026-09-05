import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // DAY / LIGHT PALETTE (06:00 AM - 05:59 PM)
  // ==========================================
  
  static const Color dayBackground = Color(0xFFF4FAFC);
  static const Color dayBackgroundAlt = Color(0xFFEEF8FC);
  static const Color dayBackgroundDeep = Color(0xFFE7F4F9);

  static const Color daySurface = Color(0xFFFFFFFF);
  static const Color daySurfaceSecondary = Color(0xFFF9FCFD);
  static const Color daySurfaceElevated = Color(0xFFFFFFFF);

  static const Color daySkyLight = Color(0xFFDDF3FB);
  static const Color daySkyMedium = Color(0xFFBFE7F5);
  static const Color daySky = Color(0xFF76CBE8);

  static const Color dayPrimary = Color(0xFF25BFD0);
  static const Color dayPrimaryBright = Color(0xFF36D3DF);
  static const Color dayPrimaryDark = Color(0xFF159AAA);

  static const Color dayText = Color(0xFF16343D);
  static const Color dayTextSecondary = Color(0xFF46636B);
  static const Color dayTextMuted = Color(0xFF718A91);
  static const Color dayTextSubtle = Color(0xFF94A9AE);

  static const Color dayWeatherYellow = Color(0xFFF6C84A);
  static const Color dayWeatherSun = Color(0xFFFFD95A);
  static const Color dayWeatherGold = Color(0xFFE8B83F);

  static const Color dayWarmOrange = Color(0xFFF5A65B);
  static const Color dayWarmOrangeLight = Color(0xFFFFD9B3);

  static const Color dayAlertCritical = Color(0xFFE96A5B);
  static const Color dayAlertWarning = Color(0xFFE8B84A);
  static const Color dayAlertInfo = Color(0xFF25BFD0);
  static const Color dayAlertSuccess = Color(0xFF55B889);
  
  static const Color dayAlertBgCritical = Color(0xFFFFF0EE);
  static const Color dayAlertBgWarning = Color(0xFFFFF8E5);
  static const Color dayAlertBgInfo = Color(0xFFEAFBFD);
  static const Color dayAlertBgSuccess = Color(0xFFECF9F2);

  static const Color dayBorder = Color(0xFFD5E8EE);
  static const Color dayBorderSecondary = Color(0xFFE4F0F3);
  static const Color dayDivider = Color(0xFFEAF2F4);

  static const Color dayIconDefault = Color(0xFF607D84);
  static const Color dayIconActive = Color(0xFF25BFD0);


  // ==========================================
  // NIGHT / DARK PALETTE (06:00 PM - 05:59 AM)
  // ==========================================
  
  static const Color nightBackground = Color(0xFF061A21);
  static const Color nightBackgroundAlt = Color(0xFF04151B);

  static const Color nightSurface = Color(0xFF08232B);
  static const Color nightSurfaceSecondary = Color(0xFF0B2B34);
  static const Color nightSurfaceElevated = Color(0xFF10343D);

  static const Color nightTealDark = Color(0xFF16434D);
  static const Color nightTealMedium = Color(0xFF1D5962);
  static const Color nightTealMuted = Color(0xFF2A6870);

  static const Color nightPrimary = Color(0xFF55D6D2);
  static const Color nightPrimaryBright = Color(0xFF67E0DC);

  static const Color nightText = Color(0xFFF1F5F3);
  static const Color nightTextSecondary = Color(0xFFB8C9C7);
  static const Color nightTextMuted = Color(0xFF789391);
  static const Color nightTextSubtle = Color(0xFF5F7978);

  static const Color nightWeatherYellow = Color(0xFFE4C45A);
  static const Color nightWeatherGold = Color(0xFFCBAE4C);

  static const Color nightAlertCritical = Color(0xFFE58A62);
  static const Color nightAlertWarning = Color(0xFFD9C05A);
  static const Color nightAlertInfo = Color(0xFF55D6D2);
  static const Color nightAlertSuccess = Color(0xFF78C69A);

  static const Color nightBorder = Color(0xFF1C4650);
  static const Color nightBorderSecondary = Color(0xFF153943);
  static const Color nightDivider = Color(0xFF12313A);

  static const Color nightIconDefault = Color(0xFF9DB5B2);
  static const Color nightIconActive = Color(0xFF55D6D2);

  // ==========================================
  // SEMANTIC ALIASES — resolve to day or night
  // based on the device's current local time.
  //
  // Day:   06:00 AM → 05:59 PM (hour >= 6 && hour < 18)
  // Night: 06:00 PM → 05:59 AM
  //
  // These getters mirror the exact same condition
  // used in ThemeController so they always agree.
  // ==========================================

  static bool get _isDayTime {
    final h = DateTime.now().hour;
    return h >= 6 && h < 18;
  }

  // Primary accent
  static Color get primary       => _isDayTime ? dayPrimary       : nightPrimary;
  static Color get primaryBright => _isDayTime ? dayPrimaryBright : nightPrimaryBright;
  static Color get primaryDark   => _isDayTime ? dayPrimaryDark   : nightPrimary;

  // Secondary / weather accent
  static Color get secondary     => _isDayTime ? dayWeatherYellow : nightWeatherYellow;

  // Backgrounds
  static Color get background    => _isDayTime ? dayBackground    : nightBackground;
  static Color get backgroundAlt => _isDayTime ? dayBackgroundAlt : nightBackgroundAlt;

  // Surfaces / cards
  static Color get surface       => _isDayTime ? daySurface          : nightSurface;
  static Color get card          => _isDayTime ? daySurface          : nightSurface;
  static Color get cardSecondary => _isDayTime ? daySurfaceSecondary : nightSurfaceSecondary;
  static Color get cardElevated  => _isDayTime ? daySurfaceElevated  : nightSurfaceElevated;

  // Explicit dark aliases used by news_screen / wherever isDark checks exist
  static Color get darkBackground => nightBackground;
  static Color get darkSurface    => nightSurface;
  static Color get darkCard       => nightSurface;

  // Text
  static Color get text          => _isDayTime ? dayText          : nightText;
  static Color get textSecondary => _isDayTime ? dayTextSecondary : nightTextSecondary;
  static Color get textMuted     => _isDayTime ? dayTextMuted     : nightTextMuted;
  static Color get textSubtle    => _isDayTime ? dayTextSubtle    : nightTextSubtle;

  // Borders
  static Color get border          => _isDayTime ? dayBorder          : nightBorder;
  static Color get borderSecondary => _isDayTime ? dayBorderSecondary : nightBorderSecondary;
  static Color get divider         => _isDayTime ? dayDivider         : nightDivider;

  // Icons
  static Color get iconDefault => _isDayTime ? dayIconDefault : nightIconDefault;
  static Color get iconActive  => _isDayTime ? dayIconActive  : nightIconActive;

  // Status / alert colours
  static Color get error   => _isDayTime ? dayAlertCritical : nightAlertCritical;
  static Color get warning => _isDayTime ? dayAlertWarning  : nightAlertWarning;
  static Color get info    => _isDayTime ? dayAlertInfo     : nightAlertInfo;
  static Color get success => _isDayTime ? dayAlertSuccess  : nightAlertSuccess;

  // Alert severity aliases used by alert_card.dart
  static Color get alertExtreme  => _isDayTime ? dayAlertCritical : nightAlertCritical;
  static Color get alertSevere   => _isDayTime ? dayAlertWarning  : nightAlertWarning;
  static Color get alertModerate => _isDayTime ? dayAlertInfo     : nightAlertInfo;
  static Color get alertMinor    => _isDayTime ? dayAlertSuccess  : nightAlertSuccess;

  // Alert background fills
  static Color get alertBgCritical => _isDayTime ? dayAlertBgCritical : nightSurfaceSecondary;
  static Color get alertBgWarning  => _isDayTime ? dayAlertBgWarning  : nightSurfaceSecondary;
  static Color get alertBgInfo     => _isDayTime ? dayAlertBgInfo     : nightSurfaceSecondary;
  static Color get alertBgSuccess  => _isDayTime ? dayAlertBgSuccess  : nightSurfaceSecondary;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.dayPrimary,
      scaffoldBackgroundColor: AppColors.dayBackground,
      dividerColor: AppColors.dayDivider,
      
      colorScheme: const ColorScheme.light(
        primary: AppColors.dayPrimary,
        secondary: AppColors.dayWeatherSun,
        surface: AppColors.daySurface,
        error: AppColors.dayAlertCritical,
        onPrimary: Colors.white,
        onSecondary: AppColors.dayText,
        onSurface: AppColors.dayText,
        onError: Colors.white,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.daySurface,
        foregroundColor: AppColors.dayPrimaryDark,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.dayIconDefault),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.dayText),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.dayText),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.dayText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.dayText),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.dayText),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.dayTextMuted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dayText),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.dayTextSecondary),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.daySurface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.dayBorder, width: 1),
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: AppColors.dayIconDefault,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: AppColors.dayTextMuted),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFCFE5EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFCFE5EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.dayPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dayPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFE6F7FA),
          foregroundColor: const Color(0xFF168C9A),
          side: const BorderSide(color: Color(0xFFBDE5EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.nightPrimary,
      scaffoldBackgroundColor: AppColors.nightBackground,
      dividerColor: AppColors.nightDivider,
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.nightPrimary,
        secondary: AppColors.nightWeatherYellow,
        surface: AppColors.nightSurface,
        error: AppColors.nightAlertCritical,
        onPrimary: Color(0xFF062027),
        onSecondary: AppColors.nightText,
        onSurface: AppColors.nightText,
        onError: Colors.white,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.nightSurface,
        foregroundColor: AppColors.nightPrimary,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.nightIconDefault),
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.nightText),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.nightText),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.nightText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.nightText),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.nightText),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.nightTextMuted),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.nightText),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.nightTextSecondary),
      ),
      
      cardTheme: CardThemeData(
        color: AppColors.nightSurface,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.nightBorder, width: 1),
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: AppColors.nightIconDefault,
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D3038),
        hintStyle: const TextStyle(color: AppColors.nightTextMuted),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF24535A)),
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF24535A)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.nightPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.nightPrimary,
          foregroundColor: const Color(0xFF062027),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF12343D),
          foregroundColor: const Color(0xFFD8E7E5),
          side: const BorderSide(color: Color(0xFF24535A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

// We will keep ThemeProvider as-is to preserve existing code structure for now.
// It will be updated by the new ThemeController logic in main.dart
class ThemeProvider extends InheritedWidget {
  final ThemeMode themeMode;
  final void Function(ThemeMode mode) setThemeMode;

  const ThemeProvider({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }

  @override
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return themeMode != oldWidget.themeMode;
  }
}
