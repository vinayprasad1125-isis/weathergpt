import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> speak(String text, String languageCode) async {
    await _flutterTts.setLanguage(_getNativeLocale(languageCode));
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
  
  String _getNativeLocale(String code) {
    if (code == 'hi') return 'hi-IN';
    if (code == 'ta') return 'ta-IN';
    return 'en-US';
  }
}
