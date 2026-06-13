import 'dart:ui';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

/// Thin wrapper over ML Kit's on-device Japanese digital-ink model.
/// This is our "Japanese MNIST": it classifies the drawn strokes into kana.
class Recognizer {
  static const _lang = 'ja';
  final _manager = DigitalInkRecognizerModelManager();
  final _recognizer = DigitalInkRecognizer(languageCode: _lang);

  /// Download the model once (no-op if already present). Needs network the
  /// first time only; afterwards recognition is fully offline.
  Future<void> ensureModel() async {
    if (!await _manager.isModelDownloaded(_lang)) {
      await _manager.downloadModel(_lang);
    }
  }

  /// Returns the model's best-guess glyphs, most likely first.
  Future<List<String>> classify(List<List<Offset>> strokes) async {
    final ink = Ink();
    var t = 0;
    for (final s in strokes) {
      if (s.isEmpty) continue;
      final stroke = Stroke();
      stroke.points = [
        for (final o in s) StrokePoint(x: o.dx, y: o.dy, t: t += 16),
      ];
      ink.strokes.add(stroke);
    }
    if (ink.strokes.isEmpty) return const [];
    final candidates = await _recognizer.recognize(ink);
    return [for (final c in candidates) c.text];
  }

  void dispose() => _recognizer.close();
}
