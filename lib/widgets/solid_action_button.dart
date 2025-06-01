import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class SolidActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SolidActionButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2), // Creates the border thickness
      decoration: BoxDecoration(
        color: styling.secondaryColor,
        borderRadius: BorderRadius.circular(6), // Slightly smaller radius
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white, // This will be masked by the gradient
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        onPressed: onTap,
      ),
    );
  }
}
