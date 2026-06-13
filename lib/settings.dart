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

  // available timer durations (seconds); 0 = off.
  static const timerChoices = [0, 3, 5, 10, 15];

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
