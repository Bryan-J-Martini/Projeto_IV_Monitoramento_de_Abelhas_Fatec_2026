class BeekeeperModel {
  final String name;
  final String meliponaryName;
  final String email;
  final String avatarId;
  final DateTime createdAt;
  final bool isRegistered;

  const BeekeeperModel({
    required this.name,
    required this.meliponaryName,
    required this.email,
    this.avatarId = 'avatar_jatai',
    required this.createdAt,
    this.isRegistered = true,
  });

  BeekeeperModel copyWith({
    String? name,
    String? meliponaryName,
    String? email,
    String? avatarId,
    DateTime? createdAt,
    bool? isRegistered,
  }) {
    return BeekeeperModel(
      name: name ?? this.name,
      meliponaryName: meliponaryName ?? this.meliponaryName,
      email: email ?? this.email,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt ?? this.createdAt,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  factory BeekeeperModel.initial() {
    return BeekeeperModel(
      name: 'Meliponicultor Guardião',
      meliponaryName: 'Meliponário Flor Nativa',
      email: 'guardiao@meliponario.eco.br',
      avatarId: 'avatar_jatai',
      createdAt: DateTime.now(),
      isRegistered: true,
    );
  }

  factory BeekeeperModel.fromJson(Map<String, dynamic> json) {
    return BeekeeperModel(
      name: json['name'] as String? ?? 'Criador',
      meliponaryName: json['meliponary_name'] as String? ?? 'Meu Meliponário',
      email: json['email'] as String? ?? '',
      avatarId: json['avatar_id'] as String? ?? 'avatar_jatai',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRegistered: json['is_registered'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'meliponary_name': meliponaryName,
      'email': email,
      'avatar_id': avatarId,
      'created_at': createdAt.toIso8601String(),
      'is_registered': isRegistered,
    };
  }
}

