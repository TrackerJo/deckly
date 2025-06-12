import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class SolidActionButton extends StatelessWidget {
  final Widget text;
  final VoidCallback onTap;
  const SolidActionButton({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      // Creates the border thickness
      decoration: BoxDecoration(
        color: styling.secondary,
        borderRadius: BorderRadius.circular(6), // Slightly smaller radius
      ),
      child: Material(
        color: Colors.transparent, // Makes the Material transparent
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          splashColor: styling.secondary.withOpacity(0.3),
          highlightColor: styling.secondary.withOpacity(0.3),
          onTap: () {
            SharedPrefs.hapticButtonPress();
            onTap();
          },
          child: Center(child: text),
        ),
      ),
    );
  }
}
