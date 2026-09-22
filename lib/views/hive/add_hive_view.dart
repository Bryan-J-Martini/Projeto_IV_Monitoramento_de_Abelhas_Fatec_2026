import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/telemetry_model.dart';
import '../../providers/hive_provider.dart';
import 'hive_form_view.dart';

class AddHiveView extends StatefulWidget {
  const AddHiveView({super.key});

  @override
  State<AddHiveView> createState() => _AddHiveViewState();
}

class _AddHiveViewState extends State<AddHiveView> {
  final _nameController = TextEditingController();
  String _selectedSpecies = hiveSpeciesOptions.first.value;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Informe um nome para a colmeia.');
      return;
    }

    context.read<HiveProvider>().addHive(
      name: name,
      species: _selectedSpecies,
      description: 'Colmeia cadastrada pelo aplicativo.',
      ipAddress: '192.168.4.1',
      initialTelemetry: TelemetryModel(
        internalTemp: 28.5,
        trafficIn: 32,
        trafficOut: 28,
        externalTemp: 27.0,
        externalHumidity: 65.0,
        timestamp: DateTime.now(),
      ),
      isOnline: true,
    );
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HiveFormView(
      title: 'Adicionar\nColmeia',
      nameController: _nameController,
      selectedSpecies: _selectedSpecies,
      onSpeciesChanged: (species) => setState(() => _selectedSpecies = species),
      onSave: _save,
    );
  }
}
