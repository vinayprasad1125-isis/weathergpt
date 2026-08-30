import os
import re

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'

# 1. Update api_chat_service.dart
api_chat_file = os.path.join(base_dir, 'lib/services/api_chat_service.dart')
with open(api_chat_file, 'r') as f:
    api_chat_content = f.read()

api_chat_content = api_chat_content.replace(
    'static Future<List<ChatMessage>> sendMessage(String message) async {',
    'static Future<List<ChatMessage>> sendMessage(String message, String languageCode) async {'
).replace(
    "'language': 'en'",
    "'language': languageCode"
)
with open(api_chat_file, 'w') as f:
    f.write(api_chat_content)

# 2. Update services.dart
services_file = os.path.join(base_dir, 'lib/services/services.dart')
with open(services_file, 'r') as f:
    services_content = f.read()

services_content = services_content.replace(
    'static Future<List<ChatMessage>> sendMessage(String message) async {',
    'static Future<List<ChatMessage>> sendMessage(String message, String languageCode) async {'
).replace(
    'return await ApiChatService.sendMessage(message);',
    'return await ApiChatService.sendMessage(message, languageCode);'
)
with open(services_file, 'w') as f:
    f.write(services_content)

# 3. Update chat_screen.dart
chat_screen_file = os.path.join(base_dir, 'lib/screens/chat_screen.dart')
with open(chat_screen_file, 'r') as f:
    chat_screen_content = f.read()

chat_screen_content = chat_screen_content.replace(
    'import \'../theme/app_theme.dart\';',
    'import \'../theme/app_theme.dart\';\\nimport \'../l10n/l10n.dart\';'
).replace(
    'final responses = await ChatService.sendMessage(text);',
    'final l10n = AppLocalizations.of(context);\\n    final responses = await ChatService.sendMessage(text, l10n.locale.languageCode);'
).replace(
    'appBar: const AppHeader(title: \'WeatherGPT Chat\'),',
    'appBar: AppHeader(title: AppLocalizations.of(context).get(\'chat\')),'
).replace(
    'hintText: \'Ask about the weather...\',',
    'hintText: AppLocalizations.of(context).get(\'search\') + \'...\','
)
with open(chat_screen_file, 'w') as f:
    f.write(chat_screen_content)

# 4. Update main.dart
main_file = os.path.join(base_dir, 'lib/main.dart')
with open(main_file, 'r') as f:
    main_content = f.read()

if 'flutter_localizations.dart' not in main_content:
    main_content = main_content.replace(
        'import \'widgets/headers.dart\';',
        'import \'widgets/headers.dart\';\\nimport \'package:flutter_localizations/flutter_localizations.dart\';\\nimport \'l10n/l10n.dart\';\\nimport \'screens/climate_screen.dart\';'
    )
    main_content = main_content.replace(
        '''class WeatherGPTApp extends StatelessWidget {
  const WeatherGPTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(''',
        '''class WeatherGPTApp extends StatefulWidget {
  const WeatherGPTApp({super.key});
  @override
  State<WeatherGPTApp> createState() => _WeatherGPTAppState();
}

class _WeatherGPTAppState extends State<WeatherGPTApp> {
  Locale _locale = const Locale('en');
  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      setLocale: setLocale,
      child: MaterialApp(
        locale: _locale,
        supportedLocales: const [Locale('en'), Locale('hi'), Locale('ta')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],'''
    )
    
    # BottomNav localization
    main_content = main_content.replace(
        'BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: \'Home\'),',
        'BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: AppLocalizations.of(context).get(\'home\')),'
    ).replace(
        'BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: \'Chat\'),',
        'BottomNavigationBarItem(icon: Icon(LucideIcons.messageSquare), label: AppLocalizations.of(context).get(\'chat\')),'
    ).replace(
        'BottomNavigationBarItem(icon: Icon(LucideIcons.cloud), label: \'Forecast\'),',
        'BottomNavigationBarItem(icon: Icon(LucideIcons.cloud), label: AppLocalizations.of(context).get(\'forecast\')),'
    ).replace(
        'BottomNavigationBarItem(icon: Icon(LucideIcons.alertTriangle), label: \'Alerts\'),',
        'BottomNavigationBarItem(icon: Icon(LucideIcons.alertTriangle), label: AppLocalizations.of(context).get(\'alerts\')),'
    ).replace(
        'BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: \'More\'),',
        'BottomNavigationBarItem(icon: Icon(LucideIcons.settings), label: AppLocalizations.of(context).get(\'more\')),'
    )

    # Routes for Climate and Language
    main_content = main_content.replace(
        '''          case 'Climate':
            page = const PlaceholderScreen(title: 'Climate Trends');
            break;''',
        '''          case 'Climate':
            page = const ClimateScreen();
            break;'''
    )
    
    main_content = main_content.replace(
        '''          case 'Language':
            page = const PlaceholderScreen(title: 'Language Selection');
            break;''',
        '''          case 'Language':
            page = const LanguageSelectionScreen();
            break;'''
    )
    
    # Append LanguageSelectionScreen
    main_content += '''
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
'''
    with open(main_file, 'w') as f:
        f.write(main_content)

print("Flutter integration updated.")
