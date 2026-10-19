import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/hive_model.dart';
import '../../providers/hive_provider.dart';
import '../../services/simulation_service.dart';
import '../../widgets/bee_mascot_widget.dart';
import '../../widgets/honeycomb_background.dart';
import '../../widgets/roi_selector_widget.dart';
import '../hive/edit_hive_view.dart';

/// Tela de uma colmeia com suporte ao modo de simulação, seleção de ROI e modelo TFLite.
class HiveDetailView extends StatefulWidget {
  final String hiveId;

  const HiveDetailView({super.key, required this.hiveId});

  @override
  State<HiveDetailView> createState() => _HiveDetailViewState();
}

class _HiveDetailViewState extends State<HiveDetailView> {
  int _mediaIndex = 0;
  bool _isSimulationMode = true; // Ativo por predefinição para testes no emulador
  File? _simulationFile;
  Rect? _currentRoi;
  final SimulationService _simulationService = SimulationService();

  Future<void> _pickSimulationImage() async {
    final XFile? picked = await _simulationService.pickSimulationImage();
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _simulationFile = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HiveProvider>(
      builder: (context, provider, _) {
        if (provider.hives.isEmpty) {
          return const Scaffold(
            backgroundColor: _HivePageColors.yellow,
            body: Center(child: Text('Nenhuma colmeia cadastrada')),
          );
        }

        final hive = provider.hives.firstWhere(
          (item) => item.id == widget.hiveId,
          orElse: () => provider.hives.first,
        );

        return Scaffold(
          backgroundColor: _HivePageColors.yellow,
          body: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(child: HoneycombBackground()),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, viewport) {
                    final contentHeight = math.max(
                      viewport.maxHeight - 24,
                      720.0,
                    );
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      child: SizedBox(
                        height: contentHeight,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _HiveHeader(
                                    name: hive.name,
                                    onBack: () => Navigator.of(context).pop(),
                                    onEdit: () => _openEdit(context, hive),
                                  ),
                                  
                                  // --- BARRA DE CONTROLO DE SIMULAÇÃO ---
                                  _SimulationToggleBar(
                                    isSimulation: _isSimulationMode,
                                    onToggle: (val) {
                                      setState(() {
                                        _isSimulationMode = val;
                                      });
                                    },
                                    onPickImage: _pickSimulationImage,
                                  ),

                                  const SizedBox(height: 4),
                                  _TemperaturePanel(
                                    hive: hive,
                                    onBeeTap: () =>
                                        _showBeeMessage(context, hive),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // --- PAINEL DE MEDIA / SELETOR DE ROI ---
                                  // --- PAINEL DE MEDIA / SELETOR DE ROI ---
                                  _MediaPanel(
                                    hive: hive,
                                    selectedIndex: _mediaIndex, // Ajustado para usar _mediaIndex (que é o nome correto da variável no seu estado)
                                    simulationFile: _simulationFile,
                                    initialNormalizedRoi: _currentRoi ?? const Rect.fromLTWH(0.2, 0.35, 0.6, 0.3), // Nome correto do parâmetro
                                    onRoiChanged: (newRect) {
                                      setState(() {
                                        _currentRoi = newRect;
                                      });
                                    },
                                    onPrevious: () => _changeMedia(hive, _mediaIndex - 1),
                                    onNext: () => _changeMedia(hive, _mediaIndex + 1),
                                    onOpen: () => _openMedia(context, hive),
                                  ),
                                  const SizedBox(height: 8),
                                  _TrafficPanel(hive: hive),
                                  const SizedBox(height: 8),
                                  _DownloadButton(
                                    onPressed: () => _downloadReport(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _changeMedia(HiveModel hive, int nextIndex) {
    final count = _mediaItems(hive).length;
    if (count == 0) return;
    setState(() => _mediaIndex = (nextIndex + count) % count);
  }

void _openMedia(BuildContext context, HiveModel hive) async {
    if (_isSimulationMode && _simulationFile != null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.all(18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 1.35,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RoiSelectorWidget(
                          imageFile: _simulationFile!,
                          initialNormalizedRoi: _currentRoi ?? const Rect.fromLTWH(0.2, 0.35, 0.6, 0.3),
                          onRoiChanged: (normalizedRect) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _currentRoi = normalizedRect;
                                });
                              }
                            });
                          },
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close, color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      // Ao fechar o modal/dialog, força uma atualização do estado da tela principal para garantir a sincronia no painel pequeno
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final items = _mediaItems(hive);
    final item = items[_mediaIndex % items.length];
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 1.35,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _MediaPreview(item: item, index: _mediaIndex, expanded: true),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_HiveMedia> _mediaItems(HiveModel hive) {
    final source = hive.galleryPhotos.isEmpty
        ? const ['registro_entrada', 'video_atividade', 'registro_colmeia']
        : hive.galleryPhotos;
    return [
      for (var index = 0; index < source.length; index++)
        _HiveMedia(source[index], isVideo: index == 1),
    ];
  }

  void _openEdit(BuildContext context, HiveModel hive) {
    Navigator.of(
      context,
    ).push(CupertinoPageRoute(builder: (_) => EditHiveView(hiveId: hive.id)));
  }

  void _showBeeMessage(BuildContext context, HiveModel hive) {
    final telemetry = hive.telemetry;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          telemetry.isThermallyIdeal
              ? 'A abelha está feliz: temperatura ideal.'
              : telemetry.isTooCold
              ? 'A abelha está com frio.'
              : 'A abelha está sentindo calor.',
        ),
      ),
    );
  }

  void _downloadReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Relatório preparado para download.')),
    );
  }
}

class _SimulationToggleBar extends StatelessWidget {
  final bool isSimulation;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickImage;

  const _SimulationToggleBar({
    required this.isSimulation,
    required this.onToggle,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isSimulation ? Icons.bug_report : Icons.wifi,
                color: isSimulation ? _HivePageColors.yellowDark : _HivePageColors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isSimulation ? 'Emulador / ROI Ativo' : 'ESP32 ao vivo',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (isSimulation)
                IconButton(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.add_photo_alternate, color: _HivePageColors.yellowDark),
                  tooltip: 'Carregar Imagem de Teste',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(right: 8),
                ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: isSimulation,
                  onChanged: onToggle,
                  activeColor: _HivePageColors.yellowDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HiveHeader extends StatelessWidget {
  final String name;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const _HiveHeader({
    required this.name,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 45),
            color: Colors.white,
            tooltip: 'Voltar',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 55, minHeight: 55),
          ),
          Expanded(
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(17),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(
                  CupertinoIcons.pencil,
                  color: _HivePageColors.yellowDark,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperaturePanel extends StatelessWidget {
  final HiveModel hive;
  final VoidCallback onBeeTap;

  const _TemperaturePanel({required this.hive, required this.onBeeTap});

  @override
  Widget build(BuildContext context) {
    final telemetry = hive.telemetry;
    final temperature = telemetry.internalTemp;
    final isIdeal = telemetry.isThermallyIdeal;
    final accent = isIdeal ? _HivePageColors.green : _HivePageColors.cyan;
    final message = isIdeal
        ? 'Abelhas estão com a temperatura ideal'
        : 'Abelhas estão com frio, temperatura abaixa';

    return SizedBox(
      height: 288,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 175,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            height: 234,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 5,
                  child: SizedBox(
                    height: 165,
                    width: 260,
                    child: CustomPaint(
                      painter: _TemperatureGaugePainter(
                        progress: _gaugeProgress(temperature),
                        accent: accent,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 69,
                  child: Text(
                    '${temperature.round()}°',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 58,
                      height: 0.9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    ),
                  ),
                ),
                Positioned(
                  top: 136,
                  child: Text(
                    'TEMPERATURA (°C)',
                    style: TextStyle(
                      color: _HivePageColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  top: 175,
                  left: 8,
                  right: 8,
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      height: 1.05,
                    ),
                  ),
                ),
                Positioned(
                  top: 187,
                  child: Text(
                    'Abelha ${hive.shortSpecies}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 215,
            child: GestureDetector(
              onTap: onBeeTap,
              child: BeeMascotWidget(size: 90, internalTemp: temperature),
            ),
          ),
        ],
      ),
    );
  }

  double _gaugeProgress(double temperature) =>
      ((temperature / 40).clamp(0.08, 0.94)).toDouble();
}

class _MediaPanel extends StatelessWidget {
  final HiveModel hive;
  final int selectedIndex;
  final File? simulationFile;
  final Rect initialNormalizedRoi; // Adicionado aqui
  final ValueChanged<Rect> onRoiChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onOpen;

  const _MediaPanel({
    required this.hive,
    required this.selectedIndex,
    this.simulationFile,
    required this.initialNormalizedRoi, // Adicionado aqui
    required this.onRoiChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final items = hive.galleryPhotos.isEmpty
        ? const ['registro_entrada', 'video_atividade', 'registro_colmeia']
        : hive.galleryPhotos;
    final safeIndex = selectedIndex % items.length;
    final media = _HiveMedia(items[safeIndex], isVideo: safeIndex == 1);

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            simulationFile != null ? 'DEFINIR ÁREA DE ENTRADA (ROI)' : 'FOTOS E VÍDEOS DA COLMEIA',
            style: const TextStyle(
              color: _HivePageColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Row(
              children: [
                if (simulationFile == null)
                  _MediaArrow(icon: Icons.chevron_left, onTap: onPrevious),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpen,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (simulationFile != null)
                            RoiSelectorWidget(
                              imageFile: simulationFile!,
                              initialNormalizedRoi: initialNormalizedRoi, // Passado corretamente
                              onRoiChanged: (normalizedRect) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  onRoiChanged(normalizedRect);
                                });
                              },
                            )
                          else ...[
                            _MediaPreview(item: media, index: safeIndex),
                            Positioned(
                              right: 5,
                              top: 5,
                              child: _MediaTag(
                                label: media.isVideo ? 'VÍDEO' : 'FOTO',
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
                if (simulationFile == null)
                  _MediaArrow(icon: Icons.chevron_right, onTap: onNext),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficPanel extends StatelessWidget {
  final HiveModel hive;

  const _TrafficPanel({required this.hive});

  @override
  Widget build(BuildContext context) {
    final telemetry = hive.telemetry;
    final traffic = telemetry.totalTraffic;
    final fill = (traffic / 50).clamp(0.08, 1.0).toDouble();
    final barColor = telemetry.isThermallyIdeal
        ? _HivePageColors.green
        : _HivePageColors.red;

    return Container(
      height: 77,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.fromLTRB(11, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTRADA E SAÍDA DAS ABELHAS',
            style: TextStyle(
              color: _HivePageColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fill,
                      child: Container(
                        height: 19,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$traffic',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 31,
                        height: 0.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'abelhas/min',
                      style: TextStyle(
                        color: _HivePageColors.muted,
                        fontSize: 10,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DownloadButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      height: 34,
      child: Material(
        color: _HivePageColors.yellowDark,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: const Icon(Icons.file_download_outlined, color: Colors.white),
        ),
      ),
    );
  }
}

class _MediaArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MediaArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 27,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 42),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          backgroundColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    );
  }
}

class _MediaTag extends StatelessWidget {
  final String label;

  const _MediaTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HiveMedia {
  final String source;
  final bool isVideo;

  const _HiveMedia(this.source, {required this.isVideo});
}

class _MediaPreview extends StatelessWidget {
  final _HiveMedia item;
  final int index;
  final bool expanded;

  const _MediaPreview({
    required this.item,
    required this.index,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return _MockHivePhoto(index: index, expanded: expanded);
  }
}

class _MockHivePhoto extends StatelessWidget {
  final int index;
  final bool expanded;

  const _MockHivePhoto({required this.index, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HivePhotoPainter(seed: index),
      child: const SizedBox.expand(),
    );
  }
}

class _TemperatureGaugePainter extends CustomPainter {
  final double progress;
  final Color accent;

  const _TemperatureGaugePainter({
    required this.progress,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width * 0.375;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height * 0.71),
      radius: radius,
    );
    const start = math.pi * 0.90;
    const sweep = math.pi * 1.20;
    final track = Paint()
      ..color = const Color(0xFF777777)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;
    final value = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, start, sweep, false, track);
    canvas.drawArc(rect, start, sweep * progress, false, value);
  }

  @override
  bool shouldRepaint(covariant _TemperatureGaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

class _HivePhotoPainter extends CustomPainter {
  final int seed;

  const _HivePhotoPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF7A5330),
      const Color(0xFF9B7652),
      const Color(0xFF5A3B27),
    ];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[seed % colors.length], const Color(0xFFE4C18A)],
        ).createShader(Offset.zero & size),
    );
    final plank = Paint()..color = Colors.black.withOpacity(0.12);
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 5),
        Offset(size.width, size.height * (i / 5 + 0.08)),
        plank,
      );
    }

    final nest = Paint()..color = const Color(0xFF2B1A11);
    final nestRect = Rect.fromCenter(
      center: Offset(size.width * 0.54, size.height * 0.58),
      width: size.width * 0.52,
      height: size.height * 0.48,
    );
    canvas.drawOval(nestRect, nest);
    canvas.drawOval(
      nestRect.deflate(8),
      Paint()..color = const Color(0xFFCC842A),
    );
    canvas.drawOval(
      nestRect.deflate(18),
      Paint()..color = const Color(0xFF24150D),
    );

    final bee = Paint()..color = const Color(0xFFFBBF24);
    for (var i = 0; i < 4; i++) {
      final point = Offset(
        size.width * (0.2 + ((i * 37 + seed * 11) % 60) / 100),
        size.height * (0.25 + ((i * 23 + seed * 7) % 45) / 100),
      );
      canvas.drawOval(
        Rect.fromCenter(center: point, width: 11, height: 7),
        bee,
      );
      canvas.drawLine(
        Offset(point.dx, point.dy - 3),
        Offset(point.dx, point.dy + 3),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HivePhotoPainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _HivePageColors {
  static const yellow = Color(0xFFFFC107);
  static const yellowDark = Color(0xFF9A5C00);
  static const green = Color(0xFF08BC67);
  static const cyan = Color(0xFF13B9D3);
  static const red = Color(0xFFFF3038);
  static const muted = Color(0xFF777777);
}