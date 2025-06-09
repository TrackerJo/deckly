import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class SolidActionButton extends StatelessWidget {
  final Text text;
  final VoidCallback onTap;
  const SolidActionButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      // Creates the border thickness
      decoration: BoxDecoration(
        color: styling.secondaryColor,
        borderRadius: BorderRadius.circular(6), // Slightly smaller radius
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          // padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          SharedPrefs.hapticButtonPress();
          onTap();
        },
        child: text,
      ),
    );
  }
}
