import 'package:deckly/constants.dart';
import 'package:flutter/material.dart';

class DraggableCardWidget extends StatelessWidget {
  final CardData card;
  final String zoneId;
  final int index;
  final int totalCards;
  final DragData currentDragData;
  final Function(String, int) getCardsFromIndex;
  final Function(DragData) onDragStarted;
  final Function() onDragEnd;
  final StackMode stackMode;
  final Function()? onDragCompleted;
  final double scale;

  const DraggableCardWidget({
    Key? key,
    required this.card,
    required this.zoneId,
    required this.index,
    required this.totalCards,
    required this.currentDragData,
    required this.getCardsFromIndex,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.stackMode,
    this.onDragCompleted,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardsBeingDragged = getCardsFromIndex(zoneId, index);

    // Check if this card should be hidden because a card above it is being dragged
    bool shouldBeHidden =
        currentDragData.sourceIndex != -1 &&
        currentDragData.sourceZoneId == zoneId &&
        index >= currentDragData.sourceIndex;

    if (shouldBeHidden) {
      return Container(); // Hide this card completely
    }

    return Draggable<DragData>(
      data: DragData(
        cards: cardsBeingDragged,
        sourceZoneId: zoneId,
        sourceIndex: index,
      ),
      onDragStarted: () {
        onDragStarted(
          DragData(
            cards: cardsBeingDragged,
            sourceZoneId: zoneId,
            sourceIndex: index,
          ),
        );
      },
      onDragEnd: (details) {
        onDragEnd();
      },
      onDragCompleted: () {
        // Call the completion callback if provided
        if (onDragCompleted != null) {
          onDragCompleted!();
        }
      },
      onDraggableCanceled: (velocity, offset) {
        onDragEnd();
      },
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: DragFeedback(
          cards: cardsBeingDragged,
          stackMode: stackMode,
          scale: scale,
        ),
      ),
      childWhenDragging:
          Container(), // Empty container - card disappears while dragging
      child: CardContent(card: card, scale: scale),
    );
  }
}

class DragFeedback extends StatelessWidget {
  final List<CardData> cards;
  final StackMode stackMode;
  final double scale;

  const DragFeedback({
    Key? key,
    required this.cards,
    required this.stackMode,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (stackMode == StackMode.overlay) {
      return _buildOverlayDragFeedback();
    } else {
      return _buildSpacedDragFeedback();
    }
  }

  Widget _buildOverlayDragFeedback() {
    return Container(
      width:
          (100 * scale) +
          (cards.length - 1) * (5 * scale), // Account for horizontal offset
      height: (150 * scale) + (cards.length - 1) * (20 * scale),
      child: Stack(
        children:
            cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;

              return Positioned(
                top: index * (20.0 * scale),
                left: index * (5.0 * scale),
                child: CardContent(card: card, isDragging: true, scale: scale),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSpacedDragFeedback() {
    return Container(
      width: 100 * scale, // Account for horizontal offset
      height: (150 * scale) + (cards.length - 1) * (35 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * scale),
      ), // Account for vertical offset
      child: Stack(
        children:
            cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;

              return Positioned(
                top: index * (35.0 * scale),
                left: 1 * scale,
                child: CardContent(card: card, isDragging: true, scale: scale),
              );
            }).toList(),
      ),
    );
  }
}

class CardContent extends StatelessWidget {
  final CardData card;
  final bool isDragging;
  final double scale;

  const CardContent({
    Key? key,
    required this.card,
    this.isDragging = false,
    this.scale = 1.0,
  }) : super(key: key);

  String cardNumberToString(int value) {
    switch (value) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150 * scale,
      width: 100 * scale,
      decoration: BoxDecoration(
        color:
            card.isFaceUp
                ? Colors.white
                : const Color.fromARGB(255, 77, 118, 163),
        borderRadius: BorderRadius.circular(8 * scale),
        boxShadow:
            isDragging
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ]
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2 * scale,
                    offset: Offset(0, 1 * scale),
                  ),
                ],
      ),
      child:
          card.isFaceUp
              ? Stack(
                children: [
                  // Top-left value and suit
                  Positioned(
                    top: 4 * scale,
                    left: 4 * scale,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      direction: Axis.vertical,
                      spacing: -6, // Reduced spacing
                      children: [
                        Text(
                          cardNumberToString(card.value),
                          style: TextStyle(
                            color:
                                card.suit == CardSuit.clubs ||
                                        card.suit == CardSuit.spades
                                    ? Colors.black
                                    : Colors.red[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        // Reduced spacing
                        Text(
                          card.suit.toIcon(),
                          style: TextStyle(
                            color:
                                card.suit == CardSuit.clubs ||
                                        card.suit == CardSuit.spades
                                    ? Colors.black
                                    : Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bottom-right value and suit (rotated)
                  Positioned(
                    bottom: 4 * scale,
                    right: 4 * scale,
                    child: Transform.rotate(
                      angle: 3.1416, // 180 degrees in radians
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        direction: Axis.vertical,
                        spacing: -6,

                        children: [
                          Text(
                            cardNumberToString(card.value),
                            style: TextStyle(
                              color:
                                  card.suit == CardSuit.clubs ||
                                          card.suit == CardSuit.spades
                                      ? Colors.black
                                      : Colors.red[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            card.suit.toIcon(),
                            style: TextStyle(
                              color:
                                  card.suit == CardSuit.clubs ||
                                          card.suit == CardSuit.spades
                                      ? Colors.black
                                      : Colors.red[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Center suit symbol (large, faded)
                  Center(
                    child: Opacity(
                      opacity: 0.15,
                      child: Text(
                        card.suit.toIcon(),
                        style: TextStyle(
                          color:
                              card.suit == CardSuit.clubs ||
                                      card.suit == CardSuit.spades
                                  ? Colors.black
                                  : Colors.red[700],
                          fontSize: 40 * scale,
                        ),
                      ),
                    ),
                  ),
                ],
              )
              : Padding(
                padding: EdgeInsets.all(8.0 * scale),
                child: Center(
                  child: Image.asset(
                    'assets/card_back.png', // Replace with your card back image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
    );
  }
}
