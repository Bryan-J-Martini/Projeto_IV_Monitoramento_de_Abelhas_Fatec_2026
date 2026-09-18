class TelemetryModel {
  final double internalTemp;
  final int trafficIn;
  final int trafficOut;
  final double externalTemp;
  final double externalHumidity;
  final DateTime timestamp;

  const TelemetryModel({
    required this.internalTemp,
    required this.trafficIn,
    required this.trafficOut,
    required this.externalTemp,
    required this.externalHumidity,
    required this.timestamp,
  });

  bool get isThermallyIdeal => internalTemp >= 28.0 && internalTemp <= 32.0;

  bool get isTooCold => internalTemp < 28.0;

  bool get isTooHot => internalTemp > 32.0;

  int get totalTraffic => trafficIn + trafficOut;

  int get netTraffic => trafficIn - trafficOut;

  String get thermalStatusText {
    if (isThermallyIdeal) {
      return 'Ideal (28°C – 32°C) • Enxame Confortável';
    } else if (isTooCold) {
      return 'Baixa Temp (< 28°C) • Risco de Resfriamento';
    } else {
      return 'Alta Temp (> 32°C) • Risco de Superaquecimento';
    }
  }

  String get beeMood {
    if (isThermallyIdeal) return 'happy';
    if (isTooCold) return 'cold';
    return 'hot';
  }

  int get swarmHealthScore {
    int score = 100;
    // Penalidade por desvio de temperatura
    if (internalTemp < 28.0) {
      score -= ((28.0 - internalTemp) * 8).round().clamp(0, 40);
    } else if (internalTemp > 32.0) {
      score -= ((internalTemp - 32.0) * 10).round().clamp(0, 40);
    }

    // Avaliação do tráfego
    if (totalTraffic < 10) {
      score -= 20; // Tráfego baixo / pouca atividade
    } else if (totalTraffic > 40) {
      score += 5; // Enxame muito ativo
    }

    return score.clamp(15, 100);
  }

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      internalTemp: (json['internal_temp'] ?? json['internalTemp'] ?? 28.5)
          .toDouble(),
      trafficIn: (json['traffic_in'] ?? json['trafficIn'] ?? 32).toInt(),
      trafficOut: (json['traffic_out'] ?? json['trafficOut'] ?? 28).toInt(),
      externalTemp: (json['external_temp'] ?? json['externalTemp'] ?? 27.2)
          .toDouble(),
      externalHumidity:
          (json['external_humidity'] ?? json['externalHumidity'] ?? 65.0)
              .toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'internal_temp': internalTemp,
      'traffic_in': trafficIn,
      'traffic_out': trafficOut,
      'external_temp': externalTemp,
      'external_humidity': externalHumidity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TelemetryModel copyWith({
    double? internalTemp,
    int? trafficIn,
    int? trafficOut,
    double? externalTemp,
    double? externalHumidity,
    DateTime? timestamp,
  }) {
    return TelemetryModel(
      internalTemp: internalTemp ?? this.internalTemp,
      trafficIn: trafficIn ?? this.trafficIn,
      trafficOut: trafficOut ?? this.trafficOut,
      externalTemp: externalTemp ?? this.externalTemp,
      externalHumidity: externalHumidity ?? this.externalHumidity,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
