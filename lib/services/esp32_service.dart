import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/telemetry_model.dart';

class Esp32Service {
  final http.Client _client;

  Esp32Service({http.Client? client}) : _client = client ?? http.Client();

  /// Testa a conexão real com o ESP32 na rota SoftAP http://192.168.4.1/telemetry
  /// Se a conexão falhar ou o dispositivo não estiver no SoftAP, pode simular caso solicitado.
  Future<Map<String, dynamic>> testConnection({
    String ipAddress = AppConstants.defaultEsp32Ip,
    bool allowSimulationFallback = true,
  }) async {
    final uri = Uri.parse('http://$ipAddress/telemetry');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'isRealHardware': true,
          'message': 'ESP32 SoftAP conectado com sucesso!',
          'telemetry': TelemetryModel.fromJson(decoded),
        };
      } else {
        throw Exception('Status HTTP: ${response.statusCode}');
      }
    } catch (e) {
      if (allowSimulationFallback) {
        // Fallback para desenvolvimento e testes práticos de UI/UX
        await Future.delayed(const Duration(milliseconds: 1200));
        final mockTelemetry = generateMockTelemetry(baseTemp: 28.4);
        return {
          'success': true,
          'isRealHardware': false,
          'message':
              'ESP32 Simulado Conectado (Modo Demonstração). Configure o Wi-Fi para o ESP32 real em campo.',
          'telemetry': mockTelemetry,
        };
      }
      return {
        'success': false,
        'isRealHardware': false,
        'message': 'Não foi possível alcançar $uri: $e',
        'telemetry': null,
      };
    }
  }

  /// Busca telemetria atualizada
  Future<TelemetryModel> fetchTelemetry({
    String ipAddress = AppConstants.defaultEsp32Ip,
    double currentBaseTemp = 28.4,
  }) async {
    final uri = Uri.parse('http://$ipAddress/telemetry');
    try {
      final response = await _client.get(uri).timeout(
        const Duration(seconds: 2),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return TelemetryModel.fromJson(decoded);
      }
    } catch (_) {
      // Falha de rede ou modo offline
    }
    // Retorna telemetria com pequena variação biológica realista
    return generateMockTelemetry(baseTemp: currentBaseTemp);
  }

  /// Gera dados de telemetria biológica com pequenas oscilações realistas
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

