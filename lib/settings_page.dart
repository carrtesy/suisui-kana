import 'package:flutter/material.dart';

import 'l10n.dart';
import 'settings.dart';

/// The settings tab. Binds directly to the [Settings] notifier.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings});
  final Settings settings;

  // Script options shown to the user; "both" label is localized.
  String _scriptLabel(ScriptMode m, L10n l) => switch (m) {
        ScriptMode.hiragana => 'ひらがな',
        ScriptMode.katakana => 'カタカナ',
        ScriptMode.both => l.both,
      };

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
