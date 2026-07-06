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

  // practice-set extras
  String get extendedTitle =>
      _pick('Voiced kana', '浊音', '탁음');
  String get extendedSub => _pick(
        'Also practise voiced kana — が, ざ, だ, ば, ぱ…',
        '练习中加入浊音 — が、ざ、だ、ば、ぱ…',
        '연습에 탁음을 추가해요 — が, ざ, だ, ば, ぱ…',
      );
  String get hideMasteredTitle =>
      _pick('Hide mastered', '隐藏已掌握', '마스터한 글자 숨기기');
  String get hideMasteredSub => _pick(
        "Stop showing glyphs you've fully mastered.",
        '不再出现已完全掌握的假名。',
        '완전히 마스터한 글자는 더 이상 출제하지 않습니다.',
      );

  // voice pack
  String get voiceSection => _pick('Voice', '语音', '음성');
  String get voicePackTitle =>
      _pick('Use saved voice', '使用已保存语音', '저장된 음성 사용');
  String get voicePackSub => _pick(
        "Save each kana's voice and play that — same sound, instant & offline.",
        '把每个假名的朗读保存下来播放——发音相同，即时且离线。',
        '각 글자 음성을 저장해 재생해요. 소리는 지금과 같고, 즉시·오프라인.',
      );
  String get download => _pick('Build voice files', '生成语音', '음성 파일 만들기');
  String get downloading => _pick('Building…', '生成中…', '만드는 중…');
  String get downloaded => _pick('Ready', '已就绪', '준비 완료');
  String get downloadFailed =>
      _pick("Couldn't build files", '生成失败', '만들기 실패');
  String get voiceReady => _pick('Voice ready', '语音已就绪', '음성 준비 완료');
  String get voiceRebuild => _pick(
        'Saved on device — tap to rebuild',
        '已保存到本机 — 点按可重新生成',
        '기기에 저장됨 — 다시 만들려면 탭',
      );

  // progress reset
  String get progressSection => _pick('Progress', '进度', '진도');
  String get resetProgress => _pick('Reset progress', '重置进度', '기록 초기화');
  String get resetConfirmTitle =>
      _pick('Reset progress?', '重置进度？', '기록을 초기화할까요?');
  String get resetConfirmBody => _pick(
        "This erases every mastery level and your score. It can't be undone.",
        '将清除所有掌握度和分数，且无法恢复。',
        '모든 숙련도와 점수가 지워지며 되돌릴 수 없습니다.',
      );
  String get cancel => _pick('Cancel', '取消', '취소');
  String get reset => _pick('Reset', '重置', '초기화');
  String get resetDone => _pick('Progress reset', '已重置', '기록을 초기화했어요');

  // intro / onboarding — a 3-slide first-launch walkthrough
  String get introTagline =>
      _pick('Learn kana by writing them.', '通过书写学习假名。', '써보면서 익히는 일본어 글자');

  String get introWriteTitle =>
      _pick('Write it', '动手书写', '직접 써보기');
  String get introWriteBody => _pick(
        'A reading appears — write the kana on the pad to learn it by hand.',
        '出现读音，在书写板上写出假名，边写边记。',
        '글자를 써보며 익혀요. 읽는 소리에 맞춰 직접 써보세요.',
      );

  String get introStudyTitle =>
      _pick('Track it', '查看进度', '학습 확인');
  String get introStudyBody => _pick(
        'Tap a card in the Study tab to check your progress and review each kana.',
        '在“学习”标签点击卡片，查看学习进度并复习假名。',
        '학습 탭에서 카드를 눌러 현재 학습 상황을 확인하고 문자를 익혀봐요.',
      );

  String get introFinishTitle =>
      _pick('Master it', '坚持到底', '끝까지');
  String get introFinishBody => _pick(
        'Keep going until you master\nhiragana and katakana!',
        '坚持到掌握所有平假名和片假名！',
        '히라가나·가타카나,\n끝까지 포기하지 말아요!',
      );

  String get introNext => _pick('Next', '下一步', '다음');
  String get introSkip => _pick('Skip', '跳过', '건너뛰기');
  String get getStarted => _pick('Get started', '开始', '시작하기');
  String get howToUse => _pick('How to use', '使用说明', '앱 사용법');

  // full-mastery celebration
  String get celebrateTitle =>
      _pick('Congratulations!', '恭喜你！', '축하해요!');
  String get celebrateBody => _pick(
        'It was a joy to share your very first Japanese with you.',
        '很高兴陪你写下第一笔日语。',
        '당신의 첫 일본어를 함께해서 기뻤습니다.',
      );
  String get done => _pick('Done', '完成', '완료');

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
