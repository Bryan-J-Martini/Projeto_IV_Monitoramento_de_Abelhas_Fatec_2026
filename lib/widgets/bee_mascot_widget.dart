import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum BeeMood {
  happy, // 26°C a 32°C (Ideal)
  cold, // < 26°C (Alerta frio)
  hot, // > 32°C (Alerta calor)
}

class BeeMascotWidget extends StatefulWidget {
  final double size;
  final double internalTemp;
  final bool showSpeechBubble;
  final String? customMessage;
  final VoidCallback? onTap;

  const BeeMascotWidget({
    super.key,
    this.size = 80.0,
    required this.internalTemp,
    this.showSpeechBubble = false,
    this.customMessage,
    this.onTap,
  });

  @override
  State<BeeMascotWidget> createState() => _BeeMascotWidgetState();
}

class _BeeMascotWidgetState extends State<BeeMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isBubbleVisible = false;

  BeeMood get mood {
    if (widget.internalTemp >= 26.0 && widget.internalTemp <= 32.0) {
      return BeeMood.happy;
    } else if (widget.internalTemp < 26.0) {
      return BeeMood.cold;
    } else {
      return BeeMood.hot;
    }
  }

  String get defaultSpeechMessage {
    switch (mood) {
      case BeeMood.happy:
        return 'Bzz! Enxame feliz! Temperatura ideal de ${widget.internalTemp.toStringAsFixed(1)}°C.';
      case BeeMood.cold:
        return 'Brrr! Estamos com frio (${widget.internalTemp.toStringAsFixed(1)}°C). Proteja a caixa do vento!';
      case BeeMood.hot:
        return 'Uff! Muito calor (${widget.internalTemp.toStringAsFixed(1)}°C)! Verifique o sombreamento!';
    }
  }

  @override
  void initState() {
    super.initState();
    _isBubbleVisible = widget.showSpeechBubble;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BeeMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSpeechBubble != widget.showSpeechBubble) {
      setState(() {
        _isBubbleVisible = widget.showSpeechBubble;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.size / 100.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          _isBubbleVisible = !_isBubbleVisible;
        });
        widget.onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBubbleVisible) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _getMoodBorderColor(),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getMoodEmoji(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.customMessage ?? defaultSpeechMessage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getMoodTextColor(),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Bater de asas e flutuação suave
              final wingAngle = math.sin(_controller.value * math.pi) * 0.45;
              final floatOffset = math.cos(_controller.value * math.pi) * 3.0;

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                    painter: _BeePainter(
                      mood: mood,
                      wingAngle: wingAngle,
                      scale: scale,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getMoodBorderColor() {
    switch (mood) {
      case BeeMood.happy:
        return AppColors.healthIdeal.withOpacity(0.5);
      case BeeMood.cold:
        return AppColors.lakeBlue.withOpacity(0.5);
      case BeeMood.hot:
        return AppColors.healthCritical.withOpacity(0.5);
    }
  }

  Color _getMoodTextColor() {
    switch (mood) {
      case BeeMood.happy:
        return const Color(0xFF0F766E);
      case BeeMood.cold:
        return AppColors.mfpBlue;
      case BeeMood.hot:
        return AppColors.healthCritical;
    }
  }

  String _getMoodEmoji() {
    switch (mood) {
      case BeeMood.happy:
        return '🐝';
      case BeeMood.cold:
        return '❄️';
      case BeeMood.hot:
        return '☀️';
    }
  }
}

class _BeePainter extends CustomPainter {
  final BeeMood mood;
  final double wingAngle;
  final double scale;

  _BeePainter({
    required this.mood,
    required this.wingAngle,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    final center = Offset(50, 50);

    // 1. Asas (desenhadas atrás do corpo)
    _drawWings(canvas, center);

    // 2. Ferrão atrofiado característico das Abelhas Sem Ferrão (Meliponíneos)
    final stingerPaint = Paint()..color = const Color(0xFF422006);
    final stingerPath = Path()
      ..moveTo(22, 50)
      ..lineTo(14, 48)
      ..lineTo(22, 52)
      ..close();
    canvas.drawPath(stingerPath, stingerPaint);

    // 3. Corpo redondo e amigável da abelha
    final bodyRect = Rect.fromCenter(center: center, width: 48, height: 40);
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          mood == BeeMood.cold
              ? const Color(0xFFFDE68A)
              : const Color(0xFFFBBF24),
          mood == BeeMood.hot
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEAB308),
        ],
      ).createShader(bodyRect);
    canvas.drawOval(bodyRect, bodyPaint);

    // 4. Listras pretas no estilo Melipona / Jataí
    final stripePaint = Paint()
      ..color = const Color(0xFF292524)
      ..style = PaintingStyle.fill;

    // Listra 1
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(bodyRect, const Radius.circular(20)));
    canvas.drawRect(const Rect.fromLTWH(34, 30, 7, 40), stripePaint);
    canvas.drawRect(const Rect.fromLTWH(47, 30, 7, 40), stripePaint);
    canvas.restore();

    // 5. Olhinhos simpáticos & expressivos
    _drawEyes(canvas);

    // 6. Boquinha e bochechas
    _drawFace(canvas);

    // 7. Anteninhas simpáticas no topo
    _drawAntennae(canvas);

    canvas.restore();
  }

  void _drawWings(Canvas canvas, Offset center) {
    final wingPaint = Paint()
      ..color = const Color(0xCCBAE6FD)
      ..style = PaintingStyle.fill;
    final wingBorder = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // Asa esquerda
    canvas.save();
    canvas.translate(42, 34);
    canvas.rotate(-0.35 + wingAngle);
    final leftWing = Rect.fromCenter(center: const Offset(0, -18), width: 22, height: 32);
    canvas.drawOval(leftWing, wingPaint);
    canvas.drawOval(leftWing, wingBorder);
    canvas.restore();

    // Asa direita
    canvas.save();
    canvas.translate(58, 34);
    canvas.rotate(0.35 - wingAngle);
    final rightWing = Rect.fromCenter(center: const Offset(0, -18), width: 22, height: 32);
    canvas.drawOval(rightWing, wingPaint);
    canvas.drawOval(rightWing, wingBorder);
    canvas.restore();
  }

  void _drawEyes(Canvas canvas) {
    final eyePaint = Paint()..color = const Color(0xFF1E293B);
    final pupilPaint = Paint()..color = Colors.white;

    if (mood == BeeMood.happy) {
      // Olho esquerdo
      canvas.drawCircle(const Offset(58, 46), 4.2, eyePaint);
      canvas.drawCircle(const Offset(59.5, 44.5), 1.5, pupilPaint);

      // Olho direito
      canvas.drawCircle(const Offset(68, 46), 4.2, eyePaint);
      canvas.drawCircle(const Offset(69.5, 44.5), 1.5, pupilPaint);
    } else if (mood == BeeMood.cold) {
      // Olhinhos tremendo / semi-fechados
      final eyePathLeft = Path()
        ..moveTo(55, 47)
        ..quadraticBezierTo(58, 43, 61, 47);
      final eyePathRight = Path()
        ..moveTo(65, 47)
        ..quadraticBezierTo(68, 43, 71, 47);

      final coldEyePaint = Paint()
        ..color = const Color(0xFF1E293B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(eyePathLeft, coldEyePaint);
      canvas.drawPath(eyePathRight, coldEyePaint);
    } else {
      // Olhos grandes de calor/alerta
      canvas.drawCircle(const Offset(58, 45), 5.0, eyePaint);
      canvas.drawCircle(const Offset(59, 44), 2.0, pupilPaint);

      canvas.drawCircle(const Offset(68, 45), 5.0, eyePaint);
      canvas.drawCircle(const Offset(69, 44), 2.0, pupilPaint);

      // Gotinha de suor
      final sweatPaint = Paint()..color = const Color(0xFF38BDF8);
      final sweatPath = Path()
        ..moveTo(74, 38)
        ..quadraticBezierTo(77, 43, 74, 45)
        ..quadraticBezierTo(71, 43, 74, 38);
      canvas.drawPath(sweatPath, sweatPaint);
    }
  }

  void _drawFace(Canvas canvas) {
    // Bochechas rosadas
    final blushPaint = Paint()
      ..color = (mood == BeeMood.hot
              ? const Color(0xFFFB7185)
              : const Color(0xFFFDA4AF))
          .withOpacity(0.7);
    canvas.drawCircle(const Offset(54, 53), 3.2, blushPaint);
    canvas.drawCircle(const Offset(72, 53), 3.2, blushPaint);

    final mouthPaint = Paint()
      ..color = const Color(0xFF451A03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    if (mood == BeeMood.happy) {
      // Sorriso aberto
      final mouthPath = Path()
        ..moveTo(60, 52)
        ..quadraticBezierTo(63, 56, 66, 52);
      canvas.drawPath(mouthPath, mouthPaint);
    } else if (mood == BeeMood.cold) {
      // Boquinha trêmula
      final mouthPath = Path()
        ..moveTo(60, 54)
        ..lineTo(62, 52)
        ..lineTo(64, 54)
        ..lineTo(66, 52);
      canvas.drawPath(mouthPath, mouthPaint);
    } else {
      // Boquinha em 'o' de calor
      final mouthPaintHot = Paint()
        ..color = const Color(0xFF451A03)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        const Rect.fromLTWH(61, 52, 5, 6),
        mouthPaintHot,
      );
    }
  }

  void _drawAntennae(Canvas canvas) {
    final antPaint = Paint()
      ..color = const Color(0xFF292524)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final tipPaint = Paint()
      ..color = const Color(0xFF292524)
      ..style = PaintingStyle.fill;

    // Antena esquerda
    final antLeft = Path()
      ..moveTo(60, 32)
      ..quadraticBezierTo(58, 22, 52, 20);
    canvas.drawPath(antLeft, antPaint);
    canvas.drawCircle(const Offset(52, 20), 2.2, tipPaint);

    // Antena direita
    final antRight = Path()
      ..moveTo(66, 32)
      ..quadraticBezierTo(70, 22, 74, 20);
    canvas.drawPath(antRight, antPaint);
    canvas.drawCircle(const Offset(74, 20), 2.2, tipPaint);
  }

  @override
  bool shouldRepaint(covariant _BeePainter oldDelegate) {
    return oldDelegate.wingAngle != wingAngle || oldDelegate.mood != mood;
  }
}

