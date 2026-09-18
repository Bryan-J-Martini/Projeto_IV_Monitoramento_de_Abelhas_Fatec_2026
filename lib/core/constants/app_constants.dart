class AppConstants {
  // Configurações padrão SoftAP ESP32
  static const String defaultEsp32Ip = '192.168.4.1';
  static const String telemetryEndpoint = 'http://$defaultEsp32Ip/telemetry';
  static const String mjpegStreamEndpoint = 'http://$defaultEsp32Ip/stream';
  static const String snapshotEndpoint = 'http://$defaultEsp32Ip/capture';
  static const String defaultSsidPrefix = 'Abelha_Node_';

  // Limiares Biológicos de Temperatura Interna (°C)
  static const double minIdealTemp = 26.0;
  static const double maxIdealTemp = 32.0;
  static const double criticalColdTemp = 22.0;
  static const double criticalHotTemp = 35.0;

  // Lista de espécies de abelhas nativas sem ferrão (Meliponíneos)
  static const List<String> stinglessBeeSpecies = [
    'Jataí (Tetragonisca angustula)',
    'Mandaçaia (Melipona quadrifasciata)',
    'Uruçu Amarela (Melipona flavolineata)',
    'Tiúba (Melipona compressipes)',
    'Iraí (Nannotrigona testaceicornis)',
    'Mirim Droriana (Plebeia droryana)',
    'Borá (Tetragona clavipes)',
    'Marmelada (Frieseomelitta varia)',
  ];

  // Avatares ilustrativos disponíveis para o criador
  static const List<Map<String, String>> beeAvatars = [
    {
      'id': 'avatar_jatai',
      'name': 'Jataí Dourada',
      'species': 'Tetragonisca angustula',
      'tag': 'Pequena & Valente',
    },
    {
      'id': 'avatar_mandacaia',
      'name': 'Mandaçaia Nobre',
      'species': 'Melipona quadrifasciata',
      'tag': 'Robusta & Dócil',
    },
    {
      'id': 'avatar_urucu',
      'name': 'Uruçu Rainha',
      'species': 'Melipona scutellaris',
      'tag': 'Grande & Produtiva',
    },
    {
      'id': 'avatar_tiuba',
      'name': 'Tiúba Protetora',
      'species': 'Melipona compressipes',
      'tag': 'Resistente & Rápida',
    },
    {
      'id': 'avatar_irai',
      'name': 'Iraí Brincalhona',
      'species': 'Nannotrigona testaceicornis',
      'tag': 'Pequena & Tranquila',
    },
  ];
}

