import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/beekeeper_model.dart';
import '../../providers/beekeeper_provider.dart';
import '../../providers/hive_provider.dart';
import '../../widgets/bee_mascot_widget.dart';
import '../../widgets/honeycomb_background.dart';
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
          const Positioned.fill(
            child: IgnorePointer(child: HoneycombBackground()),
          ),
          SafeArea(
            child: Consumer2<HiveProvider, BeekeeperProvider>(
              builder: (context, hiveProvider, beekeeperProvider, _) {
                final hives = hiveProvider.hives;
                final screenWidth = MediaQuery.sizeOf(context).width;
                final horizontalPadding = (screenWidth * 0.07)
                    .clamp(16.0, 30.0)
                    .toDouble();
                final gridSpacing = (screenWidth * 0.065)
                    .clamp(12.0, 23.0)
                    .toDouble();
                final crossAxisCount = screenWidth >= 900
                    ? 4
                    : screenWidth >= 600
                    ? 3
                    : 2;
                final cardAspectRatio = screenWidth < 300 ? 0.88 : 0.98;
                final bottomPadding = MediaQuery.paddingOf(context).bottom + 92;
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
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          12,
                          horizontalPadding,
                          bottomPadding,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: gridSpacing,
                                mainAxisSpacing: 14,
                                childAspectRatio: cardAspectRatio,
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
                    fontSize: 22,
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
                          fontSize: 15,
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
              width: 58,
              height: 58,
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
    final beeTemperature = average == 0 ? 28.0 : average;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (MediaQuery.sizeOf(context).width * 0.07)
            .clamp(16.0, 30.0)
            .toDouble(),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final summaryWidth = constraints.maxWidth;
          final summaryHeight = (summaryWidth * 0.40)
              .clamp(118.0, 146.0)
              .toDouble();
          final beeSize = (summaryWidth * 0.30).clamp(100.0, 150.0).toDouble();
          final contentRight = beeSize * 0.43;

          return Container(
            height: summaryHeight,
            padding: EdgeInsets.fromLTRB(summaryWidth < 260 ? 6 : 8, 10, 8, 9),
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
                Positioned(
                  right: 2,
                  top: 4,
                  child: SizedBox(
                    width: beeSize * 1.12,
                    height: beeSize * 1.02,
                    child: CustomPaint(painter: _SummaryHoneycombPainter()),
                  ),
                ),
                Positioned.fill(
                  right: contentRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topLeft,
                    child: Column(
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
                        const Row(
                          children: [
                            Text(
                              'Temperatura',
                              style: TextStyle(
                                color: Color(0xFF68727B),
                                fontSize: 9,
                              ),
                            ),
                            SizedBox(width: 42),
                            Text(
                              'Circulação',
                              style: TextStyle(
                                color: Color(0xFF68727B),
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.thermostat_outlined,
                              color: Color.fromARGB(255, 255, 173, 31),
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
                            const SizedBox(width: 28),
                            const Icon(
                              Icons.swap_vert,
                              color: Color.fromARGB(255, 255, 173, 31),
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
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 10,
                  child: BeeMascotWidget(
                    key: ValueKey(
                      'dashboard-bee-${beeTemperature.toStringAsFixed(1)}',
                    ),
                    size: beeSize,
                    internalTemp: beeTemperature,
                    showSpeechBubble: false,
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
          center.dx + 24 * math.cos(angle),
          center.dy + 24 * math.sin(angle),
        ),
      );
    }
    canvas.drawPath(Path()..addPolygon(points, true), outer);
    canvas.drawCircle(center, 16.5, outline);
    canvas.drawCircle(center.translate(0, -3), 8.5, head);
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(0, 11), width: 29, height: 16),
      body,
    );
  }

  @override
  bool shouldRepaint(covariant _ProfileAvatarPainter oldDelegate) => false;
}

class _SummaryHoneycombPainter extends CustomPainter {
  const _SummaryHoneycombPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 10.5;
    const horizontal = 18.5;
    const vertical = 18.0;
    const rowStarts = [1, 0, 0, 1, 2];
    const rowCounts = [4, 5, 5, 4, 3];
    final colors = [
      const Color.fromARGB(169, 255, 231, 122),
      const Color.fromARGB(151, 255, 211, 78),
      const Color.fromARGB(150, 255, 234, 165),
    ];

    for (var row = 0; row < rowCounts.length; row++) {
      final shift = row.isOdd ? horizontal / 2 : 0.0;
      for (
        var column = rowStarts[row];
        column < rowStarts[row] + rowCounts[row];
        column++
      ) {
        final center = Offset(
          12 + column * horizontal + shift,
          11 + row * vertical,
        );
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
        final fill = Paint()..color = colors[(row + column) % colors.length];
        final border = Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawPath(path..close(), fill);
        canvas.drawPath(path, border);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SummaryHoneycombPainter oldDelegate) => false;
}
