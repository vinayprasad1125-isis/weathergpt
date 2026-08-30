import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  VoidCallback? onStart;
  VoidCallback? onDone;

  TTSService() {
    _flutterTts.setStartHandler(() {
      if (onStart != null) onStart!();
    });
    _flutterTts.setCompletionHandler(() {
      if (onDone != null) onDone!();
    });
    _flutterTts.setCancelHandler(() {
      if (onDone != null) onDone!();
    });
    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS error: $msg');
      if (onDone != null) onDone!();
    });
    _initSettings();
  }

  Future<void> _initSettings() async {
    // 0.62 feels natural — not too slow, not rushed
    await _flutterTts.setSpeechRate(0.78);
    await _flutterTts.setPitch(1.05); // Slight pitch-up makes it sound warmer
    await _flutterTts.setVolume(1.0);
  }

  Future<void> speak(String text, String languageCode) async {
    final locale = _getNativeLocale(languageCode);
    await _flutterTts.setLanguage(locale);

    // On web, try to select a natural-sounding voice (Google voices if available)
    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        final voiceList = List<Map>.from(voices);
        // Priority order: Google neural > Google standard > any Google > default
        Map? best;
        for (final v in voiceList) {
          final name = (v['name'] ?? '').toString().toLowerCase();
          final lang = (v['locale'] ?? '').toString().toLowerCase();
          if (!lang.startsWith(languageCode)) continue;
          if (best == null) { best = v; continue; }
          final bestName = (best['name'] ?? '').toString().toLowerCase();
          // Prefer Google Neural > Google > anything
          if (name.contains('google') && name.contains('us english')) { best = v; break; }
          if (name.contains('google') && !bestName.contains('google')) best = v;
        }
        if (best != null && best['name'] != null) {
          await _flutterTts.setVoice({"name": best['name'], "locale": best['locale']});
        }
      }
    } catch (_) {}

    // Strip emojis and list punctuation for smoother spoken output
    final cleanText = _cleanForSpeech(text);
    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Primes the audio engine on first user gesture to satisfy browser autoplay policy.
  Future<void> unlock() async {
    try {
      await _flutterTts.speak(' ');
      await Future.delayed(const Duration(milliseconds: 100));
      await _flutterTts.stop();
    } catch (_) {}
  }

  String _cleanForSpeech(String text) {
    var result = text
        // Remove emoji (common ranges)
        .replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '')
        .replaceAll(RegExp(r'[\u{2600}-\u{27BF}]', unicode: true), '');

    // Dates first (before number patterns strip digits)
    result = result.replaceAllMapped(
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      (m) {
        const months = ['', 'January', 'February', 'March', 'April', 'May',
            'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        final month = int.tryParse(m[2]!) ?? 0;
        return '${m[3]} ${month > 0 && month <= 12 ? months[month] : m[2]} ${m[1]}';
      },
    );

    // Expand units — use replaceAllMapped so capture groups work in Dart
    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*[\u00b0\u202f]?\s*°?\s*C\b'),
      (m) => '${m[1]} degrees Celsius',
    );
    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*[\u202f\u00a0]?%'),
      (m) => '${m[1]} percent',
    );
    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*km/h'),
      (m) => '${m[1]} kilometres per hour',
    );
    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*mm\b'),
      (m) => '${m[1]} millimetres',
    );
    result = result.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)\s*hPa'),
      (m) => '${m[1]} hectopascals',
    );

    return result
        // Clean bullet points
        .replaceAll(RegExp(r'^\s*[-•]\s+', multiLine: true), '')
        // Newlines → pauses
        .replaceAll(RegExp(r'\n+'), '. ')
        .replaceAll(RegExp(r'\.\s*\.+'), '.')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  String _getNativeLocale(String code) {
    if (code == 'hi') return 'hi-IN';
    if (code == 'ta') return 'ta-IN';
    return 'en-GB'; // en-GB tends to have a more natural, pleasant voice than en-US
  }
}
