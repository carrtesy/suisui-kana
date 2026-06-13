import 'package:shared_preferences/shared_preferences.dart';

/// Persistence: total score + a per-glyph mastery level (1..5).
///
/// Mastery rises on a correct answer and falls on a miss, clamped to [1, 5].
/// Lower means less known, so the quiz samples it more often (see quiz_page).
class Store {
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
}
