import '../models/beekeeper_model.dart';
import '../models/hive_model.dart';
import '../models/telemetry_model.dart';

class StorageService {
  /// Dados usados somente uma vez pelo inicializador para criar o banco vazio.
  /// O estado normal do aplicativo vem dos repositórios SQLite.
  static List<HiveModel> get initialHiveData => getInitialHives();

  static BeekeeperModel get initialBeekeeperData => getInitialBeekeeper();

  /// Gera colmeias de exemplo para demonstração e inicialização
  static List<HiveModel> getInitialHives() {
    final now = DateTime.now();

    return [
      HiveModel(
        id: 'hive_jatai_01',
        name: 'Jataí 01',
        species: 'Jataí (Tetragonisca angustula)',
        description: 'Caixa INPA 12x12 padrão. Enxame maduro com disco de postura ativo.',
        ipAddress: '192.168.4.1',
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 45)),
        telemetry: TelemetryModel(
          internalTemp: 28.8,
          trafficIn: 38,
          trafficOut: 34,
          externalTemp: 27.4,
          externalHumidity: 65.0,
          timestamp: now,
        ),
        telemetryHistory: [
          TelemetryModel(
            internalTemp: 28.2,
            trafficIn: 30,
            trafficOut: 28,
            externalTemp: 26.8,
            externalHumidity: 67.0,
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
          TelemetryModel(
            internalTemp: 28.5,
            trafficIn: 35,
            trafficOut: 32,
            externalTemp: 27.0,
            externalHumidity: 66.0,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
          TelemetryModel(
            internalTemp: 28.8,
            trafficIn: 38,
            trafficOut: 34,
            externalTemp: 27.4,
            externalHumidity: 65.0,
            timestamp: now,
          ),
        ],
        galleryPhotos: [
          'alvado_jatai_manha',
          'alvado_jatai_pollen',
          'alvado_jatai_guarda',
        ],
      ),
      HiveModel(
        id: 'hive_mandacaia_a',
        name: 'Mandaçaia A',
        species: 'Mandaçaia (Melipona quadrifasciata)',
        description: 'Caixa modular vertical 20x20. Excelente produção de geoprópolis.',
        ipAddress: '192.168.4.2',
        isOnline: true,
        createdAt: now.subtract(const Duration(days: 90)),
        telemetry: TelemetryModel(
          internalTemp: 29.4,
          trafficIn: 45,
          trafficOut: 41,
          externalTemp: 28.0,
          externalHumidity: 62.0,
          timestamp: now,
        ),
        telemetryHistory: [
          TelemetryModel(
            internalTemp: 29.0,
            trafficIn: 40,
            trafficOut: 38,
            externalTemp: 27.5,
            externalHumidity: 64.0,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
          TelemetryModel(
            internalTemp: 29.4,
            trafficIn: 45,
            trafficOut: 41,
            externalTemp: 28.0,
            externalHumidity: 62.0,
            timestamp: now,
          ),
        ],
        galleryPhotos: [
          'alvado_mandacaia_geopolis',
          'alvado_mandacaia_entrada',
        ],
      ),
      HiveModel(
        id: 'hive_urucu_03',
        name: 'Uruçu Amarela 03',
        species: 'Uruçu Amarela (Melipona flavolineata)',
        description: 'Enxame recém-transferido. Localizado sob sombrite no fundo do meliponário.',
        ipAddress: '192.168.4.3',
        isOnline: false, // Simula colmeia com nó desconectado
        createdAt: now.subtract(const Duration(days: 15)),
        telemetry: TelemetryModel(
          internalTemp: 25.2, // Temperatura limítrofe/baixa para demonstrar mascote em alerta
          trafficIn: 12,
          trafficOut: 10,
          externalTemp: 24.1,
          externalHumidity: 72.0,
          timestamp: now.subtract(const Duration(minutes: 28)),
        ),
        telemetryHistory: [
          TelemetryModel(
            internalTemp: 25.2,
            trafficIn: 12,
            trafficOut: 10,
            externalTemp: 24.1,
            externalHumidity: 72.0,
            timestamp: now.subtract(const Duration(minutes: 28)),
          ),
        ],
        galleryPhotos: [
          'alvado_urucu_repouso',
        ],
      ),
    ];
  }

  static BeekeeperModel getInitialBeekeeper() {
    return BeekeeperModel.initial();
  }
}
