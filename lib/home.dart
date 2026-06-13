import 'package:flutter/material.dart';

import 'l10n.dart';
import 'progress_page.dart';
import 'quiz_page.dart';
import 'settings.dart';
import 'settings_page.dart';
import 'store.dart';

/// Bottom-nav shell: practice · study · settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store, required this.settings});
  final Store store;
  final Settings settings;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Rebuild labels when the UI language changes.
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        final l = L10n(widget.settings.lang);
        return Scaffold(
          body: SafeArea(
            // Keep all three alive; the quiz pauses its timer when not on top.
            child: IndexedStack(
              index: _index,
              children: [
                QuizPage(
                  store: widget.store,
                  settings: widget.settings,
                  active: _index == 0,
                ),
                ProgressPage(store: widget.store, settings: widget.settings),
                SettingsPage(settings: widget.settings),
              ],
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.edit_outlined),
                selectedIcon: const Icon(Icons.edit),
                label: l.practice,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_outlined),
                selectedIcon: const Icon(Icons.bar_chart),
                label: l.study,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l.settings,
              ),
            ],
          ),
        );
      },
    );
  }
}
