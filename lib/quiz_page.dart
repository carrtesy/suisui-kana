import 'dart:io';
import 'dart:math';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'draw_canvas.dart';
import 'kana.dart';
import 'kana_words.dart';
import 'l10n.dart';
import 'recognizer.dart';
import 'settings.dart';
import 'store.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({
    super.key,
    required this.store,
    required this.settings,
    required this.active,
  });
  final Store store;
  final Settings settings;

  /// True only while the practice tab is on top — pauses the timer otherwise.
  final bool active;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

enum _Result { none, right, wrong }

class _QuizPageState extends State<QuizPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _canvas = DrawController();
  final _recognizer = Recognizer();
  final _tts = FlutterTts();
  final _rng = Random();

  late final AnimationController _timer = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _onTimeout();
    });

  bool _ready = false;
  bool _checking = false;
  bool _jaMissing = false; // Japanese TTS voice not installed
  late Kana _target;
  _Result _result = _Result.none;
  late ScriptMode _script;

  Store get _store => widget.store;
  Settings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _script = _settings.scriptMode;
    _boot();
  }

  Future<void> _boot() async {
    await _setupTts();
    await _checkJaVoice();
    await _recognizer.ensureModel();
    if (!mounted) return;
    setState(() => _ready = true);
    _next();
  }

  /// Configure TTS for the most natural Japanese the device can offer.
  Future<void> _setupTts() async {
    // Prefer Google's engine — its Japanese voices beat most vendor defaults.
    try {
      final engines = (await _tts.getEngines as List).cast<String>();
      if (engines.contains('com.google.android.tts')) {
        await _tts.setEngine('com.google.android.tts');
      }
    } catch (_) {/* keep current engine */}

    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);

    // Pick the highest-quality Japanese voice on offer (enhanced/network first).
    try {
      final voices = (await _tts.getVoices as List).cast<Map>();
      final ja = voices
          .where((v) =>
              '${v['locale']}'.toLowerCase().startsWith('ja'))
          .toList();
      if (ja.isNotEmpty) {
        final best = ja.firstWhere(
          (v) {
            final n = '${v['name']}'.toLowerCase();
            return n.contains('network') ||
                n.contains('wavenet') ||
                n.contains('neural') ||
                n.contains('enhanced');
          },
          orElse: () => ja.first,
        );
        await _tts.setVoice(
            {'name': '${best['name']}', 'locale': '${best['locale']}'});
      }
    } catch (_) {/* fall back to default voice */}
  }

  // Re-check the voice when returning from the system TTS-data installer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkJaVoice();
  }

  /// Flags whether the Japanese voice is available; surfaces an install banner.
  Future<void> _checkJaVoice() async {
    bool ok;
    try {
      final v = await _tts.isLanguageAvailable('ja-JP');
      ok = v == true || v == 1;
    } catch (_) {
      ok = true; // don't nag if the check itself fails
    }
    if (mounted && ok == _jaMissing) setState(() => _jaMissing = !ok);
  }

  // Launch the Android system installer for TTS voice data.
  Future<void> _installJaVoice() async {
    if (!Platform.isAndroid) return;
    try {
      await const AndroidIntent(
        action: 'android.speech.tts.engine.INSTALL_TTS_DATA',
      ).launch();
    } catch (_) {/* no installer available */}
  }

  void _toggleMute() {
    _settings.muted = !_settings.muted;
    if (_settings.muted) _tts.stop();
  }

  @override
  void didUpdateWidget(QuizPage old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    // Script mode changed in settings → draw from the new pool.
    if (_settings.scriptMode != _script) {
      _script = _settings.scriptMode;
      _next();
      return;
    }
    // Tab visibility changed → pause/resume the running timer.
    if (old.active != widget.active) {
      if (!widget.active) {
        _timer.stop();
        _tts.stop();
      } else if (_result == _Result.none && _settings.timerSeconds > 0) {
        _timer.forward();
      }
    }
  }

  // Pool the question is drawn from, filtered by the script mode.
  List<Kana> get _pool {
    switch (_settings.scriptMode) {
      case ScriptMode.hiragana:
        return allKana.where((k) => k.hiragana).toList();
      case ScriptMode.katakana:
        return allKana.where((k) => !k.hiragana).toList();
      case ScriptMode.both:
        return allKana;
    }
  }

  // Weighted pick: weight = 6 - level, so level 1 → 5×, level 5 → 1× (rare but
  // never zero).
  Kana _pick() {
    final pool = _pool;
    final weights = [
      for (final k in pool) (Store.maxLevel + 1) - _store.level(k.glyph),
    ];
    var r = _rng.nextInt(weights.fold(0, (a, b) => a + b));
    for (var i = 0; i < pool.length; i++) {
      r -= weights[i];
      if (r < 0) return pool[i];
    }
    return pool.last;
  }

  KanaWord? _wordFor(Kana k) =>
      (k.hiragana ? hiraganaWords : katakanaWords)[k.romaji];

  void _next() {
    setState(() {
      _target = _pick();
      _result = _Result.none;
      _checking = false;
      _canvas.clear();
    });
    _speak();
    _startTimer();
  }

  void _startTimer() {
    final secs = _settings.timerSeconds;
    if (secs > 0 && widget.active) {
      _timer
        ..duration = Duration(seconds: secs)
        ..forward(from: 0);
    } else {
      _timer.reset();
    }
  }

  void _speak() {
    if (_settings.muted) return;
    _tts.speak(_speechText());
  }

  String _speechText() {
    final w = _wordFor(_target);
    // ん is a moraic nasal (撥音); TTS reads a lone ん as the letter "n", so
    // voice it through its example word where the nasal sounds natural.
    // ん / を: always read just the bare character, even in word mode.
    if (_target.romaji == 'n' || _target.romaji == 'wo') return _target.glyph;
    if (_settings.wordMode && w != null) {
      // Read "word の" together, then 、 pauses before the kana.
      return '${w.word} の、 ${_target.glyph}';
    }
    return _target.glyph;
  }

  // Timer ran out: grade whatever is on the pad right now (empty → miss).
  void _onTimeout() => _evaluate();

  // Check button: ignore an empty pad so a stray tap doesn't fail the round.
  Future<void> _check() async {
    if (_canvas.isEmpty) return;
    await _evaluate();
  }

  Future<void> _evaluate() async {
    if (_checking || _result != _Result.none) return;
    _timer.stop();
    setState(() => _checking = true);

    final correct = !_canvas.isEmpty &&
        (await _recognizer.classify(_canvas.strokes))
            .take(3)
            .contains(_target.glyph);

    if (correct) {
      await _store.recordCorrect(_target.glyph);
      final score = _store.score + 1;
      await _store.setScore(score);
      if (score >= Store.goal && mounted) {
        _graduate();
        return;
      }
    } else {
      await _store.recordWrong(_target.glyph);
    }
    if (!mounted) return;
    setState(() {
      _result = correct ? _Result.right : _Result.wrong;
      _checking = false;
    });
  }

  void _graduate() async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => const _GoodbyePage(), fullscreenDialog: true),
    );
    _next();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.dispose();
    _recognizer.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    final theme = Theme.of(context);
    final l = L10n(_settings.lang);
    final word = _wordFor(_target);
    // ん / を have no real example word — keep them character-only everywhere.
    final isSpecial = _target.romaji == 'n' || _target.romaji == 'wo';
    final showWord = _settings.wordMode && word != null && !isSpecial;
    final revealed = _result != _Result.none;
    // Kana-only mode: once answered, reveal the glyph in place of the romaji.
    final showGlyph = revealed && !showWord;

    // Everything scales off the available height so it never overflows and
    // adapts from a foldable cover screen up to a tablet.
    return LayoutBuilder(
      builder: (context, box) {
        final h = box.maxHeight;
        final gap = (h * 0.014).clamp(6.0, 16.0);
        final promptSize = (h * 0.085).clamp(34.0, 72.0);
        final emojiSize = (h * 0.06).clamp(28.0, 56.0);
        final wordSize = (h * 0.032).clamp(16.0, 28.0);
        final feedbackSize = (h * 0.034).clamp(18.0, 30.0);
        final btnH = (h * 0.072).clamp(46.0, 60.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: gap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_jaMissing)
                _TtsBanner(l: l, onInstall: _installJaVoice, onDismiss: () {
                  setState(() => _jaMissing = false);
                }),
              Row(
                children: [
                  Expanded(
                    child: _TimerBar(
                        controller: _timer, seconds: _settings.timerSeconds),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: l.sound,
                    icon: Icon(
                      _settings.muted ? Icons.volume_off : Icons.volume_up,
                      size: 22,
                    ),
                    onPressed: () => setState(_toggleMute),
                  ),
                ],
              ),
              SizedBox(height: gap),
              // The reading (what to write). Tap to hear it again.
              GestureDetector(
                onTap: _speak,
                child: Column(
                  children: [
                    Text(
                      showGlyph ? _target.glyph : _target.romaji,
                      style: TextStyle(
                          fontSize: promptSize, fontWeight: FontWeight.w300),
                    ),
                    Text(
                      showGlyph
                          ? '${_target.romaji} ・ ${_target.hiragana ? 'ひらがな' : 'カタカナ'}'
                          : (_target.hiragana
                              ? 'hiragana ・ ひらがな'
                              : 'katakana ・ カタカナ'),
                      style:
                          TextStyle(color: theme.hintColor, letterSpacing: 1),
                    ),
                    if (showWord)
                      _WordHint(
                        word: word,
                        kana: _target.glyph,
                        l: l,
                        reveal: revealed,
                        emojiSize: emojiSize,
                        wordSize: wordSize,
                        gap: gap,
                      ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              // Flexible square pad — shrinks so word mode never overflows.
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: DrawCanvas(controller: _canvas),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: gap),
              _Feedback(
                  result: _result,
                  answer: _target.glyph,
                  l: l,
                  fontSize: feedbackSize),
              SizedBox(height: gap),
              _Actions(
                result: _result,
                checking: _checking,
                height: btnH,
                onClear: () => setState(_canvas.clear),
                onCheck: _check,
                onNext: _next,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Countdown bar; hidden when the timer is off.
class _TimerBar extends StatelessWidget {
  const _TimerBar({required this.controller, required this.seconds});
  final AnimationController controller;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    if (seconds <= 0) return const SizedBox(height: 8);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final remaining = controller.duration == null
            ? seconds
            : (seconds * (1 - controller.value)).ceil();
        final danger = controller.value > 0.75;
        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 1 - controller.value,
                  minHeight: 6,
                  color: danger ? Colors.redAccent : null,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 28,
              child: Text(
                '$remaining',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: danger ? Colors.redAccent : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shown when the Japanese TTS voice isn't installed — offers to install it.
class _TtsBanner extends StatelessWidget {
  const _TtsBanner({
    required this.l,
    required this.onInstall,
    required this.onDismiss,
  });
  final L10n l;
  final VoidCallback onInstall;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_off, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.ttsMissing,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSecondaryContainer),
            ),
          ),
          TextButton(onPressed: onInstall, child: Text(l.install)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// Word mode hint. Before answering it shows only the picture + meaning so the
/// glyph isn't given away; the kana spelling is revealed after the check.
class _WordHint extends StatelessWidget {
  const _WordHint({
    required this.word,
    required this.kana,
    required this.l,
    required this.reveal,
    required this.emojiSize,
    required this.wordSize,
    required this.gap,
  });
  final KanaWord word;
  final String kana;
  final L10n l;
  final bool reveal;
  final double emojiSize;
  final double wordSize;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: gap),
      child: Column(
        children: [
          Text(word.emoji, style: TextStyle(fontSize: emojiSize)),
          SizedBox(height: gap * 0.4),
          Text(
            l.gloss(word),
            style: TextStyle(fontSize: wordSize, fontWeight: FontWeight.w500),
          ),
          // The kana spelling stays hidden until the answer is shown.
          if (reveal)
            Padding(
              padding: EdgeInsets.only(top: gap * 0.3),
              child: Text(
                l.wordOf(word.word, kana),
                style: TextStyle(color: theme.hintColor, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.result,
    required this.answer,
    required this.l,
    required this.fontSize,
  });
  final _Result result;
  final String answer;
  final L10n l;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = switch (result) {
      _Result.none => ' ',
      _Result.right => '✅ ${l.correct}',
      _Result.wrong => '❌ ${l.answer}: $answer',
    };
    final color = switch (result) {
      _Result.right => Colors.green,
      _Result.wrong => Colors.red,
      _Result.none => Colors.transparent,
    };
    return Text(
      text,
      textAlign: TextAlign.center,
      style:
          TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w500),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.result,
    required this.checking,
    required this.height,
    required this.onClear,
    required this.onCheck,
    required this.onNext,
  });
  final _Result result;
  final bool checking;
  final double height;
  final VoidCallback onClear;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (result != _Result.none) {
      return FilledButton(
        onPressed: onNext,
        style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
        child: const Text('next'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onClear,
            style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(height)),
            child: const Text('clear'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: checking ? null : onCheck,
            style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
            child: checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('check'),
          ),
        ),
      ],
    );
  }
}

class _GoodbyePage extends StatelessWidget {
  const _GoodbyePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('100',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w200)),
              const SizedBox(height: 16),
              const Text(
                'You know your kana.\nNothing left to teach you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70, fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 48),
              Builder(
                builder: (context) => FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(220, 56),
                  ),
                  child: const Text('keep going'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
