import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  
  Future<bool> init() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      return false;
    }
    
    _isAvailable = await _speech.initialize(
      onError: (val) => debugPrint('STT Error: $val'),
      onStatus: (val) => debugPrint('STT Status: $val'),
    );
    return _isAvailable;
  }

  Future<void> startListening({required String localeId, required Function(String) onResult}) async {
    if (!_isAvailable) {
      final initialized = await init();
      if (!initialized) return;
    }
    
    if (!_speech.isListening) {
      await _speech.listen(
        onResult: (val) {
          if (val.hasConfidenceRating && val.confidence > 0) {
            onResult(val.recognizedWords);
          }
        },
        localeId: _getNativeLocale(localeId),
      );
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  String _getNativeLocale(String code) {
    if (code == 'hi') return 'hi_IN';
    if (code == 'ta') return 'ta_IN';
    return 'en_US';
  }
}
