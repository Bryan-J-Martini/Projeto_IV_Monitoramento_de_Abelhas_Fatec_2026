import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/wifi_connection_model.dart';

class WifiConnectionService {
  final Connectivity _connectivity;
  final NetworkInfo _networkInfo;
  bool _permissionWasRequested = false;

  WifiConnectionService({Connectivity? connectivity, NetworkInfo? networkInfo})
    : _connectivity = connectivity ?? Connectivity(),
      _networkInfo = networkInfo ?? NetworkInfo();

  Future<WifiConnectionInfo> currentConnection() async {
    await _requestLocationPermission();

    List<ConnectivityResult> connectionTypes = const [];
    try {
      connectionTypes = await _connectivity.checkConnectivity();
    } catch (_) {
      // Em testes ou plataformas sem implementação nativa, o IP/SSID pode
      // continuar indisponível, mas o aplicativo ainda pode testar o ESP32.
    }
    final isWifi = connectionTypes.contains(ConnectivityResult.wifi);

    String? ssid;
    String? ipAddress;
    try {
      ssid = await _networkInfo.getWifiName();
      ipAddress = await _networkInfo.getWifiIP();
    } catch (_) {
      // A leitura do SSID pode ser bloqueada pelo sistema operacional.
      // O teste HTTP do ESP32 continua sendo a validação principal.
    }

    return WifiConnectionInfo(isWifi: isWifi, ssid: ssid, ipAddress: ipAddress);
  }

  Future<void> _requestLocationPermission() async {
    // Android exige essa permissão para liberar o SSID do Wi-Fi atual.
    // Se o usuário negar, ainda tentaremos acessar o ESP32 pelo IP salvo.
    if (_permissionWasRequested) return;
    _permissionWasRequested = true;

    try {
      final permission = await Permission.locationWhenInUse.status;
      if (!permission.isGranted && !permission.isPermanentlyDenied) {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {
      // Permissões não disponíveis em algumas plataformas, como desktop/web.
    }
  }
}
