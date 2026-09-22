class BeekeeperModel {
  final int? databaseId;
  final String name;
  final String meliponaryName;
  final String address;
  final String email;
  final String passwordHash;
  final String avatarId;
  final DateTime createdAt;
  final bool isRegistered;

  const BeekeeperModel({
    this.databaseId,
    required this.name,
    required this.meliponaryName,
    this.address = '',
    required this.email,
    this.passwordHash = '',
    this.avatarId = 'avatar_jatai',
    required this.createdAt,
    this.isRegistered = true,
  });

  BeekeeperModel copyWith({
    int? databaseId,
    String? name,
    String? meliponaryName,
    String? address,
    String? email,
    String? passwordHash,
    String? avatarId,
    DateTime? createdAt,
    bool? isRegistered,
  }) {
    return BeekeeperModel(
      databaseId: databaseId ?? this.databaseId,
      name: name ?? this.name,
      meliponaryName: meliponaryName ?? this.meliponaryName,
      address: address ?? this.address,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt ?? this.createdAt,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  factory BeekeeperModel.initial() {
    return BeekeeperModel(
      name: 'Meliponicultor Guardiao',
      meliponaryName: 'Meliponario Flor Nativa',
      email: 'guardiao@meliponario.eco.br',
      createdAt: DateTime.now(),
      isRegistered: true,
    );
  }

  factory BeekeeperModel.fromDatabase(Map<String, dynamic> row) {
    return BeekeeperModel(
      databaseId: row['id'] as int?,
      name: row['nome'] as String? ?? 'Criador',
      meliponaryName:
          row['nome_meliponicultura'] as String? ?? 'Meu meliponario',
      address: row['endereco'] as String? ?? '',
      email: row['email'] as String? ?? '',
      passwordHash: row['senha_hash'] as String? ?? '',
      createdAt: DateTime.now(),
    );
  }

  factory BeekeeperModel.fromJson(Map<String, dynamic> json) {
    return BeekeeperModel(
      databaseId: (json['id'] as num?)?.toInt(),
      name: json['name'] as String? ?? 'Criador',
      meliponaryName:
          json['meliponary_name'] as String? ?? 'Meu meliponario',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      passwordHash: json['password_hash'] as String? ?? '',
      avatarId: json['avatar_id'] as String? ?? 'avatar_jatai',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRegistered: json['is_registered'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': databaseId,
      'name': name,
      'meliponary_name': meliponaryName,
      'address': address,
      'email': email,
      'avatar_id': avatarId,
      'created_at': createdAt.toIso8601String(),
      'is_registered': isRegistered,
    };
  }
}
