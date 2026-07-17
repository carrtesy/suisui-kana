import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Owns every way the app can speak a kana: the on-device TTS engine and an
/// optional pre-rendered voice pack. The pack is produced by [buildPack], which
/// synthesizes each syllable *with the very same TTS engine and voice* to a
/// local wav — so a played-back file sounds identical to live TTS, just saved
/// for instant, consistent, fully-offline playback. The quiz plays the file
/// when one exists and the user opted in, otherwise it speaks live.
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();

  Directory? _packDir;
  final Set<String> _have = {}; // romaji keys that have a local recording

  Future<void> init() async {
    await _setupTts();
    await reloadPack();
  }

  /// Configure TTS for the most natural Japanese the device can offer.
  Future<void> _setupTts() async {
    // Prefer Google's engine — its Japanese voices beat most vendor defaults.
    try {
      final engines = (await _tts.getEngines as List).cast<String>();
      if (engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {/* keep current engine */}

    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    // Make synthesizeToFile block until the wav is fully written.
    try {
      await _tts.awaitSynthCompletion(true);
    } catch (_) {/* older engines: best effort */}

    // Pick a good *embedded* (on-device) Japanese voice. We deliberately avoid
    // *network* voices: they need internet and, critically, hang
    // synthesizeToFile (no completion callback), which would stall building the
    // voice pack. An embedded voice is reliable, offline, and — because both
    // live playback and the saved files use it — makes them sound identical.
    try {
      final voices = (await _tts.getVoices as List).cast<Map>();
      final ja = voices
          .where((v) => '${v['locale']}'.toLowerCase().startsWith('ja'))
          .toList();
      if (ja.isNotEmpty) {
        final offline = ja
            .where((v) => !'${v['name']}'.toLowerCase().contains('network'))
            .toList();
        final pool = offline.isNotEmpty ? offline : ja;
        final best = pool.firstWhere(
          (v) => '${v['name']}'.toLowerCase().contains('local'),
          orElse: () => pool.first,
        );
        await _tts.setVoice(
            {'name': '${best['name']}', 'locale': '${best['locale']}'});
      }
    } catch (_) {/* fall back to default voice */}
  }

  /// True when a usable Japanese TTS voice is installed.
  Future<bool> isJaAvailable() async {
    try {
      final v = await _tts.isLanguageAvailable('ja-JP');
      return v == true || v == 1;
    } catch (_) {
      return true; // don't nag if the check itself fails
    }
  }

  Future<Directory> _dir() async {
    return _packDir ??= Directory(
        '${(await getApplicationDocumentsDirectory()).path}/voicepack');
  }

  /// Re-scan local storage for which recordings are present.
  Future<void> reloadPack() async {
    final dir = await _dir();
    _have.clear();
    if (await dir.exists()) {
      for (final f in dir.listSync().whereType<File>()) {
        final name = f.uri.pathSegments.last;
        if (name.endsWith('.wav')) _have.add(name.substring(0, name.length - 4));
      }
    }
  }

  bool hasRecording(String key) => _have.contains(key);
  bool get hasAnyRecording => _have.isNotEmpty;

  /// How many of [keys] still have no saved file (for the "update" prompt).
  int missingCount(Iterable<String> keys) =>
      keys.where((k) => !_have.contains(k)).length;

  /// Delete the whole downloaded voice pack.
  Future<void> clearPack() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
    _have.clear();
  }

  /// Speak the utterance stored under [key] (a romaji or a word-mode key):
  /// the saved file if opted in and present, otherwise live TTS of [fallback].
  Future<void> speakPhrase(String key, String fallback,
      {required bool useVoicePack}) async {
    if (useVoicePack && hasRecording(key)) {
      try {
        final dir = await _dir();
        await _player.stop();
        await _player.play(DeviceFileSource('${dir.path}/$key.wav'));
        return;
      } catch (_) {/* fall through to TTS */}
    }
    await _player.stop(); // avoid overlap if a file just played
    await _tts.speak(fallback);
  }

  /// Speak a single syllable (keyed by its romaji).
  Future<void> speakGlyph(String romaji, String glyph,
          {required bool useVoicePack}) =>
      speakPhrase(romaji, glyph, useVoicePack: useVoicePack);

  /// Speak an arbitrary phrase via TTS (no saved-file lookup).
  Future<void> speakText(String text) => _tts.speak(text);

  Future<void> stop() async {
    await _tts.stop();
    await _player.stop();
  }

  /// Render a voice file for every entry in [items] (romaji → glyph) using the
  /// on-device TTS engine, so each file is identical to what live TTS would say.
  /// Reports (completed, total) after each file. Returns how many landed.
  Future<int> buildPack(
    Map<String, String> items,
    void Function(int done, int total) onProgress,
  ) async {
    final dir = await _dir();
    if (!await dir.exists()) await dir.create(recursive: true);
    var ok = 0;
    var i = 0;
    for (final e in items.entries) {
      final path = '${dir.path}/${e.key}.wav';
      try {
        // Backstop: never let one bad synthesis hang the whole build.
        await _tts
            .synthesizeToFile(e.value, path, true)
            .timeout(const Duration(seconds: 20));
        if (File(path).existsSync()) ok++;
      } catch (_) {/* skip this one */}
      onProgress(++i, items.length);
    }
    await reloadPack();
    return ok;
  }

  void dispose() {
    _tts.stop();
    _player.dispose();
  }
}
