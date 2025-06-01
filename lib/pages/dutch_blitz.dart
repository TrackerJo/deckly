import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/blitz_deck.dart';
import 'package:deckly/widgets/deck.dart';
import 'package:deckly/widgets/drop_zone.dart';
import 'package:flutter/material.dart';

class DutchBlitz extends StatefulWidget {
  final GamePlayer player;
  final List<GamePlayer> players;
  const DutchBlitz({super.key, required this.player, required this.players});
  @override
  _DutchBlitzState createState() => _DutchBlitzState();
}

class _DutchBlitzState extends State<DutchBlitz> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<CardData> blitzDeck = [];
  List<BlitzPlayer> players = [];
  BlitzPlayer? currentPlayer;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;

  final CardDeckController deckController = CardDeckController();
  final BlitzDeckController blitzDeckController = BlitzDeckController();
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
    _dataSub = nearbyService.dataReceivedSubscription(
      callback: (data) {
        print("dataReceivedSubscription: ${jsonEncode(data)}");
        Map<String, dynamic> dataMap;

        if (data is String) {
          // If data is a string, decode it
          try {
            dataMap = jsonDecode(data);
          } catch (e) {
            print("Error decoding JSON string: $e");
            return;
          }
        } else if (data is Map) {
          // If data is already a map, cast it
          dataMap = jsonDecode(Map<String, dynamic>.from(data)["message"]);
        } else {
          print("Unexpected data type: ${data.runtimeType}");
          return;
        }
        print("Type of data: ${dataMap['type']}");
        if (dataMap['type'] == 'update_zone') {
          final zoneId = dataMap['zoneId'] as String;
          final cardsData = dataMap['cards'] as List;
          final cards =
              cardsData
                  .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                  .toList();

          setState(() {
            final targetZone = dropZones.firstWhere(
              (zone) => zone.id == zoneId,
            );
            targetZone.cards.clear();
            targetZone.cards.addAll(cards);
          });
        } else if (dataMap['type'] == 'playerList') {
          final playersData = dataMap['players'] as List;
          print("Received player list: ${jsonEncode(playersData)}");
          setState(() {
            players.clear();
            players.addAll(
              playersData
                  .map((p) => BlitzPlayer.fromMap(p as Map<String, dynamic>))
                  .toList(),
            );
          });
        }
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
    for (int i = 0; i < 16; i++) {
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
    });
    if (targetZone.isPublic) {
      print("Played to goal zone: ${targetZone.id}");
      for (var player in players) {
        if (player.id != currentPlayer!.id) {
          nearbyService.sendMessage(
            player.id,
            jsonEncode({
              'type': 'update_zone',
              'zoneId': targetZone.id,
              'cards': dragData.cards.map((c) => c.toMap()).toList(),
            }),
          );
        }
      }
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
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _stateSub.cancel();
    _dataSub.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final calculatedScale = _calculateScale(context);

    // Update scale for all drop zones
    for (var zone in dropZones) {
      zone.scale = calculatedScale;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Dutch Blitz'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[800],
      ),
      body: Container(
        height: double.infinity,
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Container (100px)
              Container(
                height: 100.0,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: Row(
                  children: [
                    for (var player in players.where(
                      (p) => p.id != currentPlayer!.id,
                    ))
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(player.name, style: TextStyle(fontSize: 16.0)),
                            SizedBox(height: 4.0),
                            Text(
                              'Blitz Cards Left: ${player.blitzDeckSize}',
                              style: TextStyle(fontSize: 14.0),
                            ),
                          ],
                        ),
                      ),
                  ],
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
                      (middleZones.length / 1)
                          .ceil(); // Maximum possible columns

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
                      ((actualRows - 1) * 8.0);

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
                  Container(
                    width: double.infinity,
                    height:
                        ((12) * 35 + 175) *
                        calculatedScale, // 13 cards with spacing
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!, width: 1.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
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

                      SizedBox(width: 16.0),

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
          ),
        ),
      ),
    );
  }
}
