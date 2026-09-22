import '../../services/password_service.dart';
import '../../services/storage_service.dart';
import '../../repositories/colmeia_repository.dart';
import '../../repositories/dado_repository.dart';
import '../../repositories/meliponicultor_repository.dart';

class LocalDataInitializer {
  LocalDataInitializer._();

  static final LocalDataInitializer instance = LocalDataInitializer._();

  Future<void>? _initialization;

  Future<void> ensureInitialized() {
    return _initialization ??= _seedIfDatabaseIsEmpty();
  }

  Future<void> _seedIfDatabaseIsEmpty() async {
    final beekeeperRepository = MeliponicultorRepository();
    final beekeeperRows = await beekeeperRepository.listar();

    if (beekeeperRows.isNotEmpty) return;

    final initialBeekeeper = StorageService.initialBeekeeperData;
    final beekeeperId = await beekeeperRepository.inserir(
      nome: initialBeekeeper.name,
      email: initialBeekeeper.email,
      senhaHash: PasswordService.hash(''),
      endereco: initialBeekeeper.address,
      nomeMeliponicultura: initialBeekeeper.meliponaryName,
    );

    final hiveRepository = ColmeiaRepository();
    final dataRepository = DadoRepository();

    for (final hive in StorageService.initialHiveData) {
      final hiveId = await hiveRepository.inserir(
        nome: hive.name,
        meliponicultorId: beekeeperId,
        especieAbelha: hive.species,
        ipAddress: hive.ipAddress,
        nomeRedeWifi: hive.wifiName,
        senhaRedeWifi: hive.wifiPassword,
        dataCriacao: hive.createdAt,
      );

      for (final telemetry in hive.telemetryHistory) {
        await dataRepository.inserir(
          colmeiaId: hiveId,
          temperatura: telemetry.internalTemp,
          entrada: telemetry.trafficIn,
          saida: telemetry.trafficOut,
          dataInsercao: telemetry.timestamp,
        );
      }
    }
  }
}
