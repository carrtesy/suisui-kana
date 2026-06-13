# Suisui Kana

**すいすい** ("smoothly") learn hiragana & katakana by **writing** them. You
hear/see a reading, draw the glyph on screen, and an on-device model checks it.
Hit **100** and you get a congratulations screen — then keep practicing. Cool.

- Android / iOS only (no web).
- Recognition: Google ML Kit **Digital Ink** Japanese model — runs offline after
  a one-time download. This is the "Japanese MNIST": it classifies your strokes
  into kana. It recognizes the entire syllabary, so no custom training needed.
- Reading is shown as romaji and spoken in Japanese (`flutter_tts`).

## Features

Three tabs (bottom navigation): **practice / study / settings**. The whole UI is
localized — **English (default) / 中文 / 한국어**, switchable live in settings.
Layout is responsive (scales from a foldable cover screen up to a tablet; no
hardcoded heights).

- **practice** — a romaji prompt; write the glyph, `check`, `next`.
  - **Write timer** — a countdown bar per glyph. Default **5s**, configurable
    (off / 3 / 5 / 10 / 15). When it runs out, **the current pad state is graded**
    automatically (an empty pad counts as a miss).
  - Result shows a **✅ / ❌** prefix.
  - **Mute** button to silence the readings.
  - On launch it checks whether the **Japanese TTS voice** is installed; if not, a
    banner offers to open the system installer (Android).
  - **Adaptive sampling** — each glyph carries a mastery level **1–5** (correct
    `+1`, miss `−1`, clamped). The quiz samples by weight `6 − level`, so weak
    glyphs (level 1) appear ~5× as often as mastered ones (level 5 — still shown,
    just rarely).
- **study** — every glyph in gojūon (aiueo) order with its mastery dots, split
  into **ひらがな / カタカナ** sub-tabs. **Tap a card** for a detail sheet (glyph +
  example word + picture + mastery).
- **settings**
  - **Language** — English / 中文 / 한국어.
  - **Dark / light** theme.
  - **Script mode** — ひらがな only / カタカナ only / both (random).
  - **Write timer** seconds.
  - **Word mode toggle** — off: just the kana is read. On: show a cartoon
    **emoji** + the word's meaning and read *"word の kana"* (e.g. あ → 🌧️ "rain",
    spoken "あめ の あ"). To avoid giving the answer away, the kana spelling of the
    word stays hidden until after you answer. Hiragana uses native words;
    katakana uses loanwords.

## Code map (everything is in `lib/`)

| file | role |
|------|------|
| `main.dart` | app entry; wires the theme to settings |
| `home.dart` | bottom-nav shell (practice / study / settings) |
| `theme.dart` | light & dark themes |
| `l10n.dart` | hand-rolled localization (en / zh / ko) |
| `settings.dart` | persisted prefs: language, theme, script mode, timer, word mode |
| `store.dart` | score + per-glyph mastery level (1–5) |
| `kana.dart` | the 46+46 gojūon table |
| `kana_words.dart` | example word + emoji + 3-language gloss per kana |
| `recognizer.dart` | ML Kit digital-ink wrapper |
| `draw_canvas.dart` | writing pad |
| `quiz_page.dart` | practice loop: timer, sampling, word mode, the 100-screen |
| `settings_page.dart` | the settings tab |
| `progress_page.dart` | the study tab + glyph detail |

## Run it

This repo ships only the Dart sources. Generate the native projects once:

```bash
cd suisui-kana
flutter create .          # scaffolds android/ and ios/ around the existing lib/
flutter pub get
flutter run               # with an Android/iOS device or emulator attached
```

`flutter create .` keeps `lib/` and `pubspec.yaml`; it only fills in the
platform folders. The default `applicationId` becomes `com.example.suisui_kana`.

### Native notes

- **Android** — needs the internet permission for the first model download. Add
  to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```
- **iOS** — ML Kit needs iOS 15.5+. In `ios/Podfile` set
  `platform :ios, '15.5'`.
