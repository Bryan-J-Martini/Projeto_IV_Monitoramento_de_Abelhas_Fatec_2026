import 'dart:io';
import 'package:flutter/material.dart';

class RoiSelectorWidget extends StatefulWidget {
  final File imageFile;
  /// Retorna o Rect em coordenadas relativas/normalizadas (0.0 a 1.0)
  final ValueChanged<Rect> onRoiChanged;
  /// ROI inicial em coordenadas normalizadas (0.0 a 1.0)
  final Rect? initialNormalizedRoi;

  const RoiSelectorWidget({
    super.key,
    required this.imageFile,
    required this.onRoiChanged,
    this.initialNormalizedRoi,
  });

  @override
  State<RoiSelectorWidget> createState() => _RoiSelectorWidgetState();
}

class _RoiSelectorWidgetState extends State<RoiSelectorWidget> {
  // Rect em coordenadas normalizadas (0.0 a 1.0)
  Rect? _normRoi;
  bool _initialized = false;

  void _initNormRect() {
    if (_initialized) return;
    _normRoi = widget.initialNormalizedRoi ?? const Rect.fromLTWH(0.2, 0.35, 0.6, 0.3);
    _initialized = true;
    widget.onRoiChanged(_normRoi!);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (!_initialized && size.width > 0 && size.height > 0) {
          _initNormRect();
        }

        if (_normRoi == null || size.width == 0 || size.height == 0) {
          return Image.file(widget.imageFile, fit: BoxFit.cover);
        }

        // Converte o Rect normalizado (0..1) para pixels reais da tela atual
        final absRoi = Rect.fromLTRB(
          _normRoi!.left * size.width,
          _normRoi!.top * size.height,
          _normRoi!.right * size.width,
          _normRoi!.bottom * size.height,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Imagem de fundo
            Image.file(
              widget.imageFile,
              fit: BoxFit.cover,
            ),

            // 2. Overlay interativo da ROI
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  final dx = details.delta.dx / size.width;
                  final dy = details.delta.dy / size.height;

                  final w = _normRoi!.width;
                  final h = _normRoi!.height;

                  final newLeft = (_normRoi!.left + dx).clamp(0.0, 1.0 - w);
                  final newTop = (_normRoi!.top + dy).clamp(0.0, 1.0 - h);

                  _normRoi = Rect.fromLTWH(newLeft, newTop, w, h);
                  widget.onRoiChanged(_normRoi!);
                });
              },
              child: CustomPaint(
                painter: _RoiPainter(rect: absRoi),
              ),
            ),

            // 3. Alças de redimensionamento nos cantos
            _buildResizeHandle(
              left: absRoi.left - 12,
              top: absRoi.top - 12,
              onDrag: (delta) {
                setState(() {
                  final newLeft = ((absRoi.left + delta.dx) / size.width).clamp(0.0, _normRoi!.right - 0.05);
                  final newTop = ((absRoi.top + delta.dy) / size.height).clamp(0.0, _normRoi!.bottom - 0.05);
                  _normRoi = Rect.fromLTRB(newLeft, newTop, _normRoi!.right, _normRoi!.bottom);
                  widget.onRoiChanged(_normRoi!);
                });
              },
            ),
            _buildResizeHandle(
              left: absRoi.right - 12,
              top: absRoi.top - 12,
              onDrag: (delta) {
                setState(() {
                  final newRight = ((absRoi.right + delta.dx) / size.width).clamp(_normRoi!.left + 0.05, 1.0);
                  final newTop = ((absRoi.top + delta.dy) / size.height).clamp(0.0, _normRoi!.bottom - 0.05);
                  _normRoi = Rect.fromLTRB(_normRoi!.left, newTop, newRight, _normRoi!.bottom);
                  widget.onRoiChanged(_normRoi!);
                });
              },
            ),
            _buildResizeHandle(
              left: absRoi.left - 12,
              top: absRoi.bottom - 12,
              onDrag: (delta) {
                setState(() {
                  final newLeft = ((absRoi.left + delta.dx) / size.width).clamp(0.0, _normRoi!.right - 0.05);
                  final newBottom = ((absRoi.bottom + delta.dy) / size.height).clamp(_normRoi!.top + 0.05, 1.0);
                  _normRoi = Rect.fromLTRB(newLeft, _normRoi!.top, _normRoi!.right, newBottom);
                  widget.onRoiChanged(_normRoi!);
                });
              },
            ),
            _buildResizeHandle(
              left: absRoi.right - 12,
              top: absRoi.bottom - 12,
              onDrag: (delta) {
                setState(() {
                  final newRight = ((absRoi.right + delta.dx) / size.width).clamp(_normRoi!.left + 0.05, 1.0);
                  final newBottom = ((absRoi.bottom + delta.dy) / size.height).clamp(_normRoi!.top + 0.05, 1.0);
                  _normRoi = Rect.fromLTRB(_normRoi!.left, _normRoi!.top, newRight, newBottom);
                  widget.onRoiChanged(_normRoi!);
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildResizeHandle({required double left, required double top, required ValueChanged<Offset> onDrag}) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

class _RoiPainter extends CustomPainter {
  final Rect rect;

  _RoiPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect);
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, backgroundPaint);

    final borderPaint = Paint()
      ..color = Colors.amberAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _RoiPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}