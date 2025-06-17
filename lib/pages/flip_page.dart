import 'dart:async';

import 'dart:math' as math;
import 'package:deckly/api/bots.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/blitz_deck.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/deck.dart';
import 'package:deckly/widgets/deck_anim.dart';
import 'package:deckly/widgets/drop_zone.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

class FlipPage extends StatefulWidget {
  const FlipPage({super.key});
  // const Nertz({super.key});
  @override
  _FlipPageState createState() => _FlipPageState();
}

class _FlipPageState extends State<FlipPage> {
  final CardDeckAnimController deckController = CardDeckAnimController();
  List<CardData> deckCards = [];

  @override
  void initState() {
    super.initState();
    deckCards = [...fullDeck];
  }

  double _calculateScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final padding = 32.0;

    // Available dimensions
    final availableWidth = screenWidth - padding;
    final availableHeight =
        screenHeight - appBarHeight - statusBarHeight - padding;

    // Layout breakdown:
    // Top: 100px fixed
    // Bottom: remaining space for drop zones and deck
    final topHeight = 100.0;
    final bottomHeight =
        availableHeight - topHeight - 48.0; // 48px for spacing (16 + 32)

    // Calculate scale based on bottom section (most constrained)
    // Bottom: 4 drop zones + deck area
    final dropZoneBaseWidth = 116.0; // card width + padding
    final bottomZonesWidth =
        (4 * dropZoneBaseWidth) + (3 * 8.0); // 4 zones + 3 gaps
    final deckWidth = 288.5; // deck + pile area (100+20+100)
    final totalBottomWidth = bottomZonesWidth + 16.0 + deckWidth;

    final widthScale = availableWidth / totalBottomWidth;

    // Calculate height scale considering space for 13 stacked cards
    // Height needed for 13 cards: (12 spacing intervals * 35px) + (175px base height * scale)
    // Formula: heightScale = bottomHeight / (420 + 175 * heightScale)
    // Rearranging: 175 * heightScale^2 + 420 * heightScale - bottomHeight = 0
    // Using quadratic formula to solve for heightScale
    final a = 175.0;
    final b = 420.0; // 12 * 35
    final c = -bottomHeight;
    final discriminant = b * b - 4 * a * c;
    final heightScale =
        discriminant > 0
            ? (-b + math.sqrt(discriminant)) / (2 * a)
            : bottomHeight / (420 + 175); // fallback for edge cases

    // Use the more restrictive scale
    final scale = [widthScale, heightScale].reduce((a, b) => a < b ? a : b);
    return scale.clamp(0.3, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final calculatedScale = _calculateScale(context);

    return PopScope(
      //Disable swipe to go back
      canPop: false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: "Flip",
            showBackButton: true,
            onBackButtonPressed: (context) {
              connectionService.dispose();
              Navigator.pop(context);
            },
            customBackButton: IconButton(
              splashColor: Colors.transparent,
              splashRadius: 25,
              icon: Transform.flip(
                flipX: true,
                child: SFIcon(
                  SFIcons.sf_rectangle_portrait_and_arrow_right, // 'heart.fill'
                  // fontSize instead of size
                  fontWeight: FontWeight.bold, // fontWeight instead of weight
                  color: styling.primary,
                ),
              ),
              onPressed: () async {
                SharedPrefs.hapticButtonPress();
                //Confirm with user before leaving
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return Dialog(
                      backgroundColor: Colors.transparent,

                      child: Container(
                        width: 400,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [styling.primary, styling.secondary],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          margin: EdgeInsets.all(
                            2,
                          ), // Creates the border thickness
                          decoration: BoxDecoration(
                            color: styling.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Are you sure you want to leave the game?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ActionButton(
                                    height: 40,
                                    width: 100,
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    text: Text(
                                      "Cancel",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  ActionButton(
                                    height: 40,
                                    width: 100,
                                    onTap: () {
                                      connectionService.dispose();

                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    text: Text(
                                      "Leave",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: styling.background,
        body: Container(
          height: double.infinity,
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: buildPlayingScreen(calculatedScale),
          ),
        ),
      ),
    );
  }

  Widget buildPlayingScreen(double calculatedScale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Container (100px)
        FancyBorder(
          child: Container(
            height: 100.0,
            width: double.infinity,

            child: SingleChildScrollView(child: Row(children: [
                  
                ],
              )),
          ),
        ),

        SizedBox(height: 16.0),

        // Middle Section - Grid of drop zones (excluding bottom 4)
        const SizedBox(height: 16.0),
        Stack(
          children: [
            // Background grid lines

            // Foreground content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - 4 drop zones
                SizedBox(width: 8.0),
                //Create a vertical divider
                Container(
                  width: 2.0,
                  height: 330.0 * calculatedScale,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                SizedBox(width: 8.0),

                // Right side - Deck area
                Column(
                  children: [
                    CardDeckAnim(
                      cards: deckCards,
                      onDragStarted: (s) {},
                      onDragEnd: () {},
                      currentDragData: DragData(
                        cards: [],
                        sourceZoneId: "",
                        sourceIndex: -1,
                      ),
                      deckId: 'deck',
                      controller: deckController,
                      onReachEndOfDeck: () {},
                      scale: calculatedScale,
                    ),
                    SizedBox(height: 16.0),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Bottom Section - 4 drop zones on left, deck on right
      ],
    );
  }
}
