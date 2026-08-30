import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/forecast_screen.dart';
import 'screens/climate_screen.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/advisories_screen.dart';
import 'widgets/headers.dart';
import 'l10n/l10n.dart';

void main() {
  runApp(const WeatherGPTApp());
}

class WeatherGPTApp extends StatefulWidget {
  const WeatherGPTApp({super.key});

  @override
  State<WeatherGPTApp> createState() => _WeatherGPTAppState();
}

class _WeatherGPTAppState extends State<WeatherGPTApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;

  void setLocale(Locale locale) => setState(() => _locale = locale);
  void setThemeMode(ThemeMode mode) => setState(() => _themeMode = mode);

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      setLocale: setLocale,
      child: ThemeProvider(
        themeMode: _themeMode,
        setThemeMode: setThemeMode,
        child: MaterialApp(
          title: 'WeatherGPT',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          debugShowCheckedModeBanner: false,
          locale: _locale,
          supportedLocales: const [Locale('en'), Locale('hi'), Locale('ta')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const MainNavigator(),
        ),
      ),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const ForecastScreen(),
    const AlertsScreen(),
    const MoreNavigator(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          items: [
            BottomNavigationBarItem(icon: const Icon(LucideIcons.home), label: l10n.get('home')),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.map), label: l10n.get('maps')),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.cloud), label: l10n.get('forecast')),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.alertTriangle), label: l10n.get('alerts')),
            BottomNavigationBarItem(icon: const Icon(LucideIcons.settings), label: l10n.get('more')),
          ],
        ),
      ),
    );
  }
}

class MoreNavigator extends StatelessWidget {
  const MoreNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case 'Maps':
            page = const MapScreen();
            break;
          case 'Climate':
            page = const ClimateScreen();
            break;
          case 'Advisories':
            page = const AdvisoriesScreen();
            break;
          case 'Language':
            page = const LanguageSelectionScreen();
            break;
          case 'Settings':
            page = const SettingsScreen();
            break;
          default:
            page = const MoreMenuScreen();
        }
        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.get('more')),
      body: ListView(
        children: [
          ListTile(leading: const Icon(LucideIcons.barChart2), title: Text(l10n.get('climate')), onTap: () => Navigator.pushNamed(context, 'Climate')),
          ListTile(leading: const Icon(LucideIcons.bookOpen), title: Text(l10n.get('advisories')), onTap: () => Navigator.pushNamed(context, 'Advisories')),
          ListTile(leading: const Icon(LucideIcons.globe), title: Text(l10n.get('languageSelection')), onTap: () => Navigator.pushNamed(context, 'Language')),
          ListTile(leading: const Icon(LucideIcons.settings), title: Text(l10n.get('settings')), onTap: () => Navigator.pushNamed(context, 'Settings')),
        ],
      ),
    );
  }
}

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = LocaleProvider.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.get('languageSelection')),
      body: ListView(
        children: [
          ListTile(title: const Text('English'), onTap: () { provider?.setLocale(const Locale('en')); Navigator.pop(context); }),
          ListTile(title: const Text('தமிழ் (Tamil)'), onTap: () { provider?.setLocale(const Locale('ta')); Navigator.pop(context); }),
          ListTile(title: const Text('हिन्दी (Hindi)'), onTap: () { provider?.setLocale(const Locale('hi')); Navigator.pop(context); }),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: title),
      body: Center(
        child: Text(
          '$title Screen\n(Placeholder)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}
