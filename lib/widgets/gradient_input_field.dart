import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class GradientInputField extends StatelessWidget {
  final TextField textField;

  const GradientInputField({super.key, required this.textField});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [styling.primary, styling.secondary],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        margin: EdgeInsets.all(2), // Creates the border thickness
        decoration: BoxDecoration(
          color: styling.background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: textField,
      ),
    );
  }
}
