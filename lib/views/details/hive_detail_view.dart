import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/hive_model.dart';
import '../../providers/hive_provider.dart';
import '../../widgets/bee_mascot_widget.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/mjpeg_stream_viewer.dart';
import '../../widgets/status_badge.dart';

class HiveDetailView extends StatefulWidget {
  final String hiveId;

  const HiveDetailView({super.key, required this.hiveId});

  @override
  State<HiveDetailView> createState() => _HiveDetailViewState();
}

class _HiveDetailViewState extends State<HiveDetailView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HiveProvider>(
      builder: (context, provider, child) {
        final hive = provider.hives.firstWhere(
          (h) => h.id == widget.hiveId,
          orElse: () => provider.hives.first,
        );
        final telemetry = hive.telemetry;

        return Scaffold(
          backgroundColor: AppColors.canvasBg,
          appBar: AppBar(
            title: Text(hive.name),
            actions: [
              // Botão de atualização rápida de telemetria
              IconButton(
                icon: provider.isRefreshing
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.arrow_clockwise),
                tooltip: 'Atualizar Telemetria',
                onPressed: provider.isRefreshing
                    ? null
                    : () => provider.refreshHiveTelemetry(hive.id),
              ),
              // Menu de opções rápidas (ex: simular variações térmicas para teste)
              IconButton(
                icon: const Icon(CupertinoIcons.slider_horizontal_3),
                tooltip: 'Testar Resposta Térmica do Mascote',
                onPressed: () => _showThermalSimulatorSheet(context, provider, hive),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Header com dados básicos da colmeia
                  Hero(
                    tag: 'hive_card_${hive.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: GlassContainer(
                        borderRadius: 22,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      hive.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(
                                      isOnline: hive.isOnline,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hive.species,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                            // Indicador de IP ESP32
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hive.ipAddress,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. ÁREA SUPERIOR MÍDIA / STREAMING (Vídeo Ao Vivo MJPEG vs Galeria)
                  MjpegStreamViewer(
                    streamUrl: 'http://${hive.ipAddress}/stream',
                    hiveName: hive.name,
                    isOnline: hive.isOnline,
                    galleryPhotos: hive.galleryPhotos,
                  ),

                  const SizedBox(height: 22),

                  // 2. ELEMENTO INTERATIVO: SAÚDE BIOLÓGICA & MASCOTE VIVO
                  GlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BeeMascotWidget(
                          size: 76,
                          internalTemp: telemetry.internalTemp,
                          showSpeechBubble: true,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ÍNDICE DE VIGOR',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: AppColors.mute,
                                    ),
                                  ),
                                  Text(
                                    '${telemetry.swarmHealthScore}%',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: telemetry.isThermallyIdeal
                                          ? AppColors.healthIdeal
                                          : AppColors.healthWarning,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: telemetry.swarmHealthScore / 100.0,
                                  backgroundColor: AppColors.surfaceGray,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    telemetry.isThermallyIdeal
                                        ? AppColors.healthIdeal
                                        : AppColors.healthWarning,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                telemetry.isThermallyIdeal
                                    ? 'Enxame forte e bem termorregulado.'
                                    : 'Atenção aos fatores ambientais da caixa.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. PAINEL DE MÉTRICAS (Cards de Vidro/Glassmorphism)
                  // 🌡️ Temperatura Interna
                  TemperatureMetricCard(
                    internalTemp: telemetry.internalTemp,
                  ),

                  const SizedBox(height: 16),

                  // 🐝 Contagem de Tráfego no Alvado
                  TrafficMetricCard(
                    trafficIn: telemetry.trafficIn,
                    trafficOut: telemetry.trafficOut,
                  ),

                  const SizedBox(height: 16),

                  // 🌤️ Clima e Temperatura Externa
                  ClimateMetricCard(
                    externalTemp: telemetry.externalTemp,
                    externalHumidity: telemetry.externalHumidity,
                  ),

                  const SizedBox(height: 20),

                  // Rodapé com horário da última sincronização
                  Center(
                    child: Text(
                      'Última leitura IoT: ${DateFormat('dd/MM/yyyy • HH:mm:ss').format(telemetry.timestamp)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mute,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sheet para simular variações térmicas e demonstrar o mascote reagindo (Ideal 26-32°C vs Frio vs Calor)
  void _showThermalSimulatorSheet(
    BuildContext context,
    HiveProvider provider,
    HiveModel hive,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Simulador Térmico & Reação do Mascote'),
        message: const Text(
          'Escolha uma temperatura para testar as micro-animações do mascote em tempo real:',
        ),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('🌟 Temperatura Ideal (28.5°C - Feliz)'),
            onPressed: () {
              provider.simulateTemperature(hive.id, 28.5);
              Navigator.of(ctx).pop();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('❄️ Alerta Frio (23.8°C - Preocupada)'),
            onPressed: () {
              provider.simulateTemperature(hive.id, 23.8);
              Navigator.of(ctx).pop();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('☀️ Alerta Calor (34.2°C - Suando)'),
            onPressed: () {
              provider.simulateTemperature(hive.id, 34.2);
              Navigator.of(ctx).pop();
            },
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            child: Text(
              hive.isOnline ? 'Simular Nó Offline' : 'Simular Nó Online',
            ),
            onPressed: () {
              provider.toggleOnlineStatus(hive.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }
}

