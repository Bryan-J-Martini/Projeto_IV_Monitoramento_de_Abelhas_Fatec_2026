import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/beekeeper_provider.dart';
import '../../widgets/honeycomb_background.dart';
import '../../widgets/reference_profile_form.dart';

/// Cadastro inicial. Pertence ao fluxo de autenticação e retorna ao login.
class CadastroView extends StatefulWidget {
  const CadastroView({super.key});

  @override
  State<CadastroView> createState() => _CadastroViewState();
}

class _CadastroViewState extends State<CadastroView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _meliponaryController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _meliponaryController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _register() {
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
                    const Text(
                      'Cadastro',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 29,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 31),
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
                          onSubmitted: (_) => _register(),
                          validator: _required,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ReferenceActionButton(label: 'Cadastrar', onPressed: _register),
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
