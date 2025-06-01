import 'dart:math' as math;
import 'package:deckly/constants.dart';
import 'package:deckly/widgets/blitz_deck.dart';
import 'package:deckly/widgets/deck.dart';
import 'package:deckly/widgets/drop_zone.dart';
import 'package:flutter/material.dart';

class DraggableCardsPage extends StatefulWidget {
  @override
  _DraggableCardsPageState createState() => _DraggableCardsPageState();
}

class _DraggableCardsPageState extends State<DraggableCardsPage> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<CardData> blitzDeck = [];
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
  }

  void _initializeData() {
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
        cards: [CardData(id: '1', value: 1, suit: CardSuit.hearts)],
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
        cards: [
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
          CardData(id: '4', value: 4, suit: CardSuit.clubs),
        ],
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile3',
        stackMode: StackMode.spaced,
        cards: [],
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
        cards: [],
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        scale: 1.0,
      ),
    ];

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
        ),
      );
    }

    // Initialize deck cards
    deckCards = [
      CardData(id: '7', value: 7, suit: CardSuit.diamonds),
      CardData(id: '8', value: 8, suit: CardSuit.diamonds),
      CardData(id: '9', value: 9, suit: CardSuit.diamonds),
      CardData(id: '10', value: 10, suit: CardSuit.diamonds),
      CardData(id: 'J', value: 11, suit: CardSuit.spades),
      CardData(id: 'Q', value: 12, suit: CardSuit.spades),
      CardData(id: 'K', value: 13, suit: CardSuit.spades),
    ];

    // Initialize blitz deck with some cards
    blitzDeck = [CardData(id: '1', value: 1, suit: CardSuit.hearts)];

    setState(() {});
  }

  void _moveCards(DragData dragData, String targetZoneId) {
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

      final targetZone = dropZones.firstWhere(
        (zone) => zone.id == targetZoneId,
      );
      targetZone.cards.addAll(dragData.cards);
    });
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
                child: Center(
                  child: Text(
                    'Future Use Area',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
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
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - 4 drop zones
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < 4; i++)
                              Container(
                                margin: EdgeInsets.only(
                                  right: i < 3 ? 8.0 : 0.0,
                                ),
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
                        Expanded(
                          flex: 1,
                          child: Column(
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
                        ),
                      ],
                    ),
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
