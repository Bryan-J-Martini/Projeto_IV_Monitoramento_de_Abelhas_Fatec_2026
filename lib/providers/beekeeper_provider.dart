import 'dart:async';

import 'package:flutter/foundation.dart';
import '../data/local/local_data_initializer.dart';
import '../models/beekeeper_model.dart';
import '../repositories/meliponicultor_repository.dart';
import '../services/password_service.dart';

class BeekeeperProvider extends ChangeNotifier {
  final MeliponicultorRepository _repository;
  late final Future<void> _loadFuture;
  BeekeeperModel _beekeeper = BeekeeperModel.initial();
  bool _isLoading = true;

  BeekeeperProvider({MeliponicultorRepository? repository})
      : _repository = repository ?? MeliponicultorRepository() {
    _loadFuture = _loadFromDatabase();
    unawaited(_loadFuture);
  }

  BeekeeperModel get beekeeper => _beekeeper;
  bool get isLoading => _isLoading;

  Future<void> _loadFromDatabase() async {
    await LocalDataInitializer.instance.ensureInitialized();
    final rows = await _repository.listar();

    if (rows.isNotEmpty) {
      _beekeeper = BeekeeperModel.fromDatabase(rows.first);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String meliponaryName,
    String address = '',
    required String email,
    String avatarId = 'avatar_jatai',
    String? password,
  }) async {
    await _loadFuture;

    final passwordHash = password != null && password.trim().isNotEmpty
        ? PasswordService.hash(password)
        : (_beekeeper.passwordHash.isEmpty
            ? PasswordService.hash('')
            : _beekeeper.passwordHash);

    final id = _beekeeper.databaseId ??
        await _repository.inserir(
          nome: name,
          email: email,
          senhaHash: passwordHash,
          endereco: address,
          nomeMeliponicultura: meliponaryName,
        );

    if (_beekeeper.databaseId != null) {
      await _repository.atualizar(
        id: id,
        nome: name,
        email: email,
        endereco: address,
        nomeMeliponicultura: meliponaryName,
        senhaHash: password != null && password.trim().isNotEmpty
            ? passwordHash
            : null,
      );
    }

    _beekeeper = _beekeeper.copyWith(
      databaseId: id,
      name: name,
      meliponaryName: meliponaryName,
      address: address,
      email: email,
      passwordHash: passwordHash,
      avatarId: avatarId,
      isRegistered: true,
    );
    notifyListeners();
  }

  Future<bool> authenticate({
    required String email,
    required String password,
  }) async {
    await _loadFuture;

    final row = await _repository.buscarPorEmail(email.trim());
    if (row == null) return false;

    final storedHash = row['senha_hash'] as String?;
    final passwordHash = PasswordService.hash(password);
    if (storedHash == null || storedHash != passwordHash) return false;

    _beekeeper = BeekeeperModel.fromDatabase(row);
    notifyListeners();
    return true;
  }

  void selectAvatar(String avatarId) {
    _beekeeper = _beekeeper.copyWith(avatarId: avatarId);
    notifyListeners();
  }
}
