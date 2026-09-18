import 'package:flutter/material.dart';

import '../../../../../models/hive_model.dart';

/// Cartão compacto da tela inicial. O toque mantém a navegação existente;
/// a escala curta dá feedback visual sem deixar a tela estática.
class HiveCard extends StatefulWidget {
  final HiveModel hive;
  final VoidCallback onTap;

  const HiveCard({super.key, required this.hive, required this.onTap});

  @override
  State<HiveCard> createState() => _HiveCardState();
}

class _HiveCardState extends State<HiveCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hive = widget.hive;
    final isOnline = hive.isOnline;
    final statusColor = isOnline
        ? const Color(0xFF00B979)
        : const Color(0xFFFF3E51);

    return Hero(
      tag: 'hive_card_${hive.id}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B6500).withOpacity(0.15),
                    blurRadius: 7,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ConnectionLabel(isOnline: isOnline, color: statusColor),
                    const SizedBox(height: 3),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA619),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          hive.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.92, end: 1),
                          duration: const Duration(milliseconds: 850),
                          curve: Curves.easeOutBack,
                          builder: (context, value, child) =>
                              Transform.scale(scale: value, child: child),
                          child: const SizedBox(
                            width: 78,
                            height: 69,
                            child: CustomPaint(
                              painter: _HiveIllustrationPainter(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'informações',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF8D8D8D),
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        _ChevronTrail(color: const Color(0xFFFF9F17)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionLabel extends StatefulWidget {
  final bool isOnline;
  final Color color;

  const _ConnectionLabel({required this.isOnline, required this.color});

  @override
  State<_ConnectionLabel> createState() => _ConnectionLabelState();
}

class _ConnectionLabelState extends State<_ConnectionLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isOnline) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _ConnectionLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && !oldWidget.isOnline) {
      _controller.repeat();
    } else if (!widget.isOnline && oldWidget.isOnline) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity = widget.isOnline
                ? 0.45 + _controller.value * 0.55
                : 1.0;
            return Icon(
              widget.isOnline ? Icons.wifi : Icons.wifi_off,
              size: 12,
              color: widget.color.withOpacity(opacity),
            );
          },
        ),
        const SizedBox(width: 3),
        Text(
          widget.isOnline ? 'Conectada' : 'Desconectado',
          style: TextStyle(
            color: widget.color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChevronTrail extends StatelessWidget {
  final Color color;

  const _ChevronTrail({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(left: 1),
          child: Icon(Icons.chevron_right, size: 17, color: color),
        ),
      ),
    );
  }
}

class _HiveIllustrationPainter extends CustomPainter {
  const _HiveIllustrationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final top = 7.0;
    final body = Paint()..color = const Color(0xFFE87D08);
    final lightBody = Paint()..color = const Color(0xFFF28B0E);
    final dark = Paint()..color = const Color(0xFFBC5800);
    final line = Paint()
      ..color = const Color(0xFFC86600)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(x - 25, top + 8, 50, 6), dark);
    canvas.drawRect(Rect.fromLTWH(x - 29, top + 2, 58, 6), body);
    canvas.drawRect(Rect.fromLTWH(x - 21, top + 14, 42, 43), lightBody);
    canvas.drawRect(Rect.fromLTWH(x - 24, top + 17, 48, 3), dark);
    canvas.drawRect(Rect.fromLTWH(x - 24, top + 39, 48, 3), dark);
    canvas.drawRect(Rect.fromLTWH(x - 21, top + 54, 42, 4), dark);
    canvas.drawLine(Offset(x - 16, top + 15), Offset(x - 16, top + 57), line);
    canvas.drawLine(Offset(x + 16, top + 15), Offset(x + 16, top + 57), line);
    canvas.drawCircle(
      Offset(x, top + 35),
      6,
      Paint()..color = const Color(0xFFB65A05),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 10, top + 51), width: 13, height: 6),
      Paint()..color = Colors.white,
    );
    canvas.drawLine(
      Offset(x + 4, top + 51),
      Offset(x + 16, top + 51),
      Paint()
        ..color = const Color(0xFFB65A05)
        ..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(x + 10, top + 47),
      Offset(x + 10, top + 55),
      Paint()
        ..color = const Color(0xFFB65A05)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _HiveIllustrationPainter oldDelegate) => false;
}
