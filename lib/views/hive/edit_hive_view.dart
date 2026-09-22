import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/hive_provider.dart';
import 'hive_form_view.dart';

class EditHiveView extends StatefulWidget {
  final String hiveId;

  const EditHiveView({super.key, required this.hiveId});

  @override
  State<EditHiveView> createState() => _EditHiveViewState();
}

class _EditHiveViewState extends State<EditHiveView> {
  late final TextEditingController _nameController;
  late String _selectedSpecies;

  @override
  void initState() {
    super.initState();
    final provider = context.read<HiveProvider>();
    final hive = provider.hives.firstWhere(
      (item) => item.id == widget.hiveId,
      orElse: () => provider.selectedHive ?? provider.hives.first,
    );
    _nameController = TextEditingController(text: hive.name);
    _selectedSpecies = _optionForSpecies(hive.species).value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  HiveSpeciesOption _optionForSpecies(String species) {
    final normalized = species.toLowerCase();
    return hiveSpeciesOptions.firstWhere(
      (option) => normalized.contains(option.label.toLowerCase()),
      orElse: () => hiveSpeciesOptions.first,
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um nome para a colmeia.')),
      );
      return;
    }

    context.read<HiveProvider>().updateHive(
      hiveId: widget.hiveId,
      name: name,
      species: _selectedSpecies,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim().isEmpty
        ? 'Colmeia'
        : _nameController.text.trim();
    return HiveFormView(
      title: 'Editar\n$name',
      nameController: _nameController,
      selectedSpecies: _selectedSpecies,
      onSpeciesChanged: (species) => setState(() => _selectedSpecies = species),
      onSave: _save,
    );
  }
}
