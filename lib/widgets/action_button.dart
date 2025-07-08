import 'dart:async';
import 'dart:math';

import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:flutter/material.dart';

class ActionButton extends StatefulWidget {
  final Widget text;
  final VoidCallback? onTap;
  final double width;
  final double height;
  final bool useFancyText;
  final bool filled;
  final double borderRadius;
  final bool showNewIndicator;
  final Game? game;
  const ActionButton({
    required this.text,
    required this.onTap,
    this.width = double.infinity,
    this.height = 50,
    this.useFancyText = true,
    this.filled = false,
    this.borderRadius = 8,
    super.key,
    this.showNewIndicator = false,
    this.game,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  late StreamSubscription<List<Game>> _newGamesSubscription;

  bool showNewIndicator = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.showNewIndicator && widget.game != null) {
      SharedPrefs.getNewUser().then((isNewUser) {
        print('Is new user: $isNewUser');
        if (!isNewUser) {
          SharedPrefs.hasSeenNewGame(widget.game!).then((hasSeen) {
            print('Has seen new game: $hasSeen');
            setState(() {
              showNewIndicator = !hasSeen;
            });
          });
          _newGamesSubscription = SharedPrefs.newGamesSeenStream.listen((
            games,
          ) {
            setState(() {
              showNewIndicator = !games.contains(widget.game);
            });
            print('New games seen updated: $games');
          });
        }
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    try {
      _newGamesSubscription.cancel();
    } catch (e) {
      print('Error cancelling subscription: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [styling.primary, styling.secondary],
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child:
              widget.filled
                  ? Material(
                    color: Colors.transparent, // Makes the Material transparent
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius - 2,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius - 2,
                      ),
                      splashColor: styling.primary.withOpacity(0.3),
                      highlightColor: styling.primary.withOpacity(0.3),
                      onTap: () {
                        if (widget.onTap != null) {
                          SharedPrefs.hapticButtonPress();
                          widget.onTap!();
                        }
                      },
                      child: Center(
                        child:
                            widget.useFancyText
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
                                  child: widget.text,
                                )
                                : widget.text,
                      ),
                    ),
                  )
                  : Container(
                    margin: EdgeInsets.all(2),
                    // Creates the border thickness
                    decoration: BoxDecoration(
                      color: styling.background,
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius -
                            2, // Adjusts the border radius to fit inside the container
                      ), // Slightly smaller radius
                    ),
                    child: Material(
                      color:
                          Colors.transparent, // Makes the Material transparent
                      borderRadius: BorderRadius.circular(
                        widget.borderRadius - 2,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          widget.borderRadius - 2,
                        ),
                        splashColor: styling.primary.withOpacity(0.3),
                        highlightColor: styling.primary.withOpacity(0.3),
                        onTap: () {
                          if (widget.onTap != null) {
                            SharedPrefs.hapticButtonPress();
                            widget.onTap!();
                          }
                        },
                        child: Center(
                          child:
                              widget.useFancyText
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
                                    child: widget.text,
                                  )
                                  : widget.text,
                        ),
                      ),
                    ),
                  ),
        ),
        if (showNewIndicator)
          Positioned(
            top: -2,
            right: -20,
            child: Transform.rotate(
              angle: pi / 4, // Adjust the angle as needed
              child: Container(
                width: 60,
                height: 25,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  // borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
