import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'settings.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SuisuiKanaApp(store: Store(prefs), settings: Settings(prefs)));
}

class SuisuiKanaApp extends StatelessWidget {
  const SuisuiKanaApp({super.key, required this.store, required this.settings});
  final Store store;
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    // Rebuild on settings changes so the theme (and quiz) react live.
    return AnimatedBuilder(
      animation: settings,
      builder: (_, __) => MaterialApp(
        title: 'Suisui Kana',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
        home: HomeShell(store: store, settings: settings),
      ),
    );
  }
}
