import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/honeycomb_background.dart';

class HiveSpeciesOption {
  final String label;
  final String value;
  final int variant;
  final String imagePath;

  const HiveSpeciesOption({
    required this.label,
    required this.value,
    required this.variant,
    required this.imagePath,
  });
}

const hiveSpeciesOptions = <HiveSpeciesOption>[
  HiveSpeciesOption(
    label: 'JATAÍ',
    value: 'Jataí (Tetragonisca angustula)',
    variant: 0,
    imagePath: 'assets/abelhas/abelha_jataí.jpg',
  ),
  HiveSpeciesOption(
    label: 'MANDAÇAIA',
    value: 'Mandaçaia (Melipona quadrifasciata)',
    variant: 1,
    imagePath: 'assets/abelhas/abelha_mandacaia.jpg',
  ),
  HiveSpeciesOption(
    label: 'URUÇU',
    value: 'Uruçu (Melipona scutellaris)',
    variant: 2,
    imagePath: 'assets/abelhas/abelha_urucu.jpg',
  ),
  HiveSpeciesOption(
    label: 'IRAÍ',
    value: 'Iraí (Nannotrigona testaceicornis)',
    variant: 3,
    imagePath: 'assets/abelhas/abelha_iraí.png',
  ),
  HiveSpeciesOption(
    label: 'BORÁ',
    value: 'Borá (Tetragona clavipes)',
    variant: 4,
    imagePath: 'assets/abelhas/abelha_borá.png',
  ),
  HiveSpeciesOption(
    label: 'JANDAÍRA',
    value: 'Jandaíra (Melipona subnitida)',
    variant: 5,
    imagePath: 'assets/abelhas/abelha_jandaira.jpg',
  ),
];

class HiveFormView extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final String selectedSpecies;
  final ValueChanged<String> onSpeciesChanged;
  final VoidCallback onSave;

  const HiveFormView({
    super.key,
    required this.title,
    required this.nameController,
    required this.selectedSpecies,
    required this.onSpeciesChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFB703),
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: HoneycombBackground()),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    (constraints.maxWidth * 0.07).clamp(12.0, 30.0);
                final contentWidth = math.min(
                  constraints.maxWidth - horizontalPadding * 2,
                  420.0,
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    20,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          _HiveFormHeader(
                            title: title,
                            onBack: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(height: 2),
                          _HiveFormCard(
                            width: contentWidth,
                            nameController: nameController,
                            selectedSpecies: selectedSpecies,
                            onSpeciesChanged: onSpeciesChanged,
                          ),
                          const SizedBox(height: 16),
                          _SaveButton(
                            width: (contentWidth * 0.59).clamp(168.0, 220.0),
                            onPressed: onSave,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HiveFormHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _HiveFormHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const SizedBox(
              width: 54,
              height: 54,
              child: Icon(Icons.arrow_back, color: Colors.white, size: 44),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 29,
                height: 0.91,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 54),
        ],
      ),
    );
  }
}

class _HiveFormCard extends StatelessWidget {
  final double width;
  final TextEditingController nameController;
  final String selectedSpecies;
  final ValueChanged<String> onSpeciesChanged;

  const _HiveFormCard({
    required this.width,
    required this.nameController,
    required this.selectedSpecies,
    required this.onSpeciesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.fromLTRB(width * 0.032, 5, width * 0.032, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Text(
              'Nome:',
              style: TextStyle(color: Colors.black, fontSize: 13, height: 1),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 38,
            child: TextField(
              controller: nameController,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFD0D0D0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(
                    color: Color(0xFF00B977),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: Text(
              'Espécie de Abelha:',
              style: TextStyle(color: Colors.black, fontSize: 13, height: 1),
            ),
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) {
              final spacing = (constraints.maxWidth * 0.05).clamp(8.0, 18.0);
              final labelSize =
                  (constraints.maxWidth * 0.046).clamp(12.0, 14.0);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hiveSpeciesOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: 9,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final option = hiveSpeciesOptions[index];
                  return _SpeciesCard(
                    option: option,
                    selected: selectedSpecies == option.value,
                    labelSize: labelSize,
                    onTap: () => onSpeciesChanged(option.value),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi,
                color: Color(0xFF00B977),
                size: 31,
              ),
              const SizedBox(width: 8),
              Text(
                'Conectado a\nRede Wifi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF00B977),
                  fontSize: (width * 0.074).clamp(21.0, 26.0),
                  height: 0.98,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  final HiveSpeciesOption option;
  final bool selected;
  final double labelSize;
  final VoidCallback onTap;

  const _SpeciesCard({
    required this.option,
    required this.selected,
    required this.labelSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(3, 4, 3, 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD0D0D0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xFF00B977) : Colors.transparent,
              width: selected ? 5 : 0,
            ),
          ),
          child: Column(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: labelSize,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomPaint(
                    child: Image.asset(
                      option.imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final double width;
  final VoidCallback onPressed;

  const _SaveButton({required this.width, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 47,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C5A00),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Salvar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
