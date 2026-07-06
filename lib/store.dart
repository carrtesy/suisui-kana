import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kana.dart';

/// Persistence: total score + a per-glyph mastery level (1..5).
///
/// Mastery rises on a correct answer and falls on a miss, clamped to [1, 5].
/// Lower means less known, so the quiz samples it more often (see quiz_page).
///
/// Extends [ChangeNotifier] so the study grid refreshes after a reset.
class Store extends ChangeNotifier {
  final SharedPreferences _p;
  Store(this._p);

  static const _kScore = 'score';
  static const goal = 100;
  static const minLevel = 1;
  static const maxLevel = 5;

  int get score => _p.getInt(_kScore) ?? 0;
  Future<void> setScore(int v) => _p.setInt(_kScore, v);

  /// Mastery for a glyph, 1..5. New glyphs start at the minimum (sampled most).
  int level(String glyph) =>
      (_p.getInt('lv_$glyph') ?? minLevel).clamp(minLevel, maxLevel);

  Future<void> _setLevel(String glyph, int v) =>
      _p.setInt('lv_$glyph', v.clamp(minLevel, maxLevel));

  Future<void> recordCorrect(String glyph) =>
      _setLevel(glyph, level(glyph) + 1);
  Future<void> recordWrong(String glyph) => _setLevel(glyph, level(glyph) - 1);

  bool isMastered(String glyph) => level(glyph) >= maxLevel;

  /// Whether the full-mastery celebration has already been shown for the
  /// current run of progress (cleared by [resetProgress] and when mastery
  /// drops back below complete).
  bool get celebrated => _p.getBool('celebrated') ?? false;
  Future<void> setCelebrated(bool v) => _p.setBool('celebrated', v);

  /// True only once every glyph in [pool] sits at max mastery.
  bool allMastered(Iterable<Kana> pool) =>
      pool.isNotEmpty && pool.every((k) => isMastered(k.glyph));

  int masteredCount(Iterable<Kana> pool) =>
      pool.where((k) => isMastered(k.glyph)).length;

  /// Wipe all progress: every per-glyph level and the running score.
  Future<void> resetProgress() async {
    final keys = _p
        .getKeys()
        .where((k) => k.startsWith('lv_') || k == _kScore || k == 'celebrated')
        .toList();
    for (final k in keys) {
      await _p.remove(k);
    }
    notifyListeners();
  }
}
