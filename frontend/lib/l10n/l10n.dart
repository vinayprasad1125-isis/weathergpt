import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'currentWeather': 'Current Weather',
      'forecast': 'Forecast',
      'alerts': 'Alerts',
      'maps': 'Maps',
      'climate': 'Climate Trends',
      'advisories': 'Advisories',
      'settings': 'Settings',
      'search': 'Search',
      'currentLocation': 'Current Location',
      'send': 'Send',
      'listening': 'Listening',
      'noActiveWarnings': 'No active warnings',
      'chat': 'Chat',
      'home': 'Home',
      'more': 'More',
      'languageSelection': 'Language Selection',
    },
    'hi': {
      'currentWeather': 'वर्तमान मौसम',
      'forecast': 'पूर्वानुमान',
      'alerts': 'अलर्ट',
      'maps': 'नक्शे',
      'climate': 'जलवायु रुझान',
      'advisories': 'सलाह',
      'settings': 'सेटिंग्स',
      'search': 'खोजें',
      'currentLocation': 'वर्तमान स्थान',
      'send': 'भेजें',
      'listening': 'सुन रहा है',
      'noActiveWarnings': 'कोई सक्रिय चेतावनी नहीं',
      'chat': 'चैट',
      'home': 'होम',
      'more': 'अधिक',
      'languageSelection': 'भाषा चयन',
    },
    'ta': {
      'currentWeather': 'தற்போதைய வானிலை',
      'forecast': 'முன்னறிவிப்பு',
      'alerts': 'எச்சரிக்கைகள்',
      'maps': 'வரைபடங்கள்',
      'climate': 'காலநிலை போக்குகள்',
      'advisories': 'ஆலோசனைகள்',
      'settings': 'அமைப்புகள்',
      'search': 'தேடு',
      'currentLocation': 'தற்போதைய இடம்',
      'send': 'அனுப்பு',
      'listening': 'கேட்கிறது',
      'noActiveWarnings': 'எச்சரிக்கைகள் ஏதுமில்லை',
      'chat': 'அரட்டை',
      'home': 'முகப்பு',
      'more': 'மேலும்',
      'languageSelection': 'மொழி தேர்வு',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Global provider for dynamic language switching without complex state management for MVP
class LocaleProvider extends InheritedWidget {
  final Locale locale;
  final Function(Locale) setLocale;

  const LocaleProvider({
    super.key,
    required this.locale,
    required this.setLocale,
    required super.child,
  });

  static LocaleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleProvider>();
  }

  @override
  bool updateShouldNotify(LocaleProvider oldWidget) {
    return locale != oldWidget.locale;
  }
}
