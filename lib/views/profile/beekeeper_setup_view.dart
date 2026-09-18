import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/beekeeper_provider.dart';
import '../../widgets/bee_mascot_widget.dart';
import '../../widgets/glass_container.dart';

class BeekeeperSetupView extends StatefulWidget {
  final bool isInitialOnboarding;

  const BeekeeperSetupView({
    super.key,
    this.isInitialOnboarding = false,
  });

  @override
  State<BeekeeperSetupView> createState() => _BeekeeperSetupViewState();
}

class _BeekeeperSetupViewState extends State<BeekeeperSetupView> {
  late TextEditingController _nameController;
  late TextEditingController _meliponaryController;
  late TextEditingController _emailController;
  String _selectedAvatarId = 'avatar_jatai';

  @override
  void initState() {
    super.initState();
    final beekeeper =
        Provider.of<BeekeeperProvider>(context, listen: false).beekeeper;
    _nameController = TextEditingController(text: beekeeper.name);
    _meliponaryController =
        TextEditingController(text: beekeeper.meliponaryName);
    _emailController = TextEditingController(text: beekeeper.email);
    _selectedAvatarId = beekeeper.avatarId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _meliponaryController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_nameController.text.trim().isEmpty) {
      _showWarningDialog('Por favor, informe seu nome.');
      return;
    }

    final provider = Provider.of<BeekeeperProvider>(context, listen: false);
    provider.updateProfile(
      name: _nameController.text.trim(),
      meliponaryName: _meliponaryController.text.trim().isEmpty
          ? 'Meu Meliponário'
          : _meliponaryController.text.trim(),
      email: _emailController.text.trim(),
      avatarId: _selectedAvatarId,
    );

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(CupertinoIcons.checkmark_alt_circle_fill, color: Colors.white),
            SizedBox(width: 8),
            Text('Perfil do Meliponicultor salvo com sucesso!'),
          ],
        ),
        backgroundColor: AppColors.lakeBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showWarningDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Atenção'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBg,
      appBar: AppBar(
        title: const Text('Perfil do Criador'),
        leading: widget.isInitialOnboarding
            ? null
            : IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho amigável com mascote de abelha
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.skyBlue,
                            border: Border.all(
                              color: AppColors.lakeBlue.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                        const BeeMascotWidget(
                          size: 78,
                          internalTemp: 29.0, // Sempre feliz no perfil
                          showSpeechBubble: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Meliponicultura Sustentável',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Guardião das Abelhas Nativas Sem Ferrão',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Seletor de Avatar de Abelhas
              const Text(
                'SELECIONE SEU AVATAR DE ABELHA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConstants.beeAvatars.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = AppConstants.beeAvatars[index];
                    final isSelected = item['id'] == _selectedAvatarId;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAvatarId = item['id']!;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 130,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.skyBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.lakeBlue
                                : AppColors.borderLight,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isSelected ? '🐝' : '🌸',
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppColors.lakeBlue
                                    : AppColors.ink,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item['tag']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.slate,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // Formulário Agrupado Cupertino / iOS
              const Text(
                'DADOS DO CRIADOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.mute,
                ),
              ),
              const SizedBox(height: 8),

              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _buildInputField(
                      icon: CupertinoIcons.person_fill,
                      label: 'Nome do Criador',
                      placeholder: 'Ex: Carlos Silva',
                      controller: _nameController,
                    ),
                    const Divider(height: 1, indent: 48, color: AppColors.divider),
                    _buildInputField(
                      icon: CupertinoIcons.map_pin_ellipse,
                      label: 'Local / Meliponário',
                      placeholder: 'Ex: Meliponário Flor da Serra',
                      controller: _meliponaryController,
                    ),
                    const Divider(height: 1, indent: 48, color: AppColors.divider),
                    _buildInputField(
                      icon: CupertinoIcons.mail_solid,
                      label: 'E-mail para Alertas',
                      placeholder: 'Ex: criador@meliponario.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Botão Principal no estilo Apple (Lake Blue CTA)
              CupertinoButton(
                color: AppColors.lakeBlue,
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _saveProfile,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.checkmark_alt, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Salvar Informações',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required String placeholder,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.lakeBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mute,
                  ),
                ),
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      fontSize: 15,
                      color: AppColors.mute,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
