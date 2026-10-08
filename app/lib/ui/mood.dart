import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Mood 1–5 (Buruk, Kurang, Biasa, Baik, Senang).
String moodLabel(AppLocalizations l, int mood) => switch (mood) {
  1 => l.moodAwful,
  2 => l.moodBad,
  3 => l.moodOkay,
  4 => l.moodGood,
  _ => l.moodGreat,
};

/// Wajah mood seperti ikon di desain: lingkaran, dua mata, mulut
/// yang melengkung sesuai nilai mood.
class MoodFace extends StatelessWidget {
  const MoodFace({
    super.key,
    required this.mood,
    required this.color,
    this.size = 24,
    this.strokeWidth = 1.7,
  });

  final int mood;
  final Color color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MoodPainter(mood, color, strokeWidth),
    );
  }
}

class _MoodPainter extends CustomPainter {
  _MoodPainter(this.mood, this.color, this.strokeWidth);

  final int mood;
  final Color color;
  final double strokeWidth;

  // Titik mulut (awal, kontrol, akhir) dalam kotak 24×24, dari desain.
  static const _mouths = {
    1: [Offset(8, 17), Offset(12, 13), Offset(16, 17)],
    2: [Offset(8.5, 16), Offset(12, 14), Offset(15.5, 16)],
    3: [Offset(8.5, 15.5), Offset(12, 15.5), Offset(15.5, 15.5)],
    4: [Offset(8.5, 14.5), Offset(12, 17), Offset(15.5, 14.5)],
    5: [Offset(8, 14), Offset(12, 19), Offset(16, 14)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;

    canvas.drawCircle(const Offset(12, 12), 9, stroke);
    canvas.drawCircle(const Offset(9, 10), 1.1, fill);
    canvas.drawCircle(const Offset(15, 10), 1.1, fill);

    final m = _mouths[mood.clamp(1, 5)]!;
    final mouth = Path()
      ..moveTo(m[0].dx, m[0].dy)
      ..quadraticBezierTo(m[1].dx, m[1].dy, m[2].dx, m[2].dy);
    canvas.drawPath(mouth, stroke);
  }

  @override
  bool shouldRepaint(_MoodPainter old) =>
      old.mood != mood || old.color != color || old.strokeWidth != strokeWidth;
}
