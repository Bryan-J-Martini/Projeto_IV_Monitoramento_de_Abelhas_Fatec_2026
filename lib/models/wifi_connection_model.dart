class WifiConnectionInfo {
  final bool isWifi;
  final String? ssid;
  final String? ipAddress;

  const WifiConnectionInfo({required this.isWifi, this.ssid, this.ipAddress});

  bool matchesSsid(String expectedSsid) {
    final expected = _normalizeSsid(expectedSsid);
    final current = _normalizeSsid(ssid);

    // Alguns sistemas bloqueiam a leitura do SSID. Nesse caso, a conexão
    // HTTP com o IP do ESP32 continua sendo a confirmação definitiva.
    if (expected.isEmpty || current.isEmpty) return true;
    return expected == current;
  }

  static String _normalizeSsid(String? value) {
    if (value == null) return '';
    final normalized = value.trim().replaceAll(RegExp(r'^"|"$'), '');
    if (normalized.isEmpty || normalized == '<unknown ssid>') return '';
    return normalized;
  }
}
