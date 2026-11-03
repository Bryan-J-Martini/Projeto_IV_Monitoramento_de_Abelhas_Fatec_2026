import 'dart:convert';
import 'package:http/http.dart' as http;

class PythonServerService {
  final http.Client _client;

  PythonServerService({http.Client? client}) : _client = client ?? http.Client();

  /// Consulta o tráfego mais recente da colmeia no servidor Python local (FastAPI)
  Future fetchLatestTraffic(String serverIp, String hiveId) async {
    final uri = Uri.parse('http://$serverIp:8000/api/v1/hives/$hiveId/traffic/latest');
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map;
      }
    } catch (e) {
      print('Erro ao ligar ao servidor Python: $e');
    }
    return null;
  }
}