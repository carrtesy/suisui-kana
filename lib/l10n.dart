import 'kana_words.dart';
import 'settings.dart';

/// Tiny hand-rolled localization for the three supported UI languages.
class L10n {
  final Lang lang;
  const L10n(this.lang);

  T _pick<T>(T en, T zh, T ko) => switch (lang) {
        Lang.en => en,
        Lang.zh => zh,
        Lang.ko => ko,
      };

  // bottom navigation
  String get practice => _pick('Practice', '练习', '연습');
  String get study => _pick('Study', '学习', '학습');
  String get settings => _pick('Settings', '设置', '설정');

  // settings sections / rows
  String get language => _pick('Language', '语言', '언어');
  String get darkMode => _pick('Dark mode', '深色模式', '다크 모드');
  String get practiceSet => _pick('Practice set', '练习对象', '연습 대상');
  String get both => _pick('Both', '两者', '둘 다');
  String get timeLimit => _pick('Write time limit', '书写限时', '쓰기 제한 시간');
  String get timerOff => _pick('Off', '关', '끄기');
  String get readingMode => _pick('Reading mode', '朗读模式', '읽기 모드');
  String get wordModeTitle =>
      _pick('Show & read example word', '显示并朗读例词', '단어 함께 보기·읽기');
  String get wordModeSub => _pick(
        'On: shows an example word + picture and reads "word の kana".',
        '开启后显示例词和图片，并以"单词 の 假名"朗读。',
        '켜면 예시 단어와 그림을 보여주고 "단어 の 글자"로 읽어줍니다.',
      );

  // a timer chip label, e.g. "5s" / "5秒" / "5초"
  String timerLabel(int s) =>
      s == 0 ? timerOff : _pick('${s}s', '$s秒', '$s초');

  // quiz feedback
  String get correct => _pick('Correct', '正确', '정답');
  String get answer => _pick('Answer', '答案', '정답');

  // study detail
  String get mastery => _pick('Mastery', '掌握度', '숙련도');
  String get close => _pick('Close', '关闭', '닫기');

  // Japanese TTS voice install prompt
  String get ttsMissing => _pick(
        'Japanese voice not installed — readings may be in English.',
        '未安装日语语音，朗读可能为英文。',
        '일본어 음성이 없어 영어로 읽힐 수 있습니다.',
      );
  String get install => _pick('Install', '安装', '설치');
  String get sound => _pick('Sound', '声音', '소리');

  /// "「word」's 「kana」" hint shown after answering in word mode.
  String wordOf(String word, String kana) => _pick(
        '「$word」 → 「$kana」',
        '「$word」的「$kana」',
        '「$word」의 「$kana」',
      );

  /// The gloss of a word in the current language.
  String gloss(KanaWord w) => _pick(w.en, w.zh, w.ko);
}
