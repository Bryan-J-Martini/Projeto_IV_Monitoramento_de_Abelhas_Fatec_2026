import 'package:flutter/material.dart';

const referenceHoneyYellow = Color(0xFFFFC800);
const referenceHoneyOrange = Color(0xFFFF9D00);
const referenceHoneyBrown = Color(0xFF9C5A00);

class ReferenceFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const ReferenceFormField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 1, bottom: 3),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                height: 1.05,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 38),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onFieldSubmitted: onSubmitted,
              validator: validator,
              style: const TextStyle(
                color: Color(0xFF3B2A1E),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFD0D0D0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                errorStyle: const TextStyle(
                  color: Color(0xFF7A1D00),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
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
                  borderSide: const BorderSide(color: referenceHoneyBrown, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFF7A1D00), width: 1.2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: Color(0xFF7A1D00), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReferenceFormCard extends StatelessWidget {
  final List<Widget> children;

  const ReferenceFormCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 7, 11, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class ReferenceActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool compactText;

  const ReferenceActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compactText = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: referenceHoneyBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: compactText ? 14 : 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
