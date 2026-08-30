import os

base_dir = '/Users/vinayprasad/development/weathergpt/weathergpt_flutter'
main_file = os.path.join(base_dir, 'lib/main.dart')

main_content = '''import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/climate_screen.dart';
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
  void setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      setLocale: setLocale,
      child: MaterialApp(
        title: 'WeatherGPT',
        theme: AppTheme.lightTheme,
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
    const ChatScreen(),
    const PlaceholderScreen(title: 'Forecast'),
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
              color: Colors.black.withValues(alpha: 0.1),
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
            BottomNavigationBarItem(icon: const Icon(LucideIcons.messageSquare), label: l10n.get('chat')),
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
            page = const PlaceholderScreen(title: 'Maps');
            break;
          case 'Climate':
            page = const ClimateScreen();
            break;
          case 'Advisories':
            page = const PlaceholderScreen(title: 'Advisories');
            break;
          case 'Language':
            page = const LanguageSelectionScreen();
            break;
          case 'Settings':
            page = const PlaceholderScreen(title: 'Settings');
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
          ListTile(leading: const Icon(LucideIcons.map), title: Text(l10n.get('maps')), onTap: () => Navigator.pushNamed(context, 'Maps')),
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
          '$title Screen\\n(Placeholder)',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}
'''
with open(main_file, 'w') as f:
    f.write(main_content)

chat_file = os.path.join(base_dir, 'lib/screens/chat_screen.dart')
chat_content = '''import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/headers.dart';
import '../l10n/l10n.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'welcome',
      role: 'assistant',
      content: 'Namaste! I am WeatherGPT. How can I help you with weather, alerts, or advisories today?',
      timestamp: DateTime.now().toIso8601String(),
      type: 'text',
    ),
  ];
  final TextEditingController _textController = TextEditingController();
  bool _isTyping = false;

  final List<String> _suggestedQuestions = [
    "Will it rain tomorrow?",
    "Is there any cyclone warning?",
    "Should I irrigate my crops?",
    "Show me the forecast for Chennai",
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now().toIso8601String(),
      type: 'text',
    );

    setState(() {
      _messages.add(userMsg);
      _textController.clear();
      _isTyping = true;
    });
    
    final l10n = AppLocalizations.of(context);
    final responses = await ChatService.sendMessage(text, l10n.locale.languageCode);

    if (mounted) {
      setState(() {
        _messages.addAll(responses);
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppHeader(title: l10n.get('chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${l10n.get('listening')}...', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
              ),
            ),
          if (_messages.length == 1)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                itemCount: _suggestedQuestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child: ActionChip(
                      label: Text(_suggestedQuestions[index]),
                      onPressed: () => _sendMessage(_suggestedQuestions[index]),
                      backgroundColor: AppColors.card,
                      side: const BorderSide(color: AppColors.primary),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primaryDark),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.mic, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: '${l10n.get('search')}...',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.send, color: AppColors.surface, size: 20),
                    onPressed: () => _sendMessage(_textController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
'''
with open(chat_file, 'w') as f:
    f.write(chat_content)

print("Flutter UI files completely rewritten cleanly.")
