import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/blitz_deck.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/deck.dart';
import 'package:deckly/widgets/drop_zone.dart';
import 'package:deckly/widgets/fancy_text.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:flutter/material.dart';

class Nertz extends StatefulWidget {
  final GamePlayer player;
  final List<GamePlayer> players;
  const Nertz({super.key, required this.player, required this.players});
  // const Nertz({super.key});
  @override
  _NertzState createState() => _NertzState();
}

class _NertzState extends State<Nertz> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<CardData> blitzDeck = [];
  List<BlitzPlayer> players = [];
  BlitzPlayer? currentPlayer;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  late StreamSubscription<dynamic> _playersSub;

  final CardDeckController deckController = CardDeckController();
  final BlitzDeckController blitzDeckController = BlitzDeckController();
  NertzGameState gameState = NertzGameState.playing;
  DragData currentDragData = DragData(
    cards: [],
    sourceZoneId: '',
    sourceIndex: -1,
  );

  @override
  void initState() {
    super.initState();
    _initializeData();
    initListeners();
  }

  void initListeners() {
    _dataSub = connectionService.gameDataStream.listen((dataMap) {
      print("Type of data: ${dataMap['type']}");
      if (dataMap['type'] == 'update_zone') {
        final zoneId = dataMap['zoneId'] as String;
        final cardsData = dataMap['cards'] as List;
        final cards =
            cardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();

        setState(() {
          final targetZone = dropZones.firstWhere((zone) => zone.id == zoneId);
          targetZone.cards.clear();
          targetZone.cards.addAll(cards);
        });
      } else if (dataMap['type'] == 'blitz') {
        final playerData = dataMap['player'] as Map<String, dynamic>;
        final playersData = dataMap['players'] as List;

        final players =
            playersData
                .map((p) => BlitzPlayer.fromMap(p as Map<String, dynamic>))
                .toList();
        setState(() {
          this.players = players;
        });
        final player = BlitzPlayer.fromMap(playerData);
        if (player.id == currentPlayer!.id) {
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              Timer(Duration(seconds: 5), () {
                Navigator.of(context).pop();
                setState(() {
                  gameState = NertzGameState.leaderboard;
                });
              });
              return Dialog(
                backgroundColor: Colors.transparent,

                child: Container(
                  width: 400,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [styling.primaryColor, styling.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(2), // Creates the border thickness
                    decoration: BoxDecoration(
                      color: styling.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          player.name + " has Nertzed!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      } else if (dataMap['type'] == 'next_round') {
        nextRound();
      } else if (dataMap['type'] == 'end_game') {
        setState(() {
          gameState = NertzGameState.gameOver;
        });
      } else if (dataMap['type'] == 'update_player') {
        final playerData = dataMap['player'] as Map<String, dynamic>;
        final player = BlitzPlayer.fromMap(playerData);
        setState(() {
          players.firstWhere((p) => p.id == player.id).score = player.score;
          players.firstWhere((p) => p.id == player.id).blitzDeckSize =
              player.blitzDeckSize;
        });
      }
    });
  }

  List<BlitzPlayer> scoreGame() {
    List<BlitzPlayer> newPlayers = [...players];
    newPlayers.where((p) => p.id != currentPlayer!.id).forEach((player) {
      player.score -= player.blitzDeckSize;
    });
    newPlayers.firstWhere((p) => p.id == currentPlayer!.id).score += 5;
    //get all the public drop zones
    List<DropZoneData> publicZones =
        dropZones
            .where((zone) => zone.isPublic && zone.cards.isNotEmpty)
            .toList();
    //get the cards in the public drop zones
    List<CardData> publicCards =
        publicZones.expand((zone) => zone.cards).toList();
    for (var card in publicCards) {
      newPlayers.firstWhere((p) => p.id == card.playedBy!).score += 1;
    }
    // Sort players by score
    newPlayers.sort((a, b) => b.score.compareTo(a.score));
    // Update the current player with the new score
    return newPlayers;
  }

  void onBlitz() async {
    List<BlitzPlayer> scoredPlayers = scoreGame();
    await connectionService.broadcastMessage({
      'type': 'blitz',
      'player': currentPlayer!.toMap(),
      'players': scoredPlayers.map((p) => p.toMap()).toList(),
    }, currentPlayer!.id);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Timer(Duration(seconds: 5), () {
          Navigator.of(context).pop();
          setState(() {
            gameState = NertzGameState.leaderboard;
          });
        });
        return Dialog(
          backgroundColor: Colors.transparent,

          child: Container(
            width: 400,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [styling.primaryColor, styling.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              margin: EdgeInsets.all(2), // Creates the border thickness
              decoration: BoxDecoration(
                color: styling.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "You Nertzed!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _initializeData() {
    currentPlayer = BlitzPlayer(
      id: widget.player.id,
      name: widget.player.name,
      score: 0,
      blitzDeckSize: 13,
    );
    players =
        widget.players.map((p) {
          return BlitzPlayer(
            id: p.id,
            name: p.name,
            score: 0,
            blitzDeckSize: 13,
          );
        }).toList();
    // players = [
    //   BlitzPlayer(id: '1', name: 'Player 1', score: 0, blitzDeckSize: 13),
    //   BlitzPlayer(id: '2', name: 'Player 2', score: 0, blitzDeckSize: 13),
    //   BlitzPlayer(id: '3', name: 'Player 3', score: 0, blitzDeckSize: 13),
    //   BlitzPlayer(id: '4', name: 'Player 4', score: 0, blitzDeckSize: 13),
    // ];
    // currentPlayer = players.firstWhere((p) => p.id == '1');
    List<CardData> shuffledDeck = [...fullDeck];
    shuffledDeck.shuffle();
    // Bottom 4 drop zones
    dropZones = [
      DropZoneData(
        id: 'pile1',
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[0]],
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile2',
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[1]],
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile3',
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[2]],
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile4',
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[3]],
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        scale: 1.0,
      ),
    ];
    shuffledDeck = shuffledDeck.sublist(4);

    // Add middle drop zones (goal zones)
    for (int i = 0; i < players.length * 4; i++) {
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
          isPublic: true,
        ),
      );
    }
    blitzDeck = shuffledDeck.sublist(0, 13);

    // Initialize deck cards
    deckCards = shuffledDeck.sublist(13);

    // Initialize blitz deck with some cards

    setState(() {});
  }

  void _moveCards(DragData dragData, String targetZoneId) async {
    final targetZone = dropZones.firstWhere((zone) => zone.id == targetZoneId);
    setState(() {
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
      }

      if (targetZone.isPublic) {
        print("Played to goal zone: ${targetZone.id}");
      }
      targetZone.cards.addAll(dragData.cards);
      dragData.cards.forEach((card) {
        card.playedBy = currentPlayer!.id; // Set the player who played the card
      });
    });
    if (targetZone.isPublic) {
      print("Played to goal zone: ${targetZone.id}");
      connectionService.broadcastMessage({
        'type': 'update_zone',
        'zoneId': targetZone.id,
        'cards': dragData.cards.map((c) => c.toMap()).toList(),
      }, currentPlayer!.id);
    }
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

  void onPlayedFromBlitzDeck() {
    players.firstWhere((p) => p.id == currentPlayer!.id).blitzDeckSize -= 1;
    currentPlayer!.blitzDeckSize -= 1;

    setState(() {});
    connectionService.broadcastMessage({
      'type': 'update_player',
      'player': currentPlayer!.toMap(),
    }, currentPlayer!.id);
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

  void nextRound() {
    //Clear all drop zones
    for (var zone in dropZones) {
      zone.cards.clear();
    }
    if (currentPlayer!.isHost) {
      // Reset blitz deck for all players
      for (var player in players) {
        player.blitzDeckSize = 13;
      }
      connectionService.broadcastMessage({
        'type': 'update_player',
        'player': currentPlayer!.toMap(),
      }, currentPlayer!.id);
      connectionService.broadcastMessage({
        'type': 'next_round',
      }, currentPlayer!.id);
    }
    // Reset deck cards
    deckCards.clear();
    List<CardData> shuffledDeck = [...fullDeck];
    shuffledDeck.shuffle();
    // Remove the first 13 cards for blitz deck
    blitzDeck = shuffledDeck.sublist(0, 13);
    //Take 4 cards for the bottom piles
    dropZones[0].cards = [shuffledDeck[0]];
    dropZones[1].cards = [shuffledDeck[1]];
    dropZones[2].cards = [shuffledDeck[2]];
    dropZones[3].cards = [shuffledDeck[3]];
    // Remaining cards for deck
    deckCards = shuffledDeck.sublist(4);

    // Reset blitz deck for all players
    setState(() {
      gameState = NertzGameState.playing;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _stateSub.cancel();
    _dataSub.cancel();
    _playersSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final calculatedScale = _calculateScale(context);

    // Update scale for all drop zones
    for (var zone in dropZones) {
      zone.scale = calculatedScale;
    }

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          connectionService.dispose();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: "Nertz",
            showBackButton: true,
            onBackButtonPressed: (context) {
              connectionService.dispose();
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: styling.backgroundColor,
        body: Container(
          height: double.infinity,
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child:
                gameState == NertzGameState.playing
                    ? buildPlayingScreen(calculatedScale)
                    : gameState == NertzGameState.leaderboard
                    ? buildLeaderboardScreen()
                    : buildGameOverScreen(),
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
        FancyWidget(
          child: Container(
            height: 100.0,
            width: double.infinity,

            child: Row(
              children: [
                for (var player in players.where(
                  (p) => p.id != currentPlayer!.id,
                ))
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              fontSize: 16.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            '${player.blitzDeckSize} nertz cards left',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.0),

        // Middle Section - Grid of drop zones (excluding bottom 4)
        LayoutBuilder(
          builder: (context, constraints) {
            final middleZones = dropZones.skip(4).toList();
            final availableWidth = constraints.maxWidth;

            // Calculate optimal grid layout with constraints
            // Minimum 3 columns, maximum 3 rows
            int bestCols = 3; // Start with minimum 3 columns
            final maxRows = 3;
            final minCols = 3;
            final maxCols =
                (middleZones.length / 1).ceil(); // Maximum possible columns

            for (int cols = minCols; cols <= maxCols; cols++) {
              final rows = (middleZones.length / cols).ceil();

              // Skip if it would exceed maximum rows
              if (rows > maxRows) continue;

              final gridWidth =
                  (cols * 116.0 * calculatedScale) + ((cols - 1) * 8.0);

              if (gridWidth <= availableWidth) {
                bestCols = cols;
              }
            }

            // Ensure we don't exceed max rows even with min columns
            final finalRows = (middleZones.length / bestCols).ceil();
            if (finalRows > maxRows) {
              bestCols = (middleZones.length / maxRows).ceil();
            }

            // Calculate the actual height needed based on the number of rows
            final actualRows = (middleZones.length / bestCols).ceil();
            final calculatedHeight =
                (actualRows * 186.0 * calculatedScale) +
                ((actualRows - 1) * 8.0) +
                4;

            return SizedBox(
              height: calculatedHeight,
              child: GridView.count(
                crossAxisCount: bestCols,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 100.0 / 150.0, // 2:3 ratio

                physics: NeverScrollableScrollPhysics(),
                children:
                    middleZones
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
            );
          },
        ),

        const SizedBox(height: 16.0),
        Stack(
          children: [
            // Background grid lines

            // Foreground content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side - 4 drop zones
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < 4; i++)
                      Container(
                        margin: EdgeInsets.only(right: i < 3 ? 8.0 : 0.0),
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

                SizedBox(width: 8.0),
                //Create a vertical divider
                Container(
                  width: 2.0,
                  height: 330.0 * calculatedScale,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [styling.primaryColor, styling.secondaryColor],
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                SizedBox(width: 8.0),

                // Right side - Deck area
                Column(
                  children: [
                    BlitzDeck(
                      blitzDeck: blitzDeck,
                      currentDragData: currentDragData,
                      onDragStarted: _onDragStarted,
                      onDragEnd: _onDragEnd,
                      scale: calculatedScale,
                      controller: blitzDeckController,
                      onDragCompleted: onPlayedFromBlitzDeck,
                      onTapBlitz: onBlitz,
                    ),
                    CardDeck(
                      cards: deckCards,
                      onDragStarted: _onDragStarted,
                      onDragEnd: _onDragEnd,
                      currentDragData: currentDragData,
                      deckId: 'deck',
                      controller: deckController,
                      scale: calculatedScale,
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

  Widget buildLeaderboardScreen() {
    // Sort players by score
    players.sort((a, b) => b.score.compareTo(a.score));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FancyWidget(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: Text(
                  "Leaderboard",
                  style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ListView.builder(
                itemCount: players.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    title: Text(
                      '${index + 1}. ${player.name}: ${player.score}',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16.0),
        if (currentPlayer!.getIsHost())
          ActionButton(
            onTap: () {
              nextRound();
            },
            text: Text(
              'Next Round',
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
        if (currentPlayer!.getIsHost()) SizedBox(height: 16.0),
        if (currentPlayer!.getIsHost())
          ActionButton(
            onTap: () {
              connectionService.broadcastMessage({
                'type': 'end_game',
              }, currentPlayer!.id);

              setState(() {
                gameState = NertzGameState.gameOver;
              });
            },
            text: Text(
              'End Game',
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget buildGameOverScreen() {
    // Sort players by score
    players.sort((a, b) => b.score.compareTo(a.score));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FancyText(
          text: Text(
            'Game Over',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          "Winner: ${players.first.name}",
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        const SizedBox(height: 16.0),
        FancyWidget(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: Text(
                  "Final Scores",
                  style: TextStyle(
                    fontSize: 24.0,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ListView.builder(
                itemCount: players.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final player = players[index];
                  return ListTile(
                    title: Text(
                      '${index + 1}. ${player.name}: ${player.score}',
                      style: TextStyle(color: Colors.white, fontSize: 18.0),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
