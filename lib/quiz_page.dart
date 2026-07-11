import 'dart:io';
import 'dart:math';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import 'audio.dart';
import 'celebration_page.dart';
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
    required this.voice,
    required this.active,
  });
  final Store store;
  final Settings settings;
  final VoiceService voice;

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
  final _rng = Random();

  VoiceService get _voice => widget.voice;

  late final AnimationController _timer = AnimationController(vsync: this)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _onTimeout();
    });

  bool _ready = false;
  bool _checking = false;
  bool _jaMissing = false; // Japanese TTS voice not installed
  late Kana _target;
  String? _lastGlyph; // avoid drawing the same glyph twice in a row
  _Result _result = _Result.none;
  late ScriptMode _script;
  late bool _extended;

  Store get _store => widget.store;
  Settings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _script = _settings.scriptMode;
    _extended = _settings.includeExtended;
    _boot();
  }

  Future<void> _boot() async {
    await _voice.init();
    await _checkJaVoice();
    await _recognizer.ensureModel();
    if (!mounted) return;
    setState(() => _ready = true);
    _next();
  }

  // Re-check the voice when returning from the system TTS-data installer.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkJaVoice();
  }

  /// Flags whether the Japanese voice is available; surfaces an install banner.
  Future<void> _checkJaVoice() async {
    final ok = await _voice.isJaAvailable();
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
    if (_settings.muted) _voice.stop();
  }

  @override
  void didUpdateWidget(QuizPage old) {
    super.didUpdateWidget(old);
    if (!_ready) return;
    // Practice-set changed in settings → draw from the new pool.
    if (_settings.scriptMode != _script ||
        _settings.includeExtended != _extended) {
      _script = _settings.scriptMode;
      _extended = _settings.includeExtended;
      _next();
      return;
    }
    // Tab visibility changed → pause/resume the running timer.
    if (old.active != widget.active) {
      if (!widget.active) {
        _timer.stop();
        _voice.stop();
      } else if (_result == _Result.none && _settings.timerSeconds > 0) {
        _timer.forward();
      }
    }
  }

  /// The learner's chosen scope, ignoring the hide-mastered filter — this is
  /// what "finish everything" is measured against. Contracted syllables (yōon,
  /// two glyphs in a row) are never quizzed, so only voiced kana are added.
  List<Kana> get _configuredSet {
    final base =
        _settings.includeExtended ? [...allKana, ...voicedKana] : allKana;
    switch (_settings.scriptMode) {
      case ScriptMode.hiragana:
        return base.where((k) => k.hiragana).toList();
      case ScriptMode.katakana:
        return base.where((k) => !k.hiragana).toList();
      case ScriptMode.both:
        return base;
    }
  }

  /// The pool actually sampled: the configured set, minus mastered glyphs when
  /// the user asked to hide them (but never empty — if all are mastered we still
  /// draw from the full set so practice keeps working).
  List<Kana> get _pool {
    final set = _configuredSet;
    if (_settings.hideMastered) {
      final left = set.where((k) => !_store.isMastered(k.glyph)).toList();
      if (left.isNotEmpty) return left;
    }
    return set;
  }

  // Weighted pick: weight = 6 - level, so level 1 → 5×, level 5 → 1× (rare but
  // never zero). Avoids repeating the previous glyph when the pool allows.
  Kana _pick() {
    final pool = _pool;
    if (pool.length <= 1) return pool.first;
    for (var attempt = 0; attempt < 8; attempt++) {
      final k = _weighted(pool);
      if (k.glyph != _lastGlyph) return k;
    }
    return _weighted(pool);
  }

  Kana _weighted(List<Kana> pool) {
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
      _lastGlyph = _target.glyph;
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
    final w = _wordFor(_target);
    final isSpecial = isCharacterOnly(_target.romaji);
    // ん / を: always read just the bare character, even in word mode. In word
    // mode the "word の kana" phrase is composite, so it always goes via TTS;
    // a single glyph can use a recording when the voice pack has one.
    if (_settings.wordMode && w != null && !isSpecial) {
      // Word-mode phrase ("word の kana") has its own saved file per script.
      final key = 'word_${_target.hiragana ? 'h' : 'k'}_${_target.romaji}';
      _voice.speakPhrase(key, '${w.word} の、 ${_target.glyph}',
          useVoicePack: _settings.useVoicePack);
    } else {
      _voice.speakGlyph(_target.romaji, _target.glyph,
          useVoicePack: _settings.useVoicePack);
    }
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

    // Contracted syllables (きゃ) are two shapes in one pad, so accept a deeper
    // slice of the candidate list; basic glyphs stay strict to avoid false hits.
    final depth = _target.kind == KanaKind.yoon ? 10 : 3;
    final correct = !_canvas.isEmpty &&
        (await _recognizer.classify(_canvas.strokes, _canvas.size))
            .take(depth)
            .contains(_target.glyph);

    if (correct) {
      await _store.recordCorrect(_target.glyph);
      await _store.setScore(_store.score + 1);
    } else {
      await _store.recordWrong(_target.glyph);
    }
    if (!mounted) return;
    setState(() {
      _result = correct ? _Result.right : _Result.wrong;
      _checking = false;
    });
    await _maybeCelebrate();
  }

  /// Celebrate only when the entire configured set is mastered — and only once
  /// per completion. Dropping below full mastery re-arms it, so expanding the
  /// scope (e.g. adding katakana) and finishing again celebrates anew.
  Future<void> _maybeCelebrate() async {
    final all = _store.allMastered(_configuredSet);
    if (all && !_store.celebrated) {
      await _store.setCelebrated(true);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CelebrationPage(settings: _settings),
        fullscreenDialog: true,
      ));
    } else if (!all && _store.celebrated) {
      await _store.setCelebrated(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.dispose();
    _recognizer.dispose();
    // _voice is owned by HomeShell (shared with settings); don't dispose here.
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
    final isSpecial = isCharacterOnly(_target.romaji);
    final showWord = _settings.wordMode && word != null && !isSpecial;
    final revealed = _result != _Result.none;
    // Kana-only mode: once answered, reveal the glyph in place of the romaji.
    final showGlyph = revealed && !showWord;
    final scriptLabel = _target.hiragana ? 'ひらがな' : 'カタカナ';

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
                          ? '${_target.romaji} ・ $scriptLabel'
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
    // After grading the pad stays editable so you can wipe it and trace the
    // revealed glyph a few times before moving on.
    if (result != _Result.none) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onClear,
              style:
                  OutlinedButton.styleFrom(minimumSize: Size.fromHeight(height)),
              child: const Text('clear'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(minimumSize: Size.fromHeight(height)),
              child: const Text('next'),
            ),
          ),
        ],
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
