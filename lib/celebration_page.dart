import 'dart:math';

import 'package:flutter/material.dart';

import 'l10n.dart';
import 'settings.dart';

/// Shown once the learner has mastered every glyph in their practice set:
/// looping fireworks behind a heartfelt thank-you.
class CelebrationPage extends StatefulWidget {
  const CelebrationPage({super.key, required this.settings});
  final Settings settings;

  @override
  State<CelebrationPage> createState() => _CelebrationPageState();
}

class _CelebrationPageState extends State<CelebrationPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  late final List<_Burst> _bursts = _makeBursts();

  List<_Burst> _makeBursts() {
    final rng = Random(7);
    const palette = [
      Color(0xFFFFC857),
      Color(0xFFFF6B6B),
      Color(0xFF4ECDC4),
      Color(0xFFF9F871),
      Color(0xFFA06CD5),
      Color(0xFF6FCF97),
    ];
    return [
      for (var i = 0; i < 9; i++)
        _Burst(
          center: Offset(0.12 + rng.nextDouble() * 0.76,
              0.12 + rng.nextDouble() * 0.5),
          start: rng.nextDouble(),
          color: palette[rng.nextInt(palette.length)],
          seed: rng.nextInt(1 << 30),
        ),
    ];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.settings.lang);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) =>
                  CustomPaint(painter: _FireworksPainter(_bursts, _c.value)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    l.celebrateTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.celebrateBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 18, height: 1.5),
                  ),
                  const SizedBox(height: 44),
                  FilledButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(220, 56),
                    ),
                    child: Text(l.done),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One firework: a burst of particles radiating from [center] (fractional
/// screen coords), beginning at [start] within the looping timeline.
class _Burst {
  _Burst({
    required this.center,
    required this.start,
    required this.color,
    required this.seed,
  });
  final Offset center;
  final double start;
  final Color color;
  final int seed;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.bursts, this.t);
  final List<_Burst> bursts;
  final double t; // 0..1 loop

  @override
  void paint(Canvas canvas, Size size) {
    const particles = 28;
    for (final b in bursts) {
      // Each burst lives for ~40% of the loop, then repeats.
      var local = (t - b.start) % 1.0;
      if (local < 0) local += 1.0;
      if (local > 0.4) continue;
      final p = local / 0.4; // 0..1 within this burst's life
      final origin = Offset(b.center.dx * size.width, b.center.dy * size.height);
      final reach = size.shortestSide * 0.28 * Curves.easeOut.transform(p);
      final rng = Random(b.seed);
      final paint = Paint()
        ..color = b.color.withValues(alpha: (1 - p).clamp(0.0, 1.0))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < particles; i++) {
        final a = (i / particles) * 2 * pi + rng.nextDouble() * 0.2;
        final jitter = 0.75 + rng.nextDouble() * 0.25;
        final r = reach * jitter;
        final dir = Offset(cos(a), sin(a));
        final head = origin + dir * r + Offset(0, r * r * 0.006); // slight fall
        final tail = origin + dir * (r * 0.82);
        canvas.drawLine(tail, head, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t;
}
