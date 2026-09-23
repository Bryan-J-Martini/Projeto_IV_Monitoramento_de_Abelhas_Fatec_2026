import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/telemetry_model.dart';
import 'wifi_connection_service.dart';

class Esp32ConnectionException implements Exception {
  final String message;

  const Esp32ConnectionException(this.message);

  @override
  String toString() => message;
}

class Esp32Service {
  final http.Client _client;
  final WifiConnectionService _wifiService;

  Esp32Service({http.Client? client, WifiConnectionService? wifiService})
    : _client = client ?? http.Client(),
      _wifiService = wifiService ?? WifiConnectionService();

  Future<Map<String, dynamic>> testConnection({
    String ipAddress = AppConstants.defaultEsp32Ip,
    String expectedWifiName = '',
    bool allowSimulationFallback = false,
  }) async {
    final uri = Uri.parse('http://$ipAddress/telemetry');

    try {
      final wifi = await _wifiService.currentConnection();
      if (!wifi.matchesSsid(expectedWifiName)) {
        return {
          'success': false,
          'isRealHardware': false,
          'message':
              'O celular está conectado à rede "${wifi.ssid ?? 'desconhecida'}", '
              'mas esta colmeia usa "$expectedWifiName".',
          'telemetry': null,
        };
      }

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isRealHardware': true,
          'message': 'ESP32 conectado com sucesso!',
          'telemetry': TelemetryModel.fromJson(decoded),
        };
      }

      throw Esp32ConnectionException(
        'O ESP32 respondeu com HTTP ${response.statusCode}.',
      );
    } catch (error) {
      if (allowSimulationFallback) {
        return {
          'success': true,
          'isRealHardware': false,
          'message': 'ESP32 simulado conectado.',
          'telemetry': generateMockTelemetry(baseTemp: 28.4),
        };
      }

      return {
        'success': false,
        'isRealHardware': false,
        'message': error is Esp32ConnectionException
            ? error.message
            : 'Não foi possível acessar $uri. Verifique o Wi-Fi e o IP.',
        'telemetry': null,
      };
    }
  }

  Future<TelemetryModel> fetchTelemetry({
    String ipAddress = AppConstants.defaultEsp32Ip,
    String expectedWifiName = '',
    double currentBaseTemp = 28.4,
    bool allowSimulationFallback = false,
  }) async {
    final uri = Uri.parse('http://$ipAddress/telemetry');

    try {
      final wifi = await _wifiService.currentConnection();
      if (!wifi.matchesSsid(expectedWifiName)) {
        throw const Esp32ConnectionException(
          'O celular está conectado a outra rede Wi-Fi.',
        );
      }

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return TelemetryModel.fromJson(decoded);
      }

      throw Esp32ConnectionException(
        'O ESP32 respondeu com HTTP ${response.statusCode}.',
      );
    } catch (error) {
      if (allowSimulationFallback) {
        return generateMockTelemetry(baseTemp: currentBaseTemp);
      }

      if (error is Esp32ConnectionException) rethrow;
      throw const Esp32ConnectionException(
        'Não foi possível acessar o ESP32. Verifique o Wi-Fi e o endereço IP.',
      );
    }
  }

  static TelemetryModel generateMockTelemetry({
    double baseTemp = 28.6,
    bool simulateCold = false,
    bool simulateHeat = false,
  }) {
    final random = Random();
    double temp = baseTemp + (random.nextDouble() * 0.4 - 0.2);

    if (simulateCold) {
      temp = 23.5 + random.nextDouble() * 1.5;
    } else if (simulateHeat) {
      temp = 34.0 + random.nextDouble() * 1.8;
    }

    final trafficIn = 25 + random.nextInt(25);
    final trafficOut = 20 + random.nextInt(22);
    final extTemp = 26.5 + (random.nextDouble() * 2.0 - 1.0);
    final extHumidity = 62.0 + (random.nextDouble() * 8.0 - 4.0);

    return TelemetryModel(
      internalTemp: double.parse(temp.toStringAsFixed(1)),
      trafficIn: trafficIn,
      trafficOut: trafficOut,
      externalTemp: double.parse(extTemp.toStringAsFixed(1)),
      externalHumidity: double.parse(extHumidity.toStringAsFixed(1)),
      timestamp: DateTime.now(),
    );
  }
}
