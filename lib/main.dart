import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'settings.dart';
import 'store.dart';
import 'theme.dart';

/// AdMob test-device hashes (debug builds only). Fill from logcat after the
/// first run; empty means every debug ad request still hits the real unit.
const List<String> _testDeviceIds = <String>[
  '6B771F0C07505FD244FE01747555DACB', // Galaxy Z Flip (dev phone)
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = Settings(prefs);
  // First run only: seed the UI language from the device locale.
  await settings.applyDeviceLocaleDefault(Platform.localeName);
  // Safety: in debug builds, serve test ads to our own devices so we never
  // rack up invalid traffic on the real ad unit. Run once, copy the device
  // hash logcat prints ("Use ... setTestDeviceIds(...)"), and paste it here.
  if (kDebugMode && _testDeviceIds.isNotEmpty) {
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: _testDeviceIds),
    );
  }
  // Fire-and-forget: the banner loads once ads are ready.
  unawaited(MobileAds.instance.initialize());
  runApp(SuisuiKanaApp(store: Store(prefs), settings: settings));
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
