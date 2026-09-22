import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/telemetry_model.dart';
import '../../providers/hive_provider.dart';
import '../../widgets/bee_mascot_widget.dart';
import '../../widgets/glass_container.dart';

class ConnectHiveView extends StatefulWidget {
  const ConnectHiveView({super.key});

  @override
  State<ConnectHiveView> createState() => _ConnectHiveViewState();
}

class _ConnectHiveViewState extends State<ConnectHiveView> {
  int _currentStep = 0; // 0 = Wi-Fi SoftAP, 1 = Teste, 2 = Dados da Colmeia

  // Formulário Wi-Fi SoftAP
  final TextEditingController _ssidController =
      TextEditingController(text: 'Abelha_Node_01');
  final TextEditingController _passwordController =
      TextEditingController(text: 'melipona2026');
  final TextEditingController _ipController =
      TextEditingController(text: AppConstants.defaultEsp32Ip);

  // Teste de Conexão
  bool _isTestingConnection = false;
  bool _connectionSuccess = false;
  String? _testStatusMessage;
  TelemetryModel? _receivedTelemetry;

  // Dados da Colmeia
  final TextEditingController _nameController =
      TextEditingController(text: 'Jataí Nova');
  String _selectedSpecies = AppConstants.stinglessBeeSpecies[0];
  final TextEditingController _descController = TextEditingController(
    text: 'Caixa INPA modelo 12x12 em madeira de cedro.',
  );

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testStatusMessage = 'Conectando a http://${_ipController.text}/telemetry...';
    });

    final provider = Provider.of<HiveProvider>(context, listen: false);
    final result = await provider.testEsp32Connection(
      ip: _ipController.text.trim(),
      allowFallback: true,
    );

    setState(() {
      _isTestingConnection = false;
      _connectionSuccess = result['success'] == true;
      _testStatusMessage = result['message'] as String;
      _receivedTelemetry = result['telemetry'] as TelemetryModel?;
    });
  }

  Future<void> _saveHive() async {
    if (_nameController.text.trim().isEmpty) {
      _showAlert('Por favor, defina um nome para a colmeia.');
      return;
    }

    final provider = Provider.of<HiveProvider>(context, listen: false);
    final initialTelemetry = _receivedTelemetry ??
        TelemetryModel(
          internalTemp: 28.5,
          trafficIn: 32,
          trafficOut: 28,
          externalTemp: 27.0,
          externalHumidity: 65.0,
          timestamp: DateTime.now(),
        );

    await provider.addHive(
      name: _nameController.text.trim(),
      species: _selectedSpecies,
      description: _descController.text.trim(),
      ipAddress: _ipController.text.trim(),
      wifiName: _ssidController.text.trim(),
      wifiPassword: _passwordController.text,
      initialTelemetry: initialTelemetry,
      isOnline: _connectionSuccess,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Colmeia "${_nameController.text.trim()}" cadastrada com sucesso!',
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.healthIdeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showAlert(String message) {
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
        title: const Text('Nova Colmeia ESP32'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de Passos no estilo Apple
              _buildStepIndicator(),

              const SizedBox(height: 24),

              // Conteúdo do Passo Ativo
              if (_currentStep == 0) _buildSoftApInstructionsStep(),
              if (_currentStep == 1) _buildTestConnectionStep(),
              if (_currentStep == 2) _buildHiveDetailsStep(),

              const SizedBox(height: 32),

              // Botões de Avanço / Voltar
              _buildBottomControls(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Rede Wi-Fi', 'Verificar SoftAP', 'Dados da Colmeia'];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.healthIdeal
                            : (isActive
                                ? AppColors.lakeBlue
                                : AppColors.divider),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? AppColors.lakeBlue
                            : (isCompleted
                                ? AppColors.ink
                                : AppColors.mute),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (index < steps.length - 1) const SizedBox(width: 8),
            ],
          ),
        );
      }),
    );
  }

  // PASSO 1: INSTRUÇÕES E CREDENCIAIS SOFTAP
  Widget _buildSoftApInstructionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card ilustrativo amigável
        GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.skyBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.wifi,
                      color: AppColors.lakeBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Conectar ao Ponto de Acesso',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Rede Wi-Fi direta da caixa (ESP32 SoftAP)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceGray,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Acesse os ajustes Wi-Fi do seu celular e conecte-se à rede emitida pelo nó da colmeia antes de testar a rota.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'CREDENCIAS DO NÓ ESP32',
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
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              _buildFieldTile(
                icon: CupertinoIcons.antenna_radiowaves_left_right,
                label: 'Nome da Rede (SSID)',
                controller: _ssidController,
                placeholder: 'Ex: Abelha_Node_01',
              ),
              const Divider(height: 1, indent: 48, color: AppColors.divider),
              _buildFieldTile(
                icon: CupertinoIcons.lock_fill,
                label: 'Senha da Rede Wi-Fi',
                controller: _passwordController,
                placeholder: 'Senha do SoftAP',
                obscureText: true,
              ),
              const Divider(height: 1, indent: 48, color: AppColors.divider),
              _buildFieldTile(
                icon: CupertinoIcons.link,
                label: 'Endereço IP SoftAP',
                controller: _ipController,
                placeholder: '192.168.4.1',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // PASSO 2: TESTE DE ROTA /TELEMETRY
  Widget _buildTestConnectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const BeeMascotWidget(
                size: 70,
                internalTemp: 28.5,
                showSpeechBubble: false,
              ),
              const SizedBox(height: 14),
              const Text(
                'Verificador de Conexão IoT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Testando comunicação com http://${_ipController.text}/telemetry',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(height: 20),

              // Botão de teste
              CupertinoButton(
                color: _connectionSuccess
                    ? AppColors.healthIdeal
                    : AppColors.lakeBlue,
                borderRadius: BorderRadius.circular(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                onPressed: _isTestingConnection ? null : _testConnection,
                child: _isTestingConnection
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CupertinoActivityIndicator(color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            'Consultando ESP32...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _connectionSuccess
                                ? CupertinoIcons.checkmark_alt_circle_fill
                                : CupertinoIcons.bolt_horizontal_circle_fill,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _connectionSuccess
                                ? 'Conexão Verificada!'
                                : 'Testar Conexão com ESP32',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),

              if (_testStatusMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _connectionSuccess
                        ? AppColors.healthIdeal.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _connectionSuccess
                          ? AppColors.healthIdeal.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _connectionSuccess
                            ? CupertinoIcons.check_mark_circled
                            : CupertinoIcons.info_circle,
                        color: _connectionSuccess
                            ? AppColors.healthIdeal
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _testStatusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _connectionSuccess
                                ? AppColors.ink
                                : const Color(0xFFC2410C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_receivedTelemetry != null) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGray,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniTelemetry(
                        'Temp. Interna',
                        '${_receivedTelemetry!.internalTemp}°C',
                      ),
                      _buildMiniTelemetry(
                        'Tráfego',
                        '${_receivedTelemetry!.totalTraffic} ab/m',
                      ),
                      _buildMiniTelemetry(
                        'Clima Ext.',
                        '${_receivedTelemetry!.externalTemp}°C',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // PASSO 3: DADOS DA COLMEIA E SALVAR
  Widget _buildHiveDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'IDENTIFICAÇÃO DA COLMEIA',
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
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              _buildFieldTile(
                icon: CupertinoIcons.tag_fill,
                label: 'Nome da Colmeia',
                controller: _nameController,
                placeholder: 'Ex: Jataí 03, Mandaçaia Florinda',
              ),
              const Divider(height: 1, indent: 48, color: AppColors.divider),
              // Seletor de Espécie
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.circle_grid_hex_fill,
                      color: AppColors.lakeBlue,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Espécie de Abelha Sem Ferrão',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mute,
                            ),
                          ),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSpecies,
                              isExpanded: true,
                              icon: const Icon(
                                CupertinoIcons.chevron_down,
                                size: 16,
                                color: AppColors.slate,
                              ),
                              items: AppConstants.stinglessBeeSpecies
                                  .map((species) => DropdownMenuItem(
                                        value: species,
                                        child: Text(
                                          species,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() {
                                    _selectedSpecies = val;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 48, color: AppColors.divider),
              _buildFieldTile(
                icon: CupertinoIcons.doc_text_fill,
                label: 'Descrição da Caixa / Local',
                controller: _descController,
                placeholder: 'Ex: Caixa INPA 15x15 sob árvore de laranjeira',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniTelemetry(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.slate),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            child: CupertinoButton(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(16),
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text(
                'Voltar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: CupertinoButton(
            color: _currentStep == 2 ? AppColors.healthIdeal : AppColors.lakeBlue,
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(vertical: 16),
            onPressed: () {
              if (_currentStep < 2) {
                setState(() {
                  _currentStep++;
                });
              } else {
                unawaited(_saveHive());
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentStep == 2 ? 'Salvar Colmeia' : 'Continuar',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _currentStep == 2
                      ? CupertinoIcons.checkmark_alt
                      : CupertinoIcons.arrow_right,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldTile({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: const TextStyle(
                      fontSize: 14,
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
