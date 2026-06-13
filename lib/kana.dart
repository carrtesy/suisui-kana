// The full gojūon for both scripts, built from parallel rows to stay terse.

class Kana {
  final String glyph; // あ / ア
  final String romaji; // a
  final bool hiragana;
  const Kana(this.glyph, this.romaji, this.hiragana);
}

// romaji reading for each column, in row order.
const _readings = [
  'a', 'i', 'u', 'e', 'o', //
  'ka', 'ki', 'ku', 'ke', 'ko', //
  'sa', 'shi', 'su', 'se', 'so', //
  'ta', 'chi', 'tsu', 'te', 'to', //
  'na', 'ni', 'nu', 'ne', 'no', //
  'ha', 'hi', 'fu', 'he', 'ho', //
  'ma', 'mi', 'mu', 'me', 'mo', //
  'ya', 'yu', 'yo', //
  'ra', 'ri', 'ru', 're', 'ro', //
  'wa', 'wo', 'n', //
];

const _hira =
    'あいうえお'
    'かきくけこ'
    'さしすせそ'
    'たちつてと'
    'なにぬねの'
    'はひふへほ'
    'まみむめも'
    'やゆよ'
    'らりるれろ'
    'わをん';

const _kata =
    'アイウエオ'
    'カキクケコ'
    'サシスセソ'
    'タチツテト'
    'ナニヌネノ'
    'ハヒフヘホ'
    'マミムメモ'
    'ヤユヨ'
    'ラリルレロ'
    'ワヲン';

final List<Kana> allKana = [
  for (var i = 0; i < _readings.length; i++) Kana(_hira[i], _readings[i], true),
  for (var i = 0; i < _readings.length; i++) Kana(_kata[i], _readings[i], false),
];

Kana? kanaForGlyph(String glyph) {
  for (final k in allKana) {
    if (k.glyph == glyph) return k;
  }
  return null;
}
