import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/beekeeper_provider.dart';
import '../../widgets/honeycomb_background.dart';
import '../../widgets/reference_profile_form.dart';

/// Edição do perfil acessada pela tela inicial. Mantém o desenho do cadastro,
/// mas possui navegação de volta e o botão Salvar.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _meliponaryController;
  late final TextEditingController _addressController;
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final beekeeper = context.read<BeekeeperProvider>().beekeeper;
    _nameController = TextEditingController(text: beekeeper.name);
    _meliponaryController = TextEditingController(text: beekeeper.meliponaryName);
    _addressController = TextEditingController(text: beekeeper.address);
    _emailController = TextEditingController(text: beekeeper.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _meliponaryController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<BeekeeperProvider>().updateProfile(
          name: _nameController.text.trim(),
          meliponaryName: _meliponaryController.text.trim(),
          address: _addressController.text.trim(),
          email: _emailController.text.trim(),
        );
    Navigator.of(context).pop();
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Preencha este campo' : null;
  }

  String? _email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preencha este campo';
    return value.contains('@') ? null : 'Informe um e-mail válido';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: referenceHoneyOrange,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: HoneycombBackground()),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(
                      height: 56,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 42,
                                  height: 42,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 39,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Perfil',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 29,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ReferenceFormCard(
                      children: [
                        ReferenceFormField(
                          label: 'Nome:',
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          validator: _required,
                        ),
                        ReferenceFormField(
                          label: 'Nome Meliponiponário:',
                          controller: _meliponaryController,
                          textInputAction: TextInputAction.next,
                          validator: _required,
                        ),
                        ReferenceFormField(
                          label: 'Endereço:',
                          controller: _addressController,
                          textInputAction: TextInputAction.next,
                          validator: _required,
                        ),
                        ReferenceFormField(
                          label: 'Email:',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _email,
                        ),
                        ReferenceFormField(
                          label: 'Senha:',
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _save(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ReferenceActionButton(
                      label: 'Salvar',
                      compactText: true,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
