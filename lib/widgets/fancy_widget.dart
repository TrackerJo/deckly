import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class FancyWidget extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color? borderColor;
  const FancyWidget({
    super.key,
    required this.child,
    this.borderRadius = 8.0,
    this.borderWidth = 2.0,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [styling.primaryColor, styling.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth), // Creates the border thickness
        decoration: BoxDecoration(
          color: styling.backgroundColor,
          borderRadius: BorderRadius.circular(
            borderRadius - 2,
          ), // Slightly smaller radius
          border: Border.all(
            color:
                borderColor ??
                Colors.transparent, // Default to white if no color provided
            width: borderWidth,
          ),
        ),
        child: child,
      ),
    );
  }
}
