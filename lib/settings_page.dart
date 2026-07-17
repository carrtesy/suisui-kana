import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'audio.dart';
import 'intro_page.dart';
import 'kana.dart';
import 'kana_words.dart';
import 'l10n.dart';
import 'settings.dart';
import 'store.dart';

/// The settings tab. Binds directly to the [Settings] notifier.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.store,
    required this.voice,
  });
  final Settings settings;
  final Store store;
  final VoiceService voice;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Settings get settings => widget.settings;

  // voice-pack download progress; null when idle.
  double? _dlProgress;

  // Script options shown to the user; "both" label is localized.
  String _scriptLabel(ScriptMode m, L10n l) => switch (m) {
        ScriptMode.hiragana => 'ひらがな',
        ScriptMode.katakana => 'カタカナ',
        ScriptMode.both => l.both,
      };

  Future<void> _confirmReset(L10n l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.resetConfirmTitle),
        content: Text(l.resetConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(l.reset),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.store.resetProgress();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.resetDone)),
        );
      }
    }
  }

  /// Every utterance the voice pack should hold (key → text to synthesize):
  /// the plain single-syllable readings AND the word-mode phrases, so both
  /// modes can play from files. This is the source of truth for both building
  /// and the "what's still missing" check.
  Map<String, String> _voiceItems() {
    final items = <String, String>{};
    // single-kana readings — both scripts share the sound, so key by romaji.
    // yōon are never spoken/quizzed, so only single-character sounds.
    for (final k in [...allKana, ...voicedKana]) {
      items.putIfAbsent(k.romaji, () => k.glyph);
    }
    // word-mode phrases — one per script (different example words), including
    // voiced kana; entries without a word (ん / を / ぢ / づ) are skipped.
    for (final k in [...allKana, ...voicedKana]) {
      if (isCharacterOnly(k.romaji)) continue;
      final w = (k.hiragana ? hiraganaWords : katakanaWords)[k.romaji];
      if (w == null) continue;
      items['word_${k.hiragana ? 'h' : 'k'}_${k.romaji}'] =
          '${w.word} の、 ${k.glyph}';
    }
    return items;
  }

  /// Synthesize only the files that aren't there yet, so an app update just
  /// tops up the new sounds instead of rebuilding everything.
  Future<void> _buildVoicePack(L10n l) async {
    if (_dlProgress != null) return;
    final todo = {
      for (final e in _voiceItems().entries)
        if (!widget.voice.hasRecording(e.key)) e.key: e.value,
    };
    if (todo.isEmpty) return;
    setState(() => _dlProgress = 0);
    final ok = await widget.voice.buildPack(
      todo,
      (done, total) {
        if (mounted) setState(() => _dlProgress = done / total);
      },
    );
    if (!mounted) return;
    setState(() => _dlProgress = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok > 0 ? '${l.downloaded} ($ok)' : l.downloadFailed),
    ));
  }

  Future<void> _openCoffee(L10n l) async {
    final uri = Uri.parse('https://buymeacoffee.com/carrtesy');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.linkFailed)));
    }
  }

  Future<void> _deleteVoicePack(L10n l) async {
    await widget.voice.clearPack();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.voiceDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        final l = L10n(settings.lang);
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _SectionTitle(l.settings),
            // Language: native names, independent of current selection.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.language),
                  const SizedBox(width: 16),
                  Expanded(child: Text(l.language)),
                  SegmentedButton<Lang>(
                    segments: const [
                      ButtonSegment(value: Lang.en, label: Text('EN')),
                      ButtonSegment(value: Lang.zh, label: Text('中文')),
                      ButtonSegment(value: Lang.ko, label: Text('한국어')),
                    ],
                    selected: {settings.lang},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => settings.lang = s.first,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(l.darkMode),
              value: settings.isDark,
              onChanged: (v) => settings.isDark = v,
            ),
            // Re-open the first-launch walkthrough anytime.
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: Text(l.howToUse),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (ctx) => IntroPage(
                  settings: settings,
                  onDone: () => Navigator.of(ctx).pop(),
                ),
              )),
            ),
            const Divider(height: 1),
            _SectionTitle(l.practiceSet),
            RadioGroup<ScriptMode>(
              groupValue: settings.scriptMode,
              onChanged: (v) => settings.scriptMode = v!,
              child: Column(
                children: [
                  for (final m in ScriptMode.values)
                    RadioListTile<ScriptMode>(
                        title: Text(_scriptLabel(m, l)), value: m),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.auto_awesome_outlined),
              title: Text(l.extendedTitle),
              subtitle: Text(l.extendedSub),
              value: settings.includeExtended,
              onChanged: (v) => settings.includeExtended = v,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.visibility_off_outlined),
              title: Text(l.hideMasteredTitle),
              subtitle: Text(l.hideMasteredSub),
              value: settings.hideMastered,
              onChanged: (v) => settings.hideMastered = v,
            ),
            const Divider(height: 1),
            _SectionTitle(l.timeLimit),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final s in Settings.timerChoices)
                    ChoiceChip(
                      label: Text(l.timerLabel(s)),
                      selected: settings.timerSeconds == s,
                      onSelected: (_) => settings.timerSeconds = s,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            _SectionTitle(l.readingMode),
            SwitchListTile(
              secondary: const Icon(Icons.menu_book_outlined),
              title: Text(l.wordModeTitle),
              subtitle: Text(l.wordModeSub),
              value: settings.wordMode,
              onChanged: (v) => settings.wordMode = v,
            ),
            const Divider(height: 1),
            _SectionTitle(l.voiceSection),
            SwitchListTile(
              secondary: const Icon(Icons.record_voice_over_outlined),
              title: Text(l.voicePackTitle),
              subtitle: Text(l.voicePackSub),
              value: settings.useVoicePack,
              onChanged: (v) => settings.useVoicePack = v,
            ),
            Builder(builder: (context) {
              final building = _dlProgress != null;
              final has = widget.voice.hasAnyRecording;
              // Files that still need synthesizing (e.g. new words after an
              // app update). >0 while some exist → offer an "update".
              final missing = widget.voice.missingCount(_voiceItems().keys);
              final ready = !building && has && missing == 0;
              final update = !building && has && missing > 0;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      ready
                          ? Icons.check_circle
                          : (update
                              ? Icons.sync_problem
                              : Icons.download_outlined),
                      color: ready
                          ? Colors.green
                          : (update ? Colors.orange : null),
                    ),
                    title: Text(building
                        ? l.downloading
                        : ready
                            ? l.voiceReady
                            : update
                                ? l.voiceUpdate
                                : l.download),
                    subtitle: building
                        ? LinearProgressIndicator(value: _dlProgress)
                        : ready
                            ? Text(l.voiceRebuild)
                            : update
                                ? Text(l.voiceUpdateSub(missing))
                                : null,
                    trailing: building
                        ? Text('${(_dlProgress! * 100).round()}%')
                        : const Icon(Icons.chevron_right),
                    onTap: building || ready ? null : () => _buildVoicePack(l),
                  ),
                  // Delete the saved audio (e.g. to reclaim space, or to force a
                  // clean rebuild if a word changed).
                  if (has && !building)
                    ListTile(
                      leading: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      title: Text(l.voiceDelete,
                          style: const TextStyle(color: Colors.redAccent)),
                      onTap: () => _deleteVoicePack(l),
                    ),
                ],
              );
            }),
            const Divider(height: 1),
            _SectionTitle(l.progressSection),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.redAccent),
              title: Text(l.resetProgress,
                  style: const TextStyle(color: Colors.redAccent)),
              onTap: () => _confirmReset(l),
            ),
            const Divider(height: 1),
            _SectionTitle(l.supportSection),
            ListTile(
              leading: const Text('☕', style: TextStyle(fontSize: 22)),
              title: Text(l.buyCoffee),
              subtitle: Text(l.buyCoffeeSub),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openCoffee(l),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
