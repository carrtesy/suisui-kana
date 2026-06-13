// Single source of truth for the per-kana example words.
//
// Curation rules (for absolute beginners):
//  - the word STARTS with its kana (ん has no such word — みかん ends with it;
//    を is only an object particle — both are kept as the natural exception);
//  - common, concrete, everyday nouns a beginner actually runs into;
//  - hiragana = native Japanese words; katakana = loanwords (외래어);
//  - one emoji stands in for a cartoon picture; glosses in en / zh / ko.
//
// A few rows (る, を) genuinely lack an easy everyday native noun, so their
// examples are the best available common word.

class KanaWord {
  final String word; // あめ
  final String romaji; // ame
  final String emoji; // 🌧️
  final String en; // English meaning, e.g. "rain"
  final String zh; // Simplified Chinese, e.g. "雨"
  final String ko; // Korean, e.g. "비"
  const KanaWord(this.word, this.romaji, this.emoji, this.en, this.zh, this.ko);
}

// keyed by the romaji reading of the kana
const Map<String, KanaWord> hiraganaWords = {
  'a': KanaWord('あめ', 'ame', '🌧️', 'rain', '雨', '비'),
  'i': KanaWord('いぬ', 'inu', '🐶', 'dog', '狗', '개'),
  'u': KanaWord('うみ', 'umi', '🌊', 'sea', '海', '바다'),
  'e': KanaWord('えき', 'eki', '🚉', 'station', '车站', '역'),
  'o': KanaWord('おに', 'oni', '👹', 'ogre', '鬼', '도깨비'),
  'ka': KanaWord('かさ', 'kasa', '☂️', 'umbrella', '雨伞', '우산'),
  'ki': KanaWord('きつね', 'kitsune', '🦊', 'fox', '狐狸', '여우'),
  'ku': KanaWord('くつ', 'kutsu', '👟', 'shoes', '鞋', '신발'),
  'ke': KanaWord('けいたい', 'keitai', '📱', 'phone', '手机', '휴대폰'),
  'ko': KanaWord('こども', 'kodomo', '🧒', 'child', '小孩', '아이'),
  'sa': KanaWord('さかな', 'sakana', '🐟', 'fish', '鱼', '물고기'),
  'shi': KanaWord('しお', 'shio', '🧂', 'salt', '盐', '소금'),
  'su': KanaWord('すし', 'sushi', '🍣', 'sushi', '寿司', '초밥'),
  'se': KanaWord('せんせい', 'sensei', '👩‍🏫', 'teacher', '老师', '선생님'),
  'so': KanaWord('そら', 'sora', '🌌', 'sky', '天空', '하늘'),
  'ta': KanaWord('たまご', 'tamago', '🥚', 'egg', '鸡蛋', '계란'),
  'chi': KanaWord('ちず', 'chizu', '🗺️', 'map', '地图', '지도'),
  'tsu': KanaWord('つき', 'tsuki', '🌙', 'moon', '月亮', '달'),
  'te': KanaWord('てぶくろ', 'tebukuro', '🧤', 'gloves', '手套', '장갑'),
  'to': KanaWord('とり', 'tori', '🐦', 'bird', '鸟', '새'),
  'na': KanaWord('なつ', 'natsu', '☀️', 'summer', '夏天', '여름'),
  'ni': KanaWord('にく', 'niku', '🥩', 'meat', '肉', '고기'),
  'nu': KanaWord('ぬいぐるみ', 'nuigurumi', '🧸', 'plush toy', '玩偶', '인형'),
  'ne': KanaWord('ねこ', 'neko', '🐱', 'cat', '猫', '고양이'),
  'no': KanaWord('のみもの', 'nomimono', '🥤', 'drink', '饮料', '음료'),
  'ha': KanaWord('はな', 'hana', '🌸', 'flower', '花', '꽃'),
  'hi': KanaWord('ひつじ', 'hitsuji', '🐑', 'sheep', '绵羊', '양'),
  'fu': KanaWord('ふね', 'fune', '🚢', 'boat', '船', '배'),
  'he': KanaWord('へび', 'hebi', '🐍', 'snake', '蛇', '뱀'),
  'ho': KanaWord('ほし', 'hoshi', '⭐', 'star', '星星', '별'),
  'ma': KanaWord('まど', 'mado', '🪟', 'window', '窗', '창문'),
  'mi': KanaWord('みず', 'mizu', '💧', 'water', '水', '물'),
  'mu': KanaWord('むすめ', 'musume', '👧', 'daughter', '女儿', '딸'),
  'me': KanaWord('めがね', 'megane', '👓', 'glasses', '眼镜', '안경'),
  'mo': KanaWord('もも', 'momo', '🍑', 'peach', '桃子', '복숭아'),
  'ya': KanaWord('やま', 'yama', '⛰️', 'mountain', '山', '산'),
  'yu': KanaWord('ゆき', 'yuki', '❄️', 'snow', '雪', '눈'),
  'yo': KanaWord('よる', 'yoru', '🌃', 'night', '夜晚', '밤'),
  'ra': KanaWord('らっぱ', 'rappa', '🎺', 'trumpet', '喇叭', '나팔'),
  'ri': KanaWord('りんご', 'ringo', '🍎', 'apple', '苹果', '사과'),
  'ru': KanaWord('るす', 'rusu', '🏠', 'not home', '不在家', '부재중'),
  're': KanaWord('れっしゃ', 'ressha', '🚆', 'train', '火车', '기차'),
  'ro': KanaWord('ろうそく', 'rousoku', '🕯️', 'candle', '蜡烛', '양초'),
  'wa': KanaWord('わに', 'wani', '🐊', 'crocodile', '鳄鱼', '악어'),
  // を is only an object particle — no word begins with it.
  'wo': KanaWord('を', 'wo', '➡️', 'object particle', '宾语助词', '을/를(조사)'),
  // ん never starts a word — みかん ends with it.
  'n': KanaWord('みかん', 'mikan', '🍊', 'mandarin', '橘子', '귤'),
};

const Map<String, KanaWord> katakanaWords = {
  'a': KanaWord('アイス', 'aisu', '🍦', 'ice cream', '冰淇淋', '아이스크림'),
  'i': KanaWord('イヤホン', 'iyahon', '🎧', 'earphones', '耳机', '이어폰'),
  'u': KanaWord('ウール', 'uuru', '🧶', 'wool', '羊毛', '울'),
  'e': KanaWord('エアコン', 'eakon', '❄️', 'air con', '空调', '에어컨'),
  'o': KanaWord('オレンジ', 'orenji', '🍊', 'orange', '橙子', '오렌지'),
  'ka': KanaWord('カメラ', 'kamera', '📷', 'camera', '相机', '카메라'),
  'ki': KanaWord('キウイ', 'kiui', '🥝', 'kiwi', '猕猴桃', '키위'),
  'ku': KanaWord('クッキー', 'kukkii', '🍪', 'cookie', '饼干', '쿠키'),
  'ke': KanaWord('ケーキ', 'keeki', '🍰', 'cake', '蛋糕', '케이크'),
  'ko': KanaWord('コーヒー', 'koohii', '☕', 'coffee', '咖啡', '커피'),
  'sa': KanaWord('サラダ', 'sarada', '🥗', 'salad', '沙拉', '샐러드'),
  'shi': KanaWord('シャツ', 'shatsu', '👕', 'shirt', '衬衫', '셔츠'),
  'su': KanaWord('スプーン', 'supuun', '🥄', 'spoon', '勺子', '숟가락'),
  'se': KanaWord('セーター', 'seetaa', '🧥', 'sweater', '毛衣', '스웨터'),
  'so': KanaWord('ソファ', 'sofa', '🛋️', 'sofa', '沙发', '소파'),
  'ta': KanaWord('タクシー', 'takushii', '🚕', 'taxi', '出租车', '택시'),
  'chi': KanaWord('チーズ', 'chiizu', '🧀', 'cheese', '奶酪', '치즈'),
  'tsu': KanaWord('ツナ', 'tsuna', '🐟', 'tuna', '金枪鱼', '참치'),
  'te': KanaWord('テレビ', 'terebi', '📺', 'TV', '电视', '텔레비전'),
  'to': KanaWord('トマト', 'tomato', '🍅', 'tomato', '番茄', '토마토'),
  'na': KanaWord('ナイフ', 'naifu', '🔪', 'knife', '刀', '나이프'),
  'ni': KanaWord('ニュース', 'nyuusu', '📰', 'news', '新闻', '뉴스'),
  'nu': KanaWord('ヌードル', 'nuudoru', '🍜', 'noodles', '面条', '누들'),
  'ne': KanaWord('ネクタイ', 'nekutai', '👔', 'necktie', '领带', '넥타이'),
  'no': KanaWord('ノート', 'nooto', '📓', 'notebook', '笔记本', '노트'),
  'ha': KanaWord('ハンバーガー', 'hanbaagaa', '🍔', 'hamburger', '汉堡', '햄버거'),
  'hi': KanaWord('ヒーター', 'hiitaa', '🔥', 'heater', '暖气', '히터'),
  'fu': KanaWord('フォーク', 'fooku', '🍴', 'fork', '叉子', '포크'),
  'he': KanaWord('ヘルメット', 'herumetto', '⛑️', 'helmet', '头盔', '헬멧'),
  'ho': KanaWord('ホテル', 'hoteru', '🏨', 'hotel', '酒店', '호텔'),
  'ma': KanaWord('マスク', 'masuku', '😷', 'mask', '口罩', '마스크'),
  'mi': KanaWord('ミルク', 'miruku', '🥛', 'milk', '牛奶', '우유'),
  'mu': KanaWord('ムービー', 'muubii', '🎬', 'movie', '电影', '영화'),
  'me': KanaWord('メロン', 'meron', '🍈', 'melon', '甜瓜', '멜론'),
  'mo': KanaWord('モニター', 'monitaa', '🖥️', 'monitor', '显示器', '모니터'),
  'ya': KanaWord('ヤクルト', 'yakuruto', '🥤', 'Yakult', '养乐多', '야쿠르트'),
  'yu': KanaWord('ユニコーン', 'yunikoon', '🦄', 'unicorn', '独角兽', '유니콘'),
  'yo': KanaWord('ヨーグルト', 'yooguruto', '🥛', 'yogurt', '酸奶', '요거트'),
  'ra': KanaWord('ラーメン', 'raamen', '🍜', 'ramen', '拉面', '라면'),
  'ri': KanaWord('リボン', 'ribon', '🎀', 'ribbon', '丝带', '리본'),
  'ru': KanaWord('ルーター', 'ruutaa', '📡', 'router', '路由器', '공유기'),
  're': KanaWord('レモン', 'remon', '🍋', 'lemon', '柠檬', '레몬'),
  'ro': KanaWord('ロボット', 'robotto', '🤖', 'robot', '机器人', '로봇'),
  'wa': KanaWord('ワイン', 'wain', '🍷', 'wine', '葡萄酒', '와인'),
  'wo': KanaWord('ウォーター', 'wootaa', '💧', 'water', '水', '물'),
  'n': KanaWord('ペン', 'pen', '🖊️', 'pen', '笔', '펜'),
};
