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
import 'screens/aviation_screen.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const HomeScreen(),
    const MapScreen(),
    const ForecastScreen(),
    const AlertsScreen(),
    const AviationScreen(),
    const ClimateScreen(),
    const AdvisoriesScreen(),
    const SettingsScreen(),
  ];

  void _navigate(int index) {
    setState(() => _currentIndex = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      drawer: Drawer(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.cloud, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'WeatherGPT',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Divider(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _DrawerItem(icon: LucideIcons.home, label: l10n.get('home'), selected: _currentIndex == 0, onTap: () => _navigate(0)),
                    _DrawerItem(icon: LucideIcons.map, label: l10n.get('maps'), selected: _currentIndex == 1, onTap: () => _navigate(1)),
                    _DrawerItem(icon: LucideIcons.cloud, label: l10n.get('forecast'), selected: _currentIndex == 2, onTap: () => _navigate(2)),
                    _DrawerItem(icon: LucideIcons.alertTriangle, label: l10n.get('alerts'), selected: _currentIndex == 3, onTap: () => _navigate(3)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Divider()),
                    _DrawerItem(icon: LucideIcons.planeTakeoff, label: 'Aviation Weather', selected: _currentIndex == 4, onTap: () => _navigate(4)),
                    _DrawerItem(icon: LucideIcons.barChart2, label: l10n.get('climate'), selected: _currentIndex == 5, onTap: () => _navigate(5)),
                    _DrawerItem(icon: LucideIcons.bookOpen, label: l10n.get('advisories'), selected: _currentIndex == 6, onTap: () => _navigate(6)),
                    _DrawerItem(icon: LucideIcons.settings, label: l10n.get('settings'), selected: _currentIndex == 7, onTap: () => _navigate(7)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Divider()),
                    _DrawerItem(
                      icon: LucideIcons.globe,
                      label: l10n.get('languageSelection'),
                      selected: false,
                      onTap: () {
                        _scaffoldKey.currentState?.closeDrawer();
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
        title: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: selected ? AppColors.primary : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
