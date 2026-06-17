import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Singleton TTS service wrapping flutter_tts.
///
/// Usage:
///   await TtsService.instance.speak('Hello');
///   await TtsService.instance.stop();
///   TtsService.instance.isSpeaking // ValueListenable<bool>
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> isSpeaking = ValueNotifier(false);

  bool _initialized = false;

  // ── Settings (tweak from SettingsScreen if desired) ──────────────
  double speechRate = 0.45;   // 0.0–1.0  (0.45 ≈ clear and natural)
  double pitch      = 1.0;    // 0.5–2.0
  double volume     = 1.0;    // 0.0–1.0
  String language   = 'en-US';

  // ── Init ──────────────────────────────────────────────────────────
  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;

    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(volume);

    // iOS: use device speaker, not earpiece
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }

    _tts.setStartHandler(() => isSpeaking.value = true);
    _tts.setCompletionHandler(() => isSpeaking.value = false);
    _tts.setCancelHandler(() => isSpeaking.value = false);
    _tts.setErrorHandler((_) => isSpeaking.value = false);
  }

  // ── Speak ─────────────────────────────────────────────────────────
  /// Speaks [text] in English. Stops any current speech first.
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    await _tts.stop();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(speechRate);
    await _tts.speak(text.trim());
  }

  /// Speaks [text] in a given [lang] (e.g. 'om' for Oromo if available,
  /// falls back to 'en-US' if not installed on the device).
  Future<void> speakInLanguage(String text, {String lang = 'en-US'}) async {
    if (text.trim().isEmpty) return;
    await _ensureInit();
    await _tts.stop();
    final available = await _tts.isLanguageAvailable(lang);
    await _tts.setLanguage(available == true ? lang : 'en-US');
    await _tts.setSpeechRate(speechRate);
    await _tts.speak(text.trim());
  }

  // ── Stop ──────────────────────────────────────────────────────────
  Future<void> stop() async {
    await _tts.stop();
    isSpeaking.value = false;
  }

  // ── Apply updated settings ─────────────────────────────────────────
  Future<void> applySettings({
    double? rate,
    double? pitchVal,
    double? vol,
    String? lang,
  }) async {
    await _ensureInit();
    if (rate != null) { speechRate = rate; await _tts.setSpeechRate(rate); }
    if (pitchVal != null) { pitch = pitchVal; await _tts.setPitch(pitchVal); }
    if (vol != null) { volume = vol; await _tts.setVolume(vol); }
    if (lang != null) { language = lang; await _tts.setLanguage(lang); }
  }

  // ── Available languages ────────────────────────────────────────────
  Future<List<String>> availableLanguages() async {
    await _ensureInit();
    final langs = await _tts.getLanguages as List?;
    return langs?.map((l) => l.toString()).toList() ?? [];
  }

  void dispose() {
    isSpeaking.dispose();
  }
}