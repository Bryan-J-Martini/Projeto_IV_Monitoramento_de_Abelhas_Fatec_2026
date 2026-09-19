import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Plano de fundo único usado pela tela inicial e pelas telas internas.
class HoneycombBackground extends StatelessWidget {
  const HoneycombBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE06A), Color(0xFFFF9700)],
        ),
      ),
      child: CustomPaint(painter: _BottomHoneycombPainter()),
    );
  }
}

class _BottomHoneycombPainter extends CustomPainter {
  const _BottomHoneycombPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const honeycombHeight = 300.0;
    final top = size.height - honeycombHeight;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Color.fromARGB(255, 255, 236, 161).withOpacity(0.34),
          Color.fromARGB(255, 255, 236, 161).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, top, size.width, honeycombHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    const radius = 18.0;
    const horizontal = 31.0;
    const vertical = 27.0;
    for (double y = top; y < size.height + radius; y += vertical) {
      final shift = ((y / vertical).round().isOdd) ? horizontal / 2 : 0.0;
      for (double x = -radius; x < size.width + radius; x += horizontal) {
        final center = Offset(x + shift, y);
        final path = Path();
        for (var side = 0; side < 6; side++) {
          final angle = (60 * side - 30) * math.pi / 180;
          final point = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );
          if (side == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        canvas.drawPath(path..close(), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BottomHoneycombPainter oldDelegate) => false;
}
