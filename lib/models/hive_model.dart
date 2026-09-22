import 'telemetry_model.dart';

class HiveModel {
  final String id;
  final int? databaseId;
  final int? meliponicultorId;
  final String name;
  final String species;
  final String description;
  final String ipAddress;
  final String wifiName;
  final String wifiPassword;
  final bool isOnline;
  final TelemetryModel telemetry;
  final List<TelemetryModel> telemetryHistory;
  final List<String> galleryPhotos;
  final DateTime createdAt;

  const HiveModel({
    required this.id,
    this.databaseId,
    this.meliponicultorId,
    required this.name,
    required this.species,
    required this.description,
    this.ipAddress = '192.168.4.1',
    this.wifiName = '',
    this.wifiPassword = '',
    this.isOnline = true,
    required this.telemetry,
    this.telemetryHistory = const [],
    this.galleryPhotos = const [],
    required this.createdAt,
  });

  String get shortSpecies {
    final parenIndex = species.indexOf('(');
    if (parenIndex != -1) {
      return species.substring(0, parenIndex).trim();
    }
    return species;
  }

  String get scientificName {
    final start = species.indexOf('(');
    final end = species.indexOf(')');
    if (start != -1 && end != -1 && end > start) {
      return species.substring(start + 1, end);
    }
    return species;
  }

  HiveModel copyWith({
    String? id,
    int? databaseId,
    int? meliponicultorId,
    String? name,
    String? species,
    String? description,
    String? ipAddress,
    String? wifiName,
    String? wifiPassword,
    bool? isOnline,
    TelemetryModel? telemetry,
    List<TelemetryModel>? telemetryHistory,
    List<String>? galleryPhotos,
    DateTime? createdAt,
  }) {
    return HiveModel(
      id: id ?? this.id,
      databaseId: databaseId ?? this.databaseId,
      meliponicultorId: meliponicultorId ?? this.meliponicultorId,
      name: name ?? this.name,
      species: species ?? this.species,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      wifiName: wifiName ?? this.wifiName,
      wifiPassword: wifiPassword ?? this.wifiPassword,
      isOnline: isOnline ?? this.isOnline,
      telemetry: telemetry ?? this.telemetry,
      telemetryHistory: telemetryHistory ?? this.telemetryHistory,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HiveModel.fromDatabase(
    Map<String, dynamic> row, {
    TelemetryModel? telemetry,
    List<TelemetryModel> telemetryHistory = const [],
  }) {
    final rawId = row['id'];
    final databaseId = rawId is num ? rawId.toInt() : int.tryParse('$rawId');
    final currentTelemetry = telemetry ??
        TelemetryModel(
          internalTemp: 0,
          trafficIn: 0,
          trafficOut: 0,
          externalTemp: 0,
          externalHumidity: 0,
          timestamp: DateTime.tryParse(row['data_criacao'] as String? ?? '') ??
              DateTime.now(),
        );

    return HiveModel(
      id: databaseId?.toString() ?? '$rawId',
      databaseId: databaseId,
      meliponicultorId: (row['meliponicultor_id'] as num?)?.toInt(),
      name: row['nome'] as String? ?? 'Colmeia',
      species: row['especie_abelha'] as String? ?? 'Abelha sem especie',
      description: row['descricao'] as String? ?? '',
      ipAddress: row['ip_address'] as String? ?? '192.168.4.1',
      wifiName: row['nome_rede_wifi'] as String? ?? '',
      wifiPassword: row['senha_rede_wifi'] as String? ?? '',
      isOnline: true,
      telemetry: currentTelemetry,
      telemetryHistory: telemetryHistory,
      createdAt: DateTime.tryParse(row['data_criacao'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory HiveModel.fromJson(Map<String, dynamic> json) {
    return HiveModel(
      id: json['id'].toString(),
      databaseId: (json['database_id'] as num?)?.toInt(),
      meliponicultorId: (json['meliponicultor_id'] as num?)?.toInt(),
      name: json['name'] as String,
      species: json['species'] as String,
      description: json['description'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? '192.168.4.1',
      wifiName: json['wifi_name'] as String? ?? '',
      wifiPassword: json['wifi_password'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? false,
      telemetry: TelemetryModel.fromJson(
        json['telemetry'] as Map<String, dynamic>,
      ),
      telemetryHistory: (json['telemetry_history'] as List<dynamic>?)
              ?.map((e) => TelemetryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      galleryPhotos: (json['gallery_photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'database_id': databaseId,
      'meliponicultor_id': meliponicultorId,
      'name': name,
      'species': species,
      'description': description,
      'ip_address': ipAddress,
      'wifi_name': wifiName,
      'wifi_password': wifiPassword,
      'is_online': isOnline,
      'telemetry': telemetry.toJson(),
      'telemetry_history': telemetryHistory.map((e) => e.toJson()).toList(),
      'gallery_photos': galleryPhotos,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
