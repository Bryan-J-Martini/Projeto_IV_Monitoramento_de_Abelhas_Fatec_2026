import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/local_data_initializer.dart';
import '../models/hive_model.dart';
import '../models/telemetry_model.dart';
import '../repositories/colmeia_repository.dart';
import '../repositories/dado_repository.dart';
import '../services/esp32_service.dart';

class HiveProvider extends ChangeNotifier {
  final Esp32Service _esp32Service;
  final ColmeiaRepository _hiveRepository;
  final DadoRepository _dataRepository;

  Future<void> _loadFuture = Future<void>.value();
  int? _meliponicultorId;
  List<HiveModel> _hives = [];
  String? _selectedHiveId;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Timer? _periodicSyncTimer;

  HiveProvider({
    Esp32Service? esp32Service,
    ColmeiaRepository? hiveRepository,
    DadoRepository? dataRepository,
  })  : _esp32Service = esp32Service ?? Esp32Service(),
        _hiveRepository = hiveRepository ?? ColmeiaRepository(),
        _dataRepository = dataRepository ?? DadoRepository();

  void setMeliponicultorId(int? meliponicultorId) {
    if (_meliponicultorId == meliponicultorId) return;

    _meliponicultorId = meliponicultorId;
    _loadFuture = _loadFromDatabase(meliponicultorId);
    unawaited(_loadFuture);
  }

  List<HiveModel> get hives => List.unmodifiable(_hives);

  String? get selectedHiveId => _selectedHiveId;

  HiveModel? get selectedHive {
    if (_selectedHiveId == null || _hives.isEmpty) return null;
    try {
      return _hives.firstWhere((h) => h.id == _selectedHiveId);
    } catch (_) {
      return _hives.first;
    }
  }

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;

  int get onlineCount => _hives.where((h) => h.isOnline).length;

  int get totalCount => _hives.length;

  double get averageInternalTemp {
    if (_hives.isEmpty) return 0.0;
    final total = _hives.fold<double>(
      0.0,
      (sum, h) => sum + h.telemetry.internalTemp,
    );
    return double.parse((total / _hives.length).toStringAsFixed(1));
  }

  Future<void> _loadFromDatabase(int? ownerId) async {
    await LocalDataInitializer.instance.ensureInitialized();

    if (_meliponicultorId != ownerId) return;

    if (ownerId == null) {
      _hives = [];
      _selectedHiveId = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    final rows = await _hiveRepository.listarAtivas(
      meliponicultorId: ownerId,
    );
    final loadedHives = <HiveModel>[];

    for (final row in rows) {
      final hiveId = (row['id'] as num).toInt();
      final dataRows = await _dataRepository.listarPorColmeia(
        hiveId,
        limite: 20,
      );
      final history = dataRows
          .reversed
          .map(TelemetryModel.fromDatabase)
          .toList(growable: false);

      loadedHives.add(
        HiveModel.fromDatabase(
          row,
          telemetry: history.isEmpty ? null : history.last,
          telemetryHistory: history,
        ),
      );
    }

    if (_meliponicultorId != ownerId) return;

    _hives = loadedHives;
    if (_hives.isNotEmpty) {
      _selectedHiveId ??= _hives.first.id;
    }
    _isLoading = false;
    _startPeriodicSyncTimer();
    notifyListeners();
  }

  void selectHive(String id) {
    _selectedHiveId = id;
    notifyListeners();
  }

  Future<void> addHive({
    required String name,
    required String species,
    required String description,
    required String ipAddress,
    required TelemetryModel initialTelemetry,
    String wifiName = '',
    String wifiPassword = '',
    bool isOnline = true,
  }) async {
    await _loadFuture;
    final beekeeperId = _meliponicultorId;
    if (beekeeperId == null) return;
    final hiveId = await _hiveRepository.inserir(
      nome: name,
      meliponicultorId: beekeeperId,
      especieAbelha: species,
      ipAddress: ipAddress,
      nomeRedeWifi: wifiName,
      senhaRedeWifi: wifiPassword,
      dataCriacao: DateTime.now(),
    );
    await _dataRepository.inserir(
      colmeiaId: hiveId,
      temperatura: initialTelemetry.internalTemp,
      entrada: initialTelemetry.trafficIn,
      saida: initialTelemetry.trafficOut,
      dataInsercao: initialTelemetry.timestamp,
    );

    final newHive = HiveModel(
      id: hiveId.toString(),
      databaseId: hiveId,
      meliponicultorId: beekeeperId,
      name: name,
      species: species,
      description: description,
      ipAddress: ipAddress,
      wifiName: wifiName,
      wifiPassword: wifiPassword,
      isOnline: isOnline,
      telemetry: initialTelemetry,
      telemetryHistory: [initialTelemetry],
      createdAt: DateTime.now(),
    );

    _hives.insert(0, newHive);
    _selectedHiveId = newHive.id;
    notifyListeners();
  }

  Future<void> updateHive({
    required String hiveId,
    required String name,
    required String species,
  }) async {
    await _loadFuture;
    final index = _hives.indexWhere((hive) => hive.id == hiveId);
    if (index == -1) return;

    final hive = _hives[index];
    final databaseId = hive.databaseId ?? int.tryParse(hive.id);
    if (databaseId == null) return;

    await _hiveRepository.atualizar(
      id: databaseId,
      nome: name,
      especieAbelha: species,
      ipAddress: hive.ipAddress,
      nomeRedeWifi: hive.wifiName,
      senhaRedeWifi: hive.wifiPassword,
    );

    _hives[index] = hive.copyWith(
      name: name,
      species: species,
    );
    notifyListeners();
  }

  Future<Map<String, dynamic>> testEsp32Connection({
    String ip = '192.168.4.1',
    bool allowFallback = true,
  }) {
    return _esp32Service.testConnection(
      ipAddress: ip,
      allowSimulationFallback: allowFallback,
    );
  }

  Future<void> refreshHiveTelemetry(String hiveId) async {
    await _loadFuture;
    final index = _hives.indexWhere((h) => h.id == hiveId);
    if (index == -1) return;

    final hive = _hives[index];
    _isRefreshing = true;
    notifyListeners();

    try {
      final updatedTelemetry = await _esp32Service.fetchTelemetry(
        ipAddress: hive.ipAddress,
        currentBaseTemp: hive.telemetry.internalTemp,
      );

      final databaseId = hive.databaseId ?? int.tryParse(hive.id);
      if (databaseId != null) {
        await _dataRepository.inserir(
          colmeiaId: databaseId,
          temperatura: updatedTelemetry.internalTemp,
          entrada: updatedTelemetry.trafficIn,
          saida: updatedTelemetry.trafficOut,
          dataInsercao: updatedTelemetry.timestamp,
        );
      }

      final updatedHistory = List<TelemetryModel>.from(hive.telemetryHistory)
        ..add(updatedTelemetry);
      if (updatedHistory.length > 20) {
        updatedHistory.removeAt(0);
      }

      _hives[index] = hive.copyWith(
        telemetry: updatedTelemetry,
        telemetryHistory: updatedHistory,
        isOnline: true,
      );
    } catch (_) {
      _hives[index] = hive.copyWith(isOnline: false);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void toggleOnlineStatus(String hiveId) {
    final index = _hives.indexWhere((hive) => hive.id == hiveId);
    if (index != -1) {
      _hives[index] = _hives[index].copyWith(
        isOnline: !_hives[index].isOnline,
      );
      notifyListeners();
    }
  }

  void simulateTemperature(String hiveId, double newTemp) {
    final index = _hives.indexWhere((hive) => hive.id == hiveId);
    if (index == -1) return;

    final hive = _hives[index];
    final newTelemetry = hive.telemetry.copyWith(
      internalTemp: double.parse(newTemp.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );
    _hives[index] = hive.copyWith(telemetry: newTelemetry);
    notifyListeners();
  }

  void _startPeriodicSyncTimer() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final hive = selectedHive;
      if (hive != null && hive.isOnline) {
        unawaited(refreshHiveTelemetry(hive.id));
      }
    });
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}
