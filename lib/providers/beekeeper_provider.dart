import 'package:flutter/foundation.dart';
import '../models/beekeeper_model.dart';
import '../services/storage_service.dart';

class BeekeeperProvider extends ChangeNotifier {
  BeekeeperModel _beekeeper = StorageService.getInitialBeekeeper();

  BeekeeperModel get beekeeper => _beekeeper;

  void updateProfile({
    required String name,
    required String meliponaryName,
    required String email,
    required String avatarId,
  }) {
    _beekeeper = _beekeeper.copyWith(
      name: name,
      meliponaryName: meliponaryName,
      email: email,
      avatarId: avatarId,
      isRegistered: true,
    );
    notifyListeners();
  }

  void selectAvatar(String avatarId) {
    _beekeeper = _beekeeper.copyWith(avatarId: avatarId);
    notifyListeners();
  }
}

