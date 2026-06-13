import 'package:flutter/material.dart';

// Light & dark themes. Kana stays high-contrast in both.
const _font = 'Hiragino Sans';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  fontFamily: _font,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.black,
    brightness: Brightness.light,
    primary: Colors.black,
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  fontFamily: _font,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF121212),
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.white,
    brightness: Brightness.dark,
    primary: Colors.white,
  ),
);
