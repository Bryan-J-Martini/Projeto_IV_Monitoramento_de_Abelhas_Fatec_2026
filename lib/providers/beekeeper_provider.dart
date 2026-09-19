import 'package:flutter/foundation.dart';
import '../models/beekeeper_model.dart';
import '../services/storage_service.dart';

class BeekeeperProvider extends ChangeNotifier {
  BeekeeperModel _beekeeper = StorageService.getInitialBeekeeper();

  BeekeeperModel get beekeeper => _beekeeper;

  void updateProfile({
    required String name,
    required String meliponaryName,
    String address = '',
    required String email,
    String avatarId = 'avatar_jatai',
  }) {
    _beekeeper = _beekeeper.copyWith(
      name: name,
      meliponaryName: meliponaryName,
      address: address,
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
