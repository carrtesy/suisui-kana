import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'l10n.dart';
import 'settings.dart';

/// First-launch onboarding, shown once. Three swipeable slides, each with a
/// small looping demo of what the app does:
///   1. write a kana on the pad,
///   2. tap a study card to track progress,
///   3. keep going until every kana is mastered.
class IntroPage extends StatefulWidget {
  const IntroPage({super.key, required this.settings, required this.onDone});
  final Settings settings;
  final VoidCallback onDone;

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(int last) {
    if (_page >= last) {
      widget.onDone();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.settings.lang);
    final scheme = Theme.of(context).colorScheme;
    final slides = <Widget>[
      _Slide(demo: const _WriteDemo(), title: l.introWriteTitle, body: l.introWriteBody),
      _Slide(demo: const _StudyDemo(), title: l.introStudyTitle, body: l.introStudyBody),
      _Slide(demo: const _FinishDemo(), title: l.introFinishTitle, body: l.introFinishBody),
    ];
    final last = slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _page == last ? null : widget.onDone,
                child: Opacity(
                    opacity: _page == last ? 0 : 1, child: Text(l.introSkip)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: slides,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
              child: FilledButton(
                onPressed: () => _next(last),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56)),
                child: Text(_page == last ? l.getStarted : l.introNext),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.demo, required this.title, required this.body});
  final Widget demo;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            width: 240,
            height: 240,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: demo,
            ),
          ),
          const Spacer(),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.5, color: theme.hintColor),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ── slide 1: a pen writing し stroke by stroke ─────────────────────────────
class _WriteDemo extends StatefulWidget {
  const _WriteDemo();
  @override
  State<_WriteDemo> createState() => _WriteDemoState();
}

class _WriteDemoState extends State<_WriteDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        painter: _StrokePainter(
          // hold at the end for the back third of the loop before repeating
          progress: (_c.value / 0.7).clamp(0.0, 1.0),
          color: scheme.primary,
          guide: scheme.onSurface.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({
    required this.progress,
    required this.color,
    required this.guide,
  });
  final double progress;
  final Color color;
  final Color guide;

  // The real す glyph outline, from KanjiVG (109×109 box), stroke 1 then 2:
  // the short top bar, then the long vertical that loops at the bottom.
  static const _stroke1 =
      'M15.5,37.12c2.88,2.12,6.94,1.51,12.75,0.25c16.12-3.5,36.14-5.38,46.62-6.5c7-0.75,11.88-0.62,17.75,0.12';
  static const _stroke2 =
      'M57.62,13.38c2,1.5,2.75,3.25,2.75,5.88c0,10.38,0,35.12,0,40.75c0,14.62-15.62,16.38-15.62,1.75c0-14.25,18-14.12,18,6.38c0,13.25-7.75,21.5-16,28.38';

  // Build the two-stroke す, scaled uniformly and centred into [size].
  Path _su(Size size) {
    final raw = Path();
    _appendSvg(raw, _stroke1);
    _appendSvg(raw, _stroke2);
    final b = raw.getBounds();
    final pad = size.width * 0.14;
    final scale = (size.width - pad * 2) / b.longestSide;
    final dx = (size.width - b.width * scale) / 2 - b.left * scale;
    final dy = (size.height - b.height * scale) / 2 - b.top * scale;
    return raw.transform(Float64List.fromList([
      scale, 0, 0, 0, //
      0, scale, 0, 0, //
      0, 0, 1, 0, //
      dx, dy, 0, 1, //
    ]));
  }

  // Minimal SVG path parser — handles M/m, C/c, L/l (all KanjiVG kana use).
  void _appendSvg(Path path, String d) {
    final tokens = RegExp(r'[MmCcLlZz]|-?\d*\.?\d+')
        .allMatches(d)
        .map((e) => e.group(0)!)
        .toList();
    double cx = 0, cy = 0;
    var i = 0;
    var cmd = '';
    double nx() => double.parse(tokens[i++]);
    while (i < tokens.length) {
      if (RegExp(r'[A-Za-z]').hasMatch(tokens[i])) cmd = tokens[i++];
      switch (cmd) {
        case 'M':
        case 'm':
          var x = nx(), y = nx();
          if (cmd == 'm') {
            x += cx;
            y += cy;
          }
          path.moveTo(x, y);
          cx = x;
          cy = y;
          cmd = cmd == 'M' ? 'L' : 'l';
          break;
        case 'C':
        case 'c':
          var x1 = nx(), y1 = nx(), x2 = nx(), y2 = nx(), x = nx(), y = nx();
          if (cmd == 'c') {
            x1 += cx;
            y1 += cy;
            x2 += cx;
            y2 += cy;
            x += cx;
            y += cy;
          }
          path.cubicTo(x1, y1, x2, y2, x, y);
          cx = x;
          cy = y;
          break;
        case 'L':
        case 'l':
          var x = nx(), y = nx();
          if (cmd == 'l') {
            x += cx;
            y += cy;
          }
          path.lineTo(x, y);
          cx = x;
          cy = y;
          break;
        default:
          i++; // skip anything unsupported
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 240;
    final path = _su(size);

    final guidePaint = Paint()
      ..color = guide
      ..strokeWidth = 15 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final penPaint = Paint()
      ..color = color
      ..strokeWidth = 11 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // The grey reference glyph — the full shape the pen traces over.
    canvas.drawPath(path, guidePaint);

    // Ink along the same path, spanning both strokes in order.
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    var remaining = total * progress;
    final drawn = Path();
    Offset? head;
    for (final m in metrics) {
      if (remaining <= 0) break;
      final take = remaining >= m.length ? m.length : remaining;
      drawn.addPath(m.extractPath(0, take), Offset.zero);
      if (take < m.length) head = m.getTangentForOffset(take)?.position;
      remaining -= take;
    }
    canvas.drawPath(drawn, penPaint);

    // Pen tip riding the head of the active stroke.
    if (head != null) canvas.drawCircle(head, 9 * s, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StrokePainter old) =>
      old.progress != progress || old.color != color || old.guide != guide;
}

// ── slide 2: a tap landing on a study card ─────────────────────────────────
class _StudyDemo extends StatefulWidget {
  const _StudyDemo();
  @override
  State<_StudyDemo> createState() => _StudyDemoState();
}

class _StudyDemoState extends State<_StudyDemo>
    with SingleTickerProviderStateMixin {
  static const _cells = ['あ', 'い', 'う', 'か', 'き', 'く'];
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        // one card is "active" per loop; the tap pulses over it.
        final active = (_c.value * _cells.length).floor() % _cells.length;
        final local = (_c.value * _cells.length) % 1.0; // 0..1 within a cell
        final pulse = (1 - (local * 2 - 1).abs()).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (var i = 0; i < _cells.length; i++)
                _MiniCard(
                  glyph: _cells[i],
                  filled: i <= active ? 5 : 1,
                  active: i == active,
                  pulse: i == active ? pulse : 0,
                  scheme: scheme,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.glyph,
    required this.filled,
    required this.active,
    required this.pulse,
    required this.scheme,
  });
  final String glyph;
  final int filled;
  final bool active;
  final double pulse;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + pulse * 0.08,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(
            color: active
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.3),
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(glyph, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var d = 0; d < 3; d++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d < (filled / 2).ceil()
                          ? Colors.green
                          : scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── slide 3: master both scripts ──────────────────────────────────────────
class _FinishDemo extends StatefulWidget {
  const _FinishDemo();
  @override
  State<_FinishDemo> createState() => _FinishDemoState();
}

class _FinishDemoState extends State<_FinishDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1 + _c.value * 0.12,
            child: const Text('🏆', style: TextStyle(fontSize: 72)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('あ',
                  style: TextStyle(fontSize: 46, color: scheme.primary)),
              const SizedBox(width: 20),
              Text('ア',
                  style: TextStyle(fontSize: 46, color: scheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
