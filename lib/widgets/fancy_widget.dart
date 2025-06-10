import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class FancyWidget extends StatelessWidget {
  final Widget child;
  const FancyWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback:
          (bounds) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [styling.primaryColor, styling.secondaryColor],
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: child,
    );
  }
}
