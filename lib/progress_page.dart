import 'package:flutter/material.dart';

import 'kana.dart';
import 'kana_words.dart';
import 'l10n.dart';
import 'settings.dart';
import 'store.dart';

/// The study tab: mastery per glyph in gojūon (aiueo) order, split into
/// ひらがな / カタカナ sub-tabs. Tapping a card shows its example word.
class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.store, required this.settings});
  final Store store;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    // Rebuild when settings change (language/extended set) or progress is reset.
    return AnimatedBuilder(
      animation: Listenable.merge([settings, store]),
      builder: (context, _) {
        final l = L10n(settings.lang);
        // Study shows every single character (basic + voiced/dakuten), always,
        // independent of the practice-set toggle. Contracted yōon (きゃ) are two
        // glyphs in a row, not single characters, so they're not shown here.
        final chars = [...allKana, ...voicedKana];
        final hira = chars.where((k) => k.hiragana).toList();
        final kata = chars.where((k) => !k.hiragana).toList();
        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(tabs: [Tab(text: 'ひらがな'), Tab(text: 'カタカナ')]),
              Expanded(
                child: TabBarView(
                  children: [
                    _Grid(kana: hira, store: store, l: l),
                    _Grid(kana: kata, store: store, l: l),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.kana, required this.store, required this.l});
  final List<Kana> kana;
  final Store store;
  final L10n l;

  @override
  Widget build(BuildContext context) {
    // Responsive: cell count follows width (foldable cover → tablet).
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 110,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: kana.length,
      itemBuilder: (context, i) => _Cell(
        kana: kana[i],
        level: store.level(kana[i].glyph),
        onTap: () => _showDetail(context, kana[i], store.level(kana[i].glyph)),
      ),
    );
  }

  void _showDetail(BuildContext context, Kana k, int level) {
    final word = (k.hiragana ? hiraganaWords : katakanaWords)[k.romaji];
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          // Stay within the screen and scroll if the content is taller.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(k.glyph, style: const TextStyle(fontSize: 72)),
              Text(k.romaji,
                  style: TextStyle(
                      fontSize: 18, color: Theme.of(context).hintColor)),
              if (word != null) ...[
                const Divider(height: 28),
                Text(word.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 4),
                Text(word.word,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w500)),
                Text('${l.gloss(word)}  ·  ${l.wordOf(word.word, k.glyph)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).hintColor)),
              ],
              const SizedBox(height: 16),
              _Dots(level: level),
              const SizedBox(height: 4),
              Text('${l.mastery}  $level / ${Store.maxLevel}',
                  style: TextStyle(
                      fontSize: 12, color: Theme.of(context).hintColor)),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.close),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.kana, required this.level, required this.onTap});
  final Kana kana;
  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // FittedBox keeps two-codepoint yōon (きゃ) from overflowing.
            SizedBox(
              height: 40,
              child: FittedBox(
                child: Text(kana.glyph,
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w400)),
              ),
            ),
            Text(kana.romaji,
                style: TextStyle(fontSize: 12, color: theme.hintColor)),
            const SizedBox(height: 6),
            _Dots(level: level),
          ],
        ),
      ),
    );
  }
}

/// The five mastery dots, tinted from red (weak) to green (mastered).
class _Dots extends StatelessWidget {
  const _Dots({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = (level - Store.minLevel) / (Store.maxLevel - Store.minLevel);
    final accent = Color.lerp(Colors.redAccent, Colors.green, t)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = Store.minLevel; i <= Store.maxLevel; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1.5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= level
                    ? accent
                    : theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
          ),
      ],
    );
  }
}
