import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/beekeeper_model.dart';
import '../../providers/beekeeper_provider.dart';
import '../../providers/hive_provider.dart';
import '../../widgets/bee_mascot_widget.dart';
import '../connection/connect_hive_view.dart';
import '../details/hive_detail_view.dart';
import '../profile/beekeeper_setup_view.dart';
import 'widgets/hive_card.dart';

/// Tela inicial inspirada no layout de referência.
///
/// Os números e os estados continuam vindo dos providers. As ilustrações são
/// desenhadas em Dart para que a tela não dependa de arquivos de imagem.
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB900),
      body: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _HomeBackground())),
          SafeArea(
            bottom: false,
            child: Consumer2<HiveProvider, BeekeeperProvider>(
              builder: (context, hiveProvider, beekeeperProvider, _) {
                final hives = hiveProvider.hives;
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(beekeeper: beekeeperProvider.beekeeper),
                    ),
                    SliverToBoxAdapter(
                      child: _TelemetrySummary(hiveProvider: hiveProvider),
                    ),
                    if (hives.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onAdd: () => _openConnect(context)),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(23, 12, 23, 112),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 23,
                                mainAxisSpacing: 14,
                                childAspectRatio: 0.98,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final hive = hives[index];
                            return HiveCard(
                              hive: hive,
                              onTap: () {
                                hiveProvider.selectHive(hive.id);
                                Navigator.of(context).push(
                                  CupertinoPageRoute(
                                    builder: (_) =>
                                        HiveDetailView(hiveId: hive.id),
                                  ),
                                );
                              },
                            );
                          }, childCount: hives.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _AddHiveButton(
        onPressed: () => _openConnect(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _openConnect(BuildContext context) {
    Navigator.of(context)
        .push(CupertinoPageRoute(builder: (_) => const ConnectHiveView()));
  }
}

class _Header extends StatelessWidget {
  final BeekeeperModel beekeeper;

  const _Header({required this.beekeeper});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(23, 26, 23, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  beekeeper.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 17,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        beekeeper.meliponaryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const BeekeeperSetupView()),
            ),
            child: const SizedBox(
              width: 68,
              height: 68,
              child: CustomPaint(painter: _ProfileAvatarPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetrySummary extends StatelessWidget {
  final HiveProvider hiveProvider;

  const _TelemetrySummary({required this.hiveProvider});

  @override
  Widget build(BuildContext context) {
    final average = hiveProvider.averageInternalTemp;
    final hive = hiveProvider.selectedHive;
    final traffic = hive?.telemetry.totalTraffic ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 23),
      child: Container(
        height: 118,
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B6500).withOpacity(0.18),
              blurRadius: 7,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Colmeias Conectadas',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Transform.rotate(
                      angle: -0.65,
                      child: const Icon(
                        Icons.link,
                        color: Color(0xFF00B979),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${hiveProvider.onlineCount}',
                      style: const TextStyle(
                        color: Color(0xFF68727B),
                        fontSize: 32,
                        height: 0.9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Média das Colmeias',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Temperatura',
                      style: TextStyle(color: Color(0xFF68727B), fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.thermostat_outlined,
                      color: Color(0xFF9B9B9B),
                      size: 24,
                    ),
                    Text(
                      '${average.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        color: Color(0xFF68727B),
                        fontSize: 31,
                        height: 0.88,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 19),
                    const Icon(
                      Icons.swap_vert,
                      color: Color(0xFF8E8E8E),
                      size: 28,
                    ),
                    Text(
                      '$traffic',
                      style: const TextStyle(
                        color: Color(0xFF68727B),
                        fontSize: 31,
                        height: 0.88,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    SizedBox(width: 102),
                    Text(
                      'Temperatura',
                      style: TextStyle(color: Color(0xFF68727B), fontSize: 9),
                    ),
                    SizedBox(width: 31),
                    Text(
                      'Circulação',
                      style: TextStyle(color: Color(0xFF68727B), fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              right: -2,
              top: 2,
              child: BeeMascotWidget(
                size: 72,
                internalTemp: average == 0 ? 28 : average,
                showSpeechBubble: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddHiveButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AddHiveButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A4800).withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CupertinoButton(
        color: const Color(0xFF9C5A00),
        borderRadius: BorderRadius.circular(26),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        onPressed: onPressed,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 31, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'Adicionar Colmeia',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hive_outlined, size: 58, color: Color(0xFF9C5A00)),
            const SizedBox(height: 12),
            const Text(
              'Seu meliponário está vazio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            const Text(
              'Adicione a primeira colmeia para começar.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Adicionar colmeia'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  const _HomeBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC400), Color(0xFFFFB000)],
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
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    const radius = 18.0;
    const horizontal = 31.0;
    const vertical = 27.0;
    for (double y = size.height - 85; y < size.height + radius; y += vertical) {
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

class _ProfileAvatarPainter extends CustomPainter {
  const _ProfileAvatarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = Paint()..color = Colors.white;
    final outline = Paint()
      ..color = const Color(0xFFF1A914)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final head = Paint()..color = const Color(0xFFFFAA2B);
    final body = Paint()..color = const Color(0xFFFFAA2B);
    final points = <Offset>[];
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 6;
      points.add(
        Offset(
          center.dx + 28 * math.cos(angle),
          center.dy + 28 * math.sin(angle),
        ),
      );
    }
    canvas.drawPath(Path()..addPolygon(points, true), outer);
    canvas.drawCircle(center, 22, outline);
    canvas.drawCircle(center.translate(0, -5), 12, head);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 15), width: 39, height: 22),
      body,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileAvatarPainter oldDelegate) => false;
}
