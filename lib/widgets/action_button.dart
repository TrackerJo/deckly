import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const ActionButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [styling.primaryColor, styling.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        margin: EdgeInsets.all(2), // Creates the border thickness
        decoration: BoxDecoration(
          color: styling.backgroundColor,
          borderRadius: BorderRadius.circular(6), // Slightly smaller radius
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [styling.primaryColor, styling.secondaryColor],
                ).createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
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
          ),
          onPressed:
              onTap != null
                  ? () async {
                    SharedPrefs.hapticButtonPress();
                    onTap!();
                  }
                  : null,
        ),
      ),
    );
  }
}
