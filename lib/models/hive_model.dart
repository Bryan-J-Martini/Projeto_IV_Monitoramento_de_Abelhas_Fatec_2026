import 'telemetry_model.dart';

class HiveModel {
  final String id;
  final String name;
  final String species;
  final String description;
  final String ipAddress;
  final bool isOnline;
  final TelemetryModel telemetry;
  final List<TelemetryModel> telemetryHistory;
  final List<String> galleryPhotos;
  final DateTime createdAt;

  const HiveModel({
    required this.id,
    required this.name,
    required this.species,
    required this.description,
    this.ipAddress = '192.168.4.1',
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
    String? name,
    String? species,
    String? description,
    String? ipAddress,
    bool? isOnline,
    TelemetryModel? telemetry,
    List<TelemetryModel>? telemetryHistory,
    List<String>? galleryPhotos,
    DateTime? createdAt,
  }) {
    return HiveModel(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      isOnline: isOnline ?? this.isOnline,
      telemetry: telemetry ?? this.telemetry,
      telemetryHistory: telemetryHistory ?? this.telemetryHistory,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory HiveModel.fromJson(Map<String, dynamic> json) {
    return HiveModel(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      description: json['description'] as String? ?? '',
      ipAddress: json['ip_address'] as String? ?? '192.168.4.1',
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
      'name': name,
      'species': species,
      'description': description,
      'ip_address': ipAddress,
      'is_online': isOnline,
      'telemetry': telemetry.toJson(),
      'telemetry_history': telemetryHistory.map((e) => e.toJson()).toList(),
      'gallery_photos': galleryPhotos,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

