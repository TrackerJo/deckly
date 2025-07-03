import 'dart:async';

import 'dart:math' as math;
import 'package:deckly/api/bots.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/blitz_deck.dart';
import 'package:deckly/widgets/custom_app_bar.dart';

import 'package:deckly/widgets/deck_anim.dart';
import 'package:deckly/widgets/drop_zone.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/orientation_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

class Solitare extends StatefulWidget {
  final GamePlayer player;

  const Solitare({super.key, required this.player});
  // const Nertz({super.key});
  @override
  _SolitareState createState() => _SolitareState();
}

class _SolitareState extends State<Solitare> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<CardData> pileCards = [];

  GamePlayer? currentPlayer;

  bool couldBeStuck = false;
  bool hasMovedCards = false;

  final CardDeckAnimController deckController = CardDeckAnimController();

  final ScrollController scrollController = ScrollController();
  Map<String, DropZoneController> dropZoneControllers = {};

  DragData currentDragData = DragData(
    cards: [],
    sourceZoneId: '',
    sourceIndex: -1,
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() async {
    currentPlayer = GamePlayer(id: widget.player.id, name: widget.player.name);

    List<CardData> shuffledDeck = [...fullDeck];
    shuffledDeck.shuffle();
    // Bottom 4 drop zones
    //repeat 7 times
    for (int i = 0; i < 7; i++) {
      List<CardData> startingCards = [];
      for (int j = 0; j < i + 1; j++) {
        //add i + 1 cards to the pile
        if (shuffledDeck.isEmpty) {
          print("Not enough cards in deck to fill pile $i");
          break;
        }
        CardData card = shuffledDeck.removeAt(0);
        startingCards.add(card);
      }
      dropZones.add(
        DropZoneData(
          id: 'pile$i',
          stackMode: StackMode.spaced,
          rules: DropZoneRules(
            cardOrder: CardOrder.descending,
            allowedCards: AllowedCards.alternateColor,
            startingCards: [
              MiniCard(value: 13, suit: CardSuit.diamonds),
              MiniCard(value: 13, suit: CardSuit.spades),
              MiniCard(value: 13, suit: CardSuit.clubs),
              MiniCard(value: 13, suit: CardSuit.hearts),
            ],
            bannedCards: [],
          ),
          canDragCardOut: true,
          cards: startingCards,
          isSolitaire: true,
          solitaireStartingCards: startingCards,
          scale: 0.1,
          isPublic: false,
        ),
      );
    }

    // Add middle drop zones (goal zones)
    for (int i = 0; i < 4; i++) {
      dropZones.add(
        DropZoneData(
          id: 'goal$i',
          stackMode: StackMode.overlay,
          rules: DropZoneRules(
            cardOrder: CardOrder.ascending,
            allowedCards: AllowedCards.sameSuit,
            startingCards: [
              MiniCard(value: 1, suit: CardSuit.diamonds),
              MiniCard(value: 1, suit: CardSuit.spades),
              MiniCard(value: 1, suit: CardSuit.clubs),
              MiniCard(value: 1, suit: CardSuit.hearts),
            ],
            bannedCards: [],
          ),
          canDragCardOut: false,
          cards: [],
          scale: 0.1,
          isPublic: false,
        ),
      );
    }
    for (var dropZone in dropZones) {
      final controller = DropZoneController();
      dropZoneControllers[dropZone.id] = controller;
      dropZone.controller = controller;
    }

    // Initialize deck cards
    deckCards = [...shuffledDeck];

    setState(() {});
  }

  void restartGame() {
    // Reset the game state
    deckController.clearDeck();
    dropZones.clear();
    deckCards.clear();
    currentDragData = DragData(cards: [], sourceZoneId: '', sourceIndex: -1);
    hasMovedCards = false;
    couldBeStuck = false;
    _initializeData();
  }

  void _moveCards(DragData dragData, String targetZoneId) async {
    final targetZone = dropZones.firstWhere((zone) => zone.id == targetZoneId);

    setState(() {
      hasMovedCards = true;
      couldBeStuck = false;
      currentDragData = DragData(cards: [], sourceZoneId: '', sourceIndex: -1);
      if (dragData.sourceZoneId != 'deck' &&
          dragData.sourceZoneId != 'pile' &&
          dragData.sourceZoneId != 'blitz_deck') {
        final sourceZone = dropZones.firstWhere(
          (zone) => zone.id == dragData.sourceZoneId,
        );
        sourceZone.cards.removeRange(
          dragData.sourceIndex,
          dragData.sourceIndex + dragData.cards.length,
        );
      } else if (dragData.sourceZoneId == 'pile') {
        final card = dragData.cards.first;
        deckCards.removeWhere((c) => c.id == card.id);
        pileCards.removeWhere((c) => c.id == card.id);
      }

      if (targetZone.isPublic) {
        print("Played to goal zone: ${targetZone.id}");
      }
      targetZone.cards.addAll(dragData.cards);
      dragData.cards.forEach((card) {
        card.playedBy = currentPlayer!.id; // Set the player who played the card
      });
      //Check if won the game
      bool wonGame = true;
      for (var zone in dropZones) {
        if (zone.id.startsWith('goal') && zone.cards.length < 13) {
          wonGame = false;
          break;
        }
      }
      if (wonGame) {
        gameOver();
      }
    });
  }

  void gameOver() {
    print("Game Over! You won!");
    // Increment the games won count
    SharedPrefs.addSolitaireGamesWon(1);
    // Show a dialog or navigate to a game over screen
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
              margin: EdgeInsets.all(2), // Creates the border thickness
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
                    "Congratulations! You won!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ActionButton(
                        height: 40,
                        width: 100,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        text: Text(
                          "Leave",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      ActionButton(
                        height: 40,
                        width: 100,
                        onTap: () async {
                          restartGame();
                          Navigator.of(context).pop();
                        },
                        text: Text(
                          "Restart",
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
  }

  List<CardData> _getCardsFromIndex(String zoneId, int index) {
    if (zoneId == 'deck' || zoneId == 'pile' || zoneId == 'blitz_deck') {
      return <CardData>[];
    }
    final zone = dropZones.firstWhere((zone) => zone.id == zoneId);
    return zone.cards.sublist(index);
  }

  void _onDragStarted(DragData dragData) {
    setState(() {
      currentDragData = dragData;
    });
  }

  void _onDragEnd() {
    setState(() {
      currentDragData = DragData(cards: [], sourceZoneId: '', sourceIndex: -1);
    });
  }

  double _calculateScale(BuildContext context, Orientation orientation) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    print("Screen Width: $screenWidth, Screen Height: $screenHeight");
    final appBarHeight = kToolbarHeight;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Available dimensions
    final availableWidth = screenWidth;
    final availableHeight = screenHeight - appBarHeight - statusBarHeight;

    // Layout breakdown:
    // Top: 100px fixed
    // Bottom: remaining space for drop zones and deck
    final topHeight = 100.0;
    final bottomHeight =
        availableHeight - topHeight; // 48px for spacing (16 + 32)

    // Calculate scale based on bottom section (most constrained)
    // Bottom: 4 drop zones + deck area
    final dropZoneBaseWidth = 116.0; // card width + padding

    final bottomZonesWidth =
        orientation == Orientation.landscape
            ? (14 * dropZoneBaseWidth)
            : (5 * dropZoneBaseWidth); // 4 zones + 3 gaps
    // deck + pile area (100+20+100)
    final totalBottomWidth = bottomZonesWidth;

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
    print(
      "Calculated Scale: $scale, Width Scale: $widthScale, Height Scale: $heightScale",
    );
    // return scale.clamp(0.3, 1.0);
    return widthScale.clamp(0.3, 1.0); // Use width scale for consistency
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    final calculatedScale = _calculateScale(context, orientation);

    // Update scale for all drop zones
    for (var zone in dropZones) {
      zone.scale = calculatedScale;
    }

    return PopScope(
      //Disable swipe to go back
      canPop: false,
      child: OrientationChecker(
        allowedOrientations: [Orientation.portrait, Orientation.landscape],
        onOrientationChange: (orientation) {
          if (!mounted) return;
          orientation = orientation;
        },
        isSolitaire: true,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: CustomAppBar(
              title: "Solitaire",
              showBackButton: true,
              onBackButtonPressed: (context) {
                Navigator.pop(context);
              },
              actions: [
                IconButton(
                  onPressed: () {
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
                                    "Are you sure you want to restart the game?",
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
                                        onTap: () async {
                                          restartGame();
                                          Navigator.of(context).pop();
                                        },
                                        text: Text(
                                          "Restart",
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
                  icon: Icon(Icons.refresh, color: styling.primary, size: 24),
                ),
                IconButton(
                  icon: SFIcon(
                    SFIcons.sf_pencil_and_list_clipboard, // 'heart.fill'
                    // fontSize instead of size
                    fontWeight: FontWeight.bold, // fontWeight instead of weight
                    color: styling.primary,
                  ),
                  onPressed: () {
                    SharedPrefs.hapticButtonPress();
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: styling.background,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      constraints: BoxConstraints(
                        // ✅ Add constraints to force full width
                        maxWidth: MediaQuery.of(context).size.width,
                        minWidth: MediaQuery.of(context).size.width,
                      ),
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.8,
                              width: double.infinity,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: solitaireRules,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
              customBackButton: IconButton(
                splashColor: Colors.transparent,
                splashRadius: 25,
                icon: Transform.flip(
                  flipX: true,
                  child: SFIcon(
                    SFIcons
                        .sf_rectangle_portrait_and_arrow_right, // 'heart.fill'
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
                                      onTap: () async {
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
              controller: scrollController,

              child: buildPlayingScreen(calculatedScale, orientation),
            ),
          ),
        ),
      ),
    );
  }

  void onReachEndOfDeck() {
    print("Reached end of deck hasMovedCards: $hasMovedCards");
    if (!hasMovedCards) {
      setState(() {
        couldBeStuck = true;
        hasMovedCards = false;
      });
    } else {
      setState(() {
        couldBeStuck = false;
        hasMovedCards = false;
      });
    }
  }

  Widget buildPlayingScreen(double calculatedScale, Orientation orientation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Container (100px)
        if (orientation == Orientation.portrait)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CardDeckAnim(
                cards: deckCards,
                onDragStarted: _onDragStarted,
                onDragEnd: _onDragEnd,
                currentDragData: currentDragData,
                deckId: 'deck',
                controller: deckController,
                onReachEndOfDeck: onReachEndOfDeck,
                scale: calculatedScale,
                pileCards: pileCards,
                isSolitaire: true,
              ),
              SizedBox(height: 16.0),
              if (couldBeStuck)
                ActionButton(
                  width: 200.0 * calculatedScale,
                  height: 75.0 * calculatedScale,

                  useFancyText: true,
                  text: Text(
                    "Stuck?",
                    style: TextStyle(
                      fontSize: 28.0 * calculatedScale,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    deckController.unstuck();
                    setState(() {
                      couldBeStuck = false;
                      hasMovedCards = false;
                    });
                  },
                ),
            ],
          ),
        if (orientation == Orientation.portrait) const SizedBox(height: 16.0),
        if (orientation == Orientation.portrait) // Spacing below deck
          SizedBox(
            height: 175 * calculatedScale, // 100 + 16 padding
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 100.0 / 150.0, // 2:3 ratio

              physics: NeverScrollableScrollPhysics(),
              children:
                  dropZones
                      .where((zone) => zone.id.startsWith('goal'))
                      .map(
                        (zone) => DropZoneWidget(
                          zone: zone,
                          currentDragData: currentDragData,
                          onMoveCards: _moveCards,
                          getCardsFromIndex: _getCardsFromIndex,
                          onDragStarted: _onDragStarted,
                          onDragEnd: _onDragEnd,
                        ),
                      )
                      .toList(),
            ),
          ),
        if (orientation == Orientation.portrait) const SizedBox(height: 16.0),
        if (orientation == Orientation.portrait) // Spacing below goal zones
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 4; i++)
                Container(
                  margin: EdgeInsets.only(right: i < 6 ? 8.0 : 0.0),
                  child: DropZoneWidget(
                    zone: dropZones[i],
                    currentDragData: currentDragData,
                    onMoveCards: _moveCards,
                    getCardsFromIndex: _getCardsFromIndex,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                  ),
                ),
            ],
          ),
        if (orientation == Orientation.portrait)
          const SizedBox(height: 16.0), // Spacing below goal zones
        if (orientation == Orientation.portrait)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 4; i < 7; i++)
                Container(
                  margin: EdgeInsets.only(right: i < 6 ? 8.0 : 0.0),
                  child: DropZoneWidget(
                    zone: dropZones[i],
                    currentDragData: currentDragData,
                    onMoveCards: _moveCards,
                    getCardsFromIndex: _getCardsFromIndex,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                  ),
                ),
            ],
          ),
        if (orientation == Orientation.landscape)
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 7; i++)
                Container(
                  margin: EdgeInsets.only(right: i < 6 ? 8.0 : 0.0),
                  child: DropZoneWidget(
                    zone: dropZones[i],
                    currentDragData: currentDragData,
                    onMoveCards: _moveCards,
                    getCardsFromIndex: _getCardsFromIndex,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                  ),
                ),
              const SizedBox(width: 16.0),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100, // 100 + 16 padding
                    width:
                        (MediaQuery.of(context).size.width -
                            64 -
                            7 *
                                ((120 * calculatedScale) +
                                    8)), // 4 zones + 3 gaps
                    child: GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 100.0 / 150.0, // 2:3 ratio

                      physics: NeverScrollableScrollPhysics(),
                      children:
                          dropZones
                              .where((zone) => zone.id.startsWith('goal'))
                              .map(
                                (zone) => DropZoneWidget(
                                  zone: zone,
                                  currentDragData: currentDragData,
                                  onMoveCards: _moveCards,
                                  getCardsFromIndex: _getCardsFromIndex,
                                  onDragStarted: _onDragStarted,
                                  onDragEnd: _onDragEnd,
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CardDeckAnim(
                        cards: deckCards,
                        onDragStarted: _onDragStarted,
                        onDragEnd: _onDragEnd,
                        currentDragData: currentDragData,
                        deckId: 'deck',
                        controller: deckController,
                        onReachEndOfDeck: onReachEndOfDeck,
                        scale: calculatedScale,
                        pileCards: pileCards,
                        isSolitaire: true,
                      ),
                      SizedBox(width: 16.0),
                      if (couldBeStuck)
                        ActionButton(
                          width: 200.0 * calculatedScale,
                          height: 75.0 * calculatedScale,

                          useFancyText: true,
                          text: Text(
                            "Stuck?",
                            style: TextStyle(
                              fontSize: 28.0 * calculatedScale,
                              color: Colors.white,
                            ),
                          ),
                          onTap: () {
                            deckController.unstuck();
                            setState(() {
                              couldBeStuck = false;
                              hasMovedCards = false;
                            });
                          },
                        ),
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
