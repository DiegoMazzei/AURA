import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original code-native brand mark; also rasterized for the native launch icons.
class AuraMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(.1, -.35),
          radius: 1.3,
          colors: [Color(0xff233d6c), Color(0xff0b142a), Color(0xff050a17)],
        ).createShader(rect),
    );
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6);
    final ring = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * .48,
      height: size.height * .64,
    );
    for (var i = 3; i >= 0; i--) {
      canvas.drawOval(
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * (.055 + i * .018)
          ..color = const Color(0xff9c9dff)
              .withValues(alpha: i == 0 ? .8 : .06),
      );
    }
    canvas.drawOval(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .035
        ..shader = const SweepGradient(
          colors: [
            Color(0xff9bbdff),
            Color(0xffe8b9ed),
            Color(0xff8967f4),
            Color(0xff63b1ff),
            Color(0xff9bbdff),
          ],
        ).createShader(ring),
    );
    canvas.rotate(math.pi / 3);
    canvas.drawOval(
      ring.deflate(size.width * .04),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * .018
        ..shader = const SweepGradient(
          colors: [
            Color(0xffd0e8ff),
            Color(0xffacb6ff),
            Color(0xfff9c6e9),
            Color(0xffd0e8ff),
          ],
        ).createShader(ring),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(AuraMarkPainter oldDelegate) => false;
}
