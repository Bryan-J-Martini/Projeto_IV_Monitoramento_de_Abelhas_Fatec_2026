import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hive_model.dart';
import '../models/telemetry_model.dart';
import '../services/esp32_service.dart';
import '../services/storage_service.dart';

class HiveProvider extends ChangeNotifier {
  final Esp32Service _esp32Service;
  List<HiveModel> _hives = [];
  String? _selectedHiveId;
  bool _isRefreshing = false;
  Timer? _periodicSyncTimer;

  HiveProvider({Esp32Service? esp32Service})
      : _esp32Service = esp32Service ?? Esp32Service() {
    _hives = StorageService.getInitialHives();
    if (_hives.isNotEmpty) {
      _selectedHiveId = _hives.first.id;
    }
    _startPeriodicSync();
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

  void selectHive(String id) {
    _selectedHiveId = id;
    notifyListeners();
  }

  /// Adiciona uma nova colmeia após provisionamento do SoftAP ESP32
  void addHive({
    required String name,
    required String species,
    required String description,
    required String ipAddress,
    required TelemetryModel initialTelemetry,
    bool isOnline = true,
  }) {
    final newHive = HiveModel(
      id: 'hive_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      species: species,
      description: description,
      ipAddress: ipAddress,
      isOnline: isOnline,
      telemetry: initialTelemetry,
      telemetryHistory: [initialTelemetry],
      galleryPhotos: [
        'alvado_novo_enxame',
      ],
      createdAt: DateTime.now(),
    );

    _hives.insert(0, newHive);
    _selectedHiveId = newHive.id;
    notifyListeners();
  }

  /// Atualiza os dados de identificação de uma colmeia existente.
  void updateHive({
    required String hiveId,
    required String name,
    required String species,
  }) {
    final index = _hives.indexWhere((hive) => hive.id == hiveId);
    if (index == -1) return;

    _hives[index] = _hives[index].copyWith(
      name: name,
      species: species,
    );
    notifyListeners();
  }

  /// Testa conexão com rota http://192.168.4.1/telemetry
  Future<Map<String, dynamic>> testEsp32Connection({
    String ip = '192.168.4.1',
    bool allowFallback = true,
  }) async {
    return await _esp32Service.testConnection(
      ipAddress: ip,
      allowSimulationFallback: allowFallback,
    );
  }

  /// Atualiza a telemetria de uma colmeia específica
  Future<void> refreshHiveTelemetry(String hiveId) async {
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
      // Se falhar a comunicação
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Alterna o status online/offline para testes
  void toggleOnlineStatus(String hiveId) {
    final index = _hives.indexWhere((h) => h.id == hiveId);
    if (index != -1) {
      _hives[index] = _hives[index].copyWith(
        isOnline: !_hives[index].isOnline,
      );
      notifyListeners();
    }
  }

  /// Permite ao usuário simular diferentes faixas de temperatura para ver a reação do mascote!
  void simulateTemperature(String hiveId, double newTemp) {
    final index = _hives.indexWhere((h) => h.id == hiveId);
    if (index != -1) {
      final hive = _hives[index];
      final newTelemetry = hive.telemetry.copyWith(
        internalTemp: double.parse(newTemp.toStringAsFixed(1)),
        timestamp: DateTime.now(),
      );
      _hives[index] = hive.copyWith(telemetry: newTelemetry);
      notifyListeners();
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_selectedHiveId != null) {
        final hive = selectedHive;
        if (hive != null && hive.isOnline) {
          refreshHiveTelemetry(hive.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}
