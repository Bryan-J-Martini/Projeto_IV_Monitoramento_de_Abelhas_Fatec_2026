import 'package:flutter/material.dart';

import 'edit_profile_view.dart';

/// Compatibilidade com chamadas antigas: a tela oficial de perfil agora é a
/// mesma tela de edição usada pelo botão de perfil da tela inicial.
class BeekeeperSetupView extends StatelessWidget {
  final bool isInitialOnboarding;

  const BeekeeperSetupView({
    super.key,
    this.isInitialOnboarding = false,
  });

  @override
  Widget build(BuildContext context) => const EditProfileView();
}
