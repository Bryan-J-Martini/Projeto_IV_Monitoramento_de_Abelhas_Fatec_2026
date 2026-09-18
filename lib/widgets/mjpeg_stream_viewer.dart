import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/theme/app_colors.dart';

class MjpegStreamViewer extends StatefulWidget {
  final String streamUrl;
  final String hiveName;
  final bool isOnline;
  final List<String> galleryPhotos;

  const MjpegStreamViewer({
    super.key,
    required this.streamUrl,
    required this.hiveName,
    required this.isOnline,
    this.galleryPhotos = const [],
  });

  @override
  State<MjpegStreamViewer> createState() => _MjpegStreamViewerState();
}

class _MjpegStreamViewerState extends State<MjpegStreamViewer>
    with SingleTickerProviderStateMixin {
  int _selectedSegment = 0; // 0 = Ao Vivo, 1 = Galeria
  late AnimationController _flightAnimController;

  @override
  void initState() {
    super.initState();
    _flightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _flightAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Alternador de Segmento Apple/iOS
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: CupertinoSlidingSegmentedControl<int>(
              backgroundColor: AppColors.surfaceGray,
              thumbColor: Colors.white,
              groupValue: _selectedSegment,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.videocam_fill, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Ao Vivo (Vídeo)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.photo_on_rectangle, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Galeria de Registros',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              },
              onValueChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedSegment = val;
                  });
                }
              },
            ),
          ),
        ),

        // Área de Exibição
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _selectedSegment == 0
              ? _buildLiveStreamArea()
              : _buildGalleryArea(),
        ),
      ],
    );
  }

  Widget _buildLiveStreamArea() {
    return ClipRRect(
      key: const ValueKey('stream_area'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Fundo escuro de câmera
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Simulação visual de alta fidelidade do Alvado e Tubo de Cera
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _flightAnimController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _EntranceCameraPainter(
                      progress: _flightAnimController.value,
                      isOnline: widget.isOnline,
                    ),
                  );
                },
              ),
            ),

            // Gradiente escuro no topo para contraste dos controles
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Badge superior "AO VIVO • MJPEG" e Status
            Positioned(
              top: 12,
              left: 14,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isOnline
                          ? const Color(0xFFEF4444)
                          : AppColors.slate,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isOnline) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          widget.isOnline ? 'AO VIVO' : 'SINAL OFFLINE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      widget.isOnline ? 'ESP32 CAM • 15 FPS' : 'STANDBY',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Timestamp no canto inferior direito
            Positioned(
              bottom: 12,
              right: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat('HH:mm:ss').format(DateTime.now()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Informação da colmeia no canto inferior esquerdo
            Positioned(
              bottom: 12,
              left: 14,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.camera_viewfinder,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Alvado - ${widget.hiveName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryArea() {
    final List<Map<String, String>> snapshots = [
      {
        'title': 'Registro Matinal',
        'time': 'Hoje às 08:30',
        'desc': 'Tráfego intenso de pólen amarelo',
        'status': 'Normal',
      },
      {
        'title': 'Guardiãs no Tubo',
        'time': 'Hoje às 07:15',
        'desc': '5 abelhas atentas na borda de cera',
        'status': 'Seguro',
      },
      {
        'title': 'Fechamento Noturno',
        'time': 'Ontem às 18:45',
        'desc': 'Redução de abertura com resina protetora',
        'status': 'Protegido',
      },
    ];

    return SizedBox(
      key: const ValueKey('gallery_area'),
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: snapshots.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = snapshots[index];
          return Container(
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo ilustrativo do snapshot do alvado
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(19),
                  ),
                  child: Container(
                    height: 115,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: index == 0
                            ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                            : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Desenho do alvado estilizado
                        CustomPaint(
                          size: const Size(200, 115),
                          painter: _EntranceThumbnailPainter(seed: index),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['status']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['time']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mute,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['desc']!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EntranceCameraPainter extends CustomPainter {
  final double progress;
  final bool isOnline;

  _EntranceCameraPainter({
    required this.progress,
    required this.isOnline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fundo da madeira da caixa da colmeia
    final woodPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF451A03),
          const Color(0xFF78350F),
          const Color(0xFF451A03),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), woodPaint);

    // Textura de veios de madeira sutis
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    for (double i = 20; i < h; i += 30) {
      final p = Path()
        ..moveTo(0, i)
        ..quadraticBezierTo(w * 0.5, i + 8, w, i - 4);
      canvas.drawPath(p, grainPaint);
    }

    // Tubo de cera / Geoprópolis característico (alvado de Melipona / Jataí)
    final tubeCenter = Offset(w * 0.5, h * 0.55);
    final tubeOuterRect =
        Rect.fromCenter(center: tubeCenter, width: 85, height: 70);
    final tubePaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFD97706),
          Color(0xFF92400E),
          Color(0xFF451A03),
        ],
      ).createShader(tubeOuterRect);
    canvas.drawOval(tubeOuterRect, tubePaint);

    // Interior escuro do ninho
    final innerTubeRect =
        Rect.fromCenter(center: tubeCenter, width: 50, height: 42);
    final darkInner = Paint()..color = const Color(0xFF170F08);
    canvas.drawOval(innerTubeRect, darkInner);

    if (!isOnline) {
      // Indicador visual de ausência de stream
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Conexão MJPEG Desconectada\nVerifique o Wi-Fi do ESP32',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 40);
      textPainter.paint(
        canvas,
        Offset((w - textPainter.width) / 2, (h - textPainter.height) / 2),
      );
      return;
    }

    // Simulação de abelhas forrageiras voando ao redor do tubo
    final beePositions = [
      Offset(
        tubeCenter.dx + math.sin(progress * 2 * math.pi) * 60,
        tubeCenter.dy + math.cos(progress * 2 * math.pi) * 30 - 20,
      ),
      Offset(
        tubeCenter.dx - math.cos(progress * 2 * math.pi + 1.2) * 80,
        tubeCenter.dy + math.sin(progress * 2 * math.pi + 1.2) * 35,
      ),
      Offset(
        tubeCenter.dx + 16,
        tubeCenter.dy + 8, // Guardiã pousada na borda
      ),
    ];

    for (int i = 0; i < beePositions.length; i++) {
      _drawFlyingBee(canvas, beePositions[i], isHovering: i == 2);
    }
  }

  void _drawFlyingBee(Canvas canvas, Offset pos, {bool isHovering = false}) {
    // Corpo miniatura da abelha
    final bodyPaint = Paint()..color = const Color(0xFFFBBF24);
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 10, height: 6),
      bodyPaint,
    );

    // Listrinha
    final stripe = Paint()..color = Colors.black;
    canvas.drawRect(
      Rect.fromCenter(center: pos, width: 2, height: 6),
      stripe,
    );

    // Asinhas translúcidas
    final wing = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 4),
        width: 8,
        height: 5,
      ),
      wing,
    );
  }

  @override
  bool shouldRepaint(covariant _EntranceCameraPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isOnline != isOnline;
  }
}

class _EntranceThumbnailPainter extends CustomPainter {
  final int seed;

  _EntranceThumbnailPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final wood = Paint()..color = const Color(0xFF5C2D12);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), wood);

    final tube = Paint()..color = const Color(0xFFB45309);
    final center = Offset(w * 0.5, h * 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 60, height: 45),
      tube,
    );

    final inner = Paint()..color = const Color(0xFF1C110A);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 34, height: 26),
      inner,
    );

    // Pontinho de pólen ou abelhinha
    final pollen = Paint()
      ..color = seed == 0 ? const Color(0xFFFDE047) : const Color(0xFFFBBF24);
    canvas.drawCircle(Offset(center.dx + 8, center.dy - 6), 3, pollen);
  }

  @override
  bool shouldRepaint(covariant _EntranceThumbnailPainter oldDelegate) => false;
}
