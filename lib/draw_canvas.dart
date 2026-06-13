import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// A square writing pad. Captures strokes as polylines and paints them.
class DrawCanvas extends StatefulWidget {
  const DrawCanvas({super.key, required this.controller});
  final DrawController controller;

  @override
  State<DrawCanvas> createState() => _DrawCanvasState();
}

class DrawController extends ChangeNotifier {
  final List<List<Offset>> strokes = [];
  bool get isEmpty => strokes.every((s) => s.isEmpty);

  void clear() {
    strokes.clear();
    notifyListeners();
  }
}

class _DrawCanvasState extends State<DrawCanvas> {
  DrawController get c => widget.controller;

  void _start(Offset p) => setState(() => c.strokes.add([p]));
  void _move(Offset p) => setState(() => c.strokes.last.add(p));

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onPanStart: (d) => _start(d.localPosition),
        onPanUpdate: (d) => _move(d.localPosition),
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) => CustomPaint(
            painter: _Painter(c.strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF6F6F4);
    canvas.drawRect(Offset.zero & size, bg);

    final pen = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final s in strokes) {
      if (s.length < 2) {
        if (s.isNotEmpty) canvas.drawPoints(PointMode.points, s, pen);
        continue;
      }
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(_Painter old) => true;
}
