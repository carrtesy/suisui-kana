import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which script(s) the quiz draws from.
enum ScriptMode { hiragana, katakana, both }

/// UI / gloss language. Default English.
enum Lang { en, zh, ko }

/// User preferences, persisted in shared_preferences and broadcast to the UI.
class Settings extends ChangeNotifier {
  final SharedPreferences _p;
  Settings(this._p);

  // available timer durations (seconds); 0 = off (no limit).
  static const timerChoices = [0, 5, 10, 15];

  /// Once at startup: if the user has never picked a language, seed it from the
  /// device locale (Korean → ko, Chinese → zh, otherwise English).
  Future<void> applyDeviceLocaleDefault(String localeName) async {
    if (_p.containsKey('lang')) return;
    final code = localeName.toLowerCase();
    final def = code.startsWith('ko')
        ? Lang.ko
        : code.startsWith('zh')
            ? Lang.zh
            : Lang.en;
    await _p.setInt('lang', def.index);
    notifyListeners();
  }

  Lang get lang => Lang.values[_p.getInt('lang') ?? Lang.en.index];
  set lang(Lang v) {
    _p.setInt('lang', v.index);
    notifyListeners();
  }

  bool get isDark => _p.getBool('isDark') ?? false;
  set isDark(bool v) {
    _p.setBool('isDark', v);
    notifyListeners();
  }

  ScriptMode get scriptMode =>
      ScriptMode.values[_p.getInt('scriptMode') ?? ScriptMode.both.index];
  set scriptMode(ScriptMode v) {
    _p.setInt('scriptMode', v.index);
    notifyListeners();
  }

  /// Include voiced (濁音) + contracted (拗音) syllables in the practice pool.
  bool get includeExtended => _p.getBool('includeExtended') ?? false;
  set includeExtended(bool v) {
    _p.setBool('includeExtended', v);
    notifyListeners();
  }

  /// Drop fully-mastered (level 5) glyphs from the practice pool.
  bool get hideMastered => _p.getBool('hideMastered') ?? false;
  set hideMastered(bool v) {
    _p.setBool('hideMastered', v);
    notifyListeners();
  }

  /// Play downloaded recordings instead of TTS when available.
  bool get useVoicePack => _p.getBool('useVoicePack') ?? false;
  set useVoicePack(bool v) {
    _p.setBool('useVoicePack', v);
    notifyListeners();
  }

  /// Whether the first-launch intro has been shown.
  bool get introSeen => _p.getBool('introSeen') ?? false;
  set introSeen(bool v) {
    _p.setBool('introSeen', v);
    notifyListeners();
  }

  /// Seconds allowed to write a glyph; 0 means no timer.
  int get timerSeconds => _p.getInt('timerSeconds') ?? 5;
  set timerSeconds(int v) {
    _p.setInt('timerSeconds', v);
    notifyListeners();
  }

  /// When on, show an example word + emoji and read "word の kana".
  bool get wordMode => _p.getBool('wordMode') ?? false;
  set wordMode(bool v) {
    _p.setBool('wordMode', v);
    notifyListeners();
  }

  /// Silence the text-to-speech readings.
  bool get muted => _p.getBool('muted') ?? false;
  set muted(bool v) {
    _p.setBool('muted', v);
    notifyListeners();
  }
}
