import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final Widget text;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool useFancyText;
  final bool filled;
  final double borderRadius;
  const ActionButton({
    required this.text,
    required this.onTap,
    this.width = double.infinity,
    this.height = 50,
    this.useFancyText = true,
    this.filled = false,
    this.borderRadius = 8,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [styling.primary, styling.secondary],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child:
          filled
              ? Material(
                color: Colors.transparent, // Makes the Material transparent
                borderRadius: BorderRadius.circular(borderRadius - 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                  splashColor: styling.primary.withOpacity(0.3),
                  highlightColor: styling.primary.withOpacity(0.3),
                  onTap: () {
                    if (onTap != null) {
                      SharedPrefs.hapticButtonPress();
                      onTap!();
                    }
                  },
                  child: Center(
                    child:
                        useFancyText
                            ? ShaderMask(
                              shaderCallback:
                                  (bounds) => LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      styling.primary,
                                      styling.secondary,
                                    ],
                                  ).createShader(
                                    Rect.fromLTWH(
                                      0,
                                      0,
                                      bounds.width,
                                      bounds.height,
                                    ),
                                  ),
                              child: text,
                            )
                            : text,
                  ),
                ),
              )
              : Container(
                margin: EdgeInsets.all(2),
                // Creates the border thickness
                decoration: BoxDecoration(
                  color: styling.background,
                  borderRadius: BorderRadius.circular(
                    borderRadius -
                        2, // Adjusts the border radius to fit inside the container
                  ), // Slightly smaller radius
                ),
                child: Material(
                  color: Colors.transparent, // Makes the Material transparent
                  borderRadius: BorderRadius.circular(borderRadius - 2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(borderRadius - 2),
                    splashColor: styling.primary.withOpacity(0.3),
                    highlightColor: styling.primary.withOpacity(0.3),
                    onTap: () {
                      if (onTap != null) {
                        SharedPrefs.hapticButtonPress();
                        onTap!();
                      }
                    },
                    child: Center(
                      child:
                          useFancyText
                              ? ShaderMask(
                                shaderCallback:
                                    (bounds) => LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        styling.primary,
                                        styling.secondary,
                                      ],
                                    ).createShader(
                                      Rect.fromLTWH(
                                        0,
                                        0,
                                        bounds.width,
                                        bounds.height,
                                      ),
                                    ),
                                child: text,
                              )
                              : text,
                    ),
                  ),
                ),
              ),
    );
  }
}
