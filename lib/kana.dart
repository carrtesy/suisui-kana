// The gojūon for both scripts, plus the voiced (濁音/半濁音) and
// contracted (拗音) syllables. Built from parallel rows to stay terse.

/// How a syllable is categorised, for pool filtering and the study grid.
///   basic    — the 46 gojūon (あ か さ …)
///   dakuten  — voiced + semi-voiced (が ざ だ ば ぱ …)
///   yoon     — contracted combos (きゃ しゅ ちょ …)
enum KanaKind { basic, dakuten, yoon }

class Kana {
  final String glyph; // あ / ア / きゃ
  final String romaji; // a / kya
  final bool hiragana;
  final KanaKind kind;
  const Kana(this.glyph, this.romaji, this.hiragana,
      [this.kind = KanaKind.basic]);
}

// ── basic gojūon ──────────────────────────────────────────────────────────
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

// ── voiced (濁音) + semi-voiced (半濁音) ──────────────────────────────────
// Parallel (glyph, romaji) rows so hira/kata stay aligned. ぢ/づ (yotsugana) are
// omitted: they sound identical to じ/ず, are almost never used, and would make
// the prompt ambiguous — so the だ row is just だ・で・ど here.
const _dakutenReadings = [
  'ga', 'gi', 'gu', 'ge', 'go', //
  'za', 'ji', 'zu', 'ze', 'zo', //
  'da', 'de', 'do', //
  'ba', 'bi', 'bu', 'be', 'bo', //
  'pa', 'pi', 'pu', 'pe', 'po', //
];

const _dakutenHira =
    'がぎぐげご'
    'ざじずぜぞ'
    'だでど'
    'ばびぶべぼ'
    'ぱぴぷぺぽ';

const _dakutenKata =
    'ガギグゲゴ'
    'ザジズゼゾ'
    'ダデド'
    'バビブベボ'
    'パピプペポ';

// ── contracted (拗音) ─────────────────────────────────────────────────────
// Two-codepoint combos, so kept as explicit lists rather than string indexing.
const _yoonReadings = [
  'kya', 'kyu', 'kyo', //
  'sha', 'shu', 'sho', //
  'cha', 'chu', 'cho', //
  'nya', 'nyu', 'nyo', //
  'hya', 'hyu', 'hyo', //
  'mya', 'myu', 'myo', //
  'rya', 'ryu', 'ryo', //
  'gya', 'gyu', 'gyo', //
  'ja', 'ju', 'jo', //
  'bya', 'byu', 'byo', //
  'pya', 'pyu', 'pyo', //
];

const _yoonHira = [
  'きゃ', 'きゅ', 'きょ', //
  'しゃ', 'しゅ', 'しょ', //
  'ちゃ', 'ちゅ', 'ちょ', //
  'にゃ', 'にゅ', 'にょ', //
  'ひゃ', 'ひゅ', 'ひょ', //
  'みゃ', 'みゅ', 'みょ', //
  'りゃ', 'りゅ', 'りょ', //
  'ぎゃ', 'ぎゅ', 'ぎょ', //
  'じゃ', 'じゅ', 'じょ', //
  'びゃ', 'びゅ', 'びょ', //
  'ぴゃ', 'ぴゅ', 'ぴょ', //
];

const _yoonKata = [
  'キャ', 'キュ', 'キョ', //
  'シャ', 'シュ', 'ショ', //
  'チャ', 'チュ', 'チョ', //
  'ニャ', 'ニュ', 'ニョ', //
  'ヒャ', 'ヒュ', 'ヒョ', //
  'ミャ', 'ミュ', 'ミョ', //
  'リャ', 'リュ', 'リョ', //
  'ギャ', 'ギュ', 'ギョ', //
  'ジャ', 'ジュ', 'ジョ', //
  'ビャ', 'ビュ', 'ビョ', //
  'ピャ', 'ピュ', 'ピョ', //
];

List<Kana> _rows(String glyphs, List<String> readings, bool hira, KanaKind k) =>
    [for (var i = 0; i < readings.length; i++) Kana(glyphs[i], readings[i], hira, k)];

List<Kana> _list(List<String> glyphs, List<String> readings, bool hira,
        KanaKind k) =>
    [for (var i = 0; i < readings.length; i++) Kana(glyphs[i], readings[i], hira, k)];

/// The basic 46+46 gojūon (unchanged default set).
final List<Kana> allKana = [
  ..._rows(_hira, _readings, true, KanaKind.basic),
  ..._rows(_kata, _readings, false, KanaKind.basic),
];

/// Voiced + semi-voiced only (が, ぱ …) — single glyphs, so they can be drawn
/// and graded in the quiz.
final List<Kana> voicedKana = [
  ..._rows(_dakutenHira, _dakutenReadings, true, KanaKind.dakuten),
  ..._rows(_dakutenKata, _dakutenReadings, false, KanaKind.dakuten),
];

/// Contracted syllables (きゃ …) — two glyphs in a row. Shown in the study grid
/// for reference, but never used as a writing target (see quiz_page).
final List<Kana> yoonKana = [
  ..._list(_yoonHira, _yoonReadings, true, KanaKind.yoon),
  ..._list(_yoonKata, _yoonReadings, false, KanaKind.yoon),
];

/// Voiced + contracted, both scripts (study reference set).
final List<Kana> extendedKana = [...voicedKana, ...yoonKana];

/// Every syllable the app knows about (basic first, then extended).
final List<Kana> everyKana = [...allKana, ...extendedKana];

/// Kana that never begin a word: word mode reads just the bare glyph and shows
/// no word hint (ん → みかん contains, を is a particle).
bool isCharacterOnly(String romaji) => romaji == 'n' || romaji == 'wo';

Kana? kanaForGlyph(String glyph) {
  for (final k in everyKana) {
    if (k.glyph == glyph) return k;
  }
  return null;
}
