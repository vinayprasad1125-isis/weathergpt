import 'package:flutter/material.dart';

class AppColors {
  // Light Theme
  static const Color primary = Color(0xFF0C717C);
  static const Color primaryDark = Color(0xFF074F58);
  static const Color secondary = Color(0xFFEFB241); // Sun color
  static const Color background = Color(0xFFE0EDEE); // Canvas
  static const Color card = Color(0xFFF7FBFB); // Surface
  static const Color text = Color(0xFF08222B); // Ink
  static const Color textSecondary = Color(0xFF24688F); // Minor alert or similar
  static const Color border = Color(0xFF97690E); 
  static const Color error = Color(0xFFB01E2D); // Extreme alert
  static const Color warning = Color(0xFFCD4D1E); // Severe alert
  static const Color success = Color(0xFF24688F); 
  static const Color info = Color(0xFF24688F);
  static const Color surface = Color(0xFFF7FBFB);
  
  // Dark Theme
  static const Color darkBackground = Color(0xFF05141C);
  static const Color darkCard = Color(0xFF0A1F28);
  static const Color darkSurface = Color(0xFF0A1F28);
  static const Color darkText = Color(0xFFE6F1F1);
  static const Color darkTextSecondary = Color(0xFF6DB4D9);
  
  // Alerts Light
  static const Color alertExtreme = Color(0xFFB01E2D);
  static const Color alertSevere = Color(0xFFCD4D1E);
  static const Color alertModerate = Color(0xFF97690E);
  static const Color alertMinor = Color(0xFF24688F);

  // Alerts Dark
  static const Color darkAlertExtreme = Color(0xFFF76973);
  static const Color darkAlertSevere = Color(0xFFF79158);
  static const Color darkAlertModerate = Color(0xFFEBBC53);
  static const Color darkAlertMinor = Color(0xFF6DB4D9);
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
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primaryDark,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.text),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.text),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.text),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.text),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.primary,
        elevation: 1,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.darkText),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.darkText),
        displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkText),
        displaySmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.darkText),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.darkText),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkText),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

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
