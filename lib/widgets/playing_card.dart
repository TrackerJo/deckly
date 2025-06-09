import 'package:deckly/api/shared_prefs.dart';
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
  final bool isDutchBlitz;
  final bool isCardPlayable;

  const DraggableCardWidget({
    super.key,
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
    this.isDutchBlitz = false,
    this.isCardPlayable = true, // Default to true for player's hand
  });

  @override
  Widget build(BuildContext context) {
    final cardsBeingDragged = getCardsFromIndex(zoneId, index);

    // Check if this card should be hidden because a card above it is being dragged
    bool shouldBeHidden = false;

    if (zoneId == 'hand') {
      // For hand, only hide the exact card being dragged
      shouldBeHidden =
          currentDragData.sourceIndex == index &&
          currentDragData.sourceZoneId == zoneId;
    } else {
      // For other zones (like stacks), hide all cards from drag index onwards
      shouldBeHidden =
          currentDragData.sourceIndex != -1 &&
          currentDragData.sourceZoneId == zoneId &&
          index >= currentDragData.sourceIndex;
    }

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
        SharedPrefs.hapticInputSelect();
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
        SharedPrefs.hapticInputSelect();
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
          isDutchBlitz: isDutchBlitz,
        ),
      ),
      childWhenDragging:
          Container(), // Empty container - card disappears while dragging
      child: CardContent(
        card: card,
        scale: scale,
        isDutchBlitz: isDutchBlitz,
        isCardPlayable: isCardPlayable,
      ),
    );
  }
}

class DragFeedback extends StatelessWidget {
  final List<CardData> cards;
  final StackMode stackMode;
  final double scale;
  final bool isDutchBlitz;

  const DragFeedback({
    Key? key,
    required this.cards,
    required this.stackMode,
    this.scale = 1.0,
    this.isDutchBlitz = false,
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
                child: CardContent(
                  card: card,
                  isDragging: true,
                  scale: scale,
                  isDutchBlitz: isDutchBlitz,
                ),
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
                child: CardContent(
                  card: card,
                  isDragging: true,
                  scale: scale,
                  isDutchBlitz: isDutchBlitz,
                ),
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
  final bool isDutchBlitz;
  final Function(CardData)? onTap;
  final bool isCardPlayable;

  const CardContent({
    Key? key,
    required this.card,
    this.isDragging = false,
    this.scale = 1.0,
    this.isDutchBlitz = false,
    this.onTap,
    this.isCardPlayable = true, // Default to true for player's hand
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
    return isDutchBlitz ? dutchBlitzCard(context) : playingCard();
  }

  Widget playingCard() {
    return GestureDetector(
      onTap:
          onTap != null
              ? () {
                SharedPrefs.hapticInputSelect();
                onTap!(card);
              }
              : null,
      child: Container(
        height: 150 * scale,
        width: 100 * scale,
        decoration: BoxDecoration(
          color:
              card.isFaceUp
                  ? isCardPlayable
                      ? Colors.white
                      : Colors.grey[300]
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
                : ClipRRect(
                  borderRadius: BorderRadius.circular(8 * scale),

                  child: Padding(
                    padding: EdgeInsets.all(isDutchBlitz ? 0 : 8.0 * scale),
                    child: Center(
                      child: Image.asset(
                        'assets/card_back.png', // Replace with your card back image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget dutchBlitzCard(BuildContext context) {
    print(MediaQuery.of(context).size.width / 2);
    return Container(
      height: 150 * scale,
      width: 100 * scale,
      decoration: BoxDecoration(
        color:
            card.isFaceUp
                ? card.suit == CardSuit.clubs
                    ? Color.fromARGB(255, 255, 213, 4)
                    : card.suit == CardSuit.spades
                    ? Color.fromARGB(255, 1, 152, 71)
                    : card.suit == CardSuit.hearts
                    ? Color.fromARGB(255, 216, 60, 15)
                    : Color.fromARGB(255, 0, 136, 192)
                : Colors.transparent,

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
                  Positioned(
                    top: 4 * scale,
                    left: 4 * scale,
                    child: Image.asset(
                      card.suit == CardSuit.clubs
                          ? "assets/yellow_girl.png"
                          : card.suit == CardSuit.spades
                          ? "assets/green_girl.png"
                          : card.suit == CardSuit.hearts
                          ? "assets/red_boy.png"
                          : "assets/blue_boy.png",
                      width: 30 * scale,
                      height: 45 * scale,
                      fit: BoxFit.cover,

                      // Replace with your Dutch Blitz card background image
                    ),
                  ),
                  // Top-left value and suit
                  Positioned(
                    top: 4 * scale,
                    left:
                        card.value == 10
                            ? (100 * scale) / 2 - 20 * scale
                            : (100 * scale) / 2 - 12 * scale,
                    child: Text(
                      cardNumberToString(card.value) == "A"
                          ? "1"
                          : cardNumberToString(card.value),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: card.value == 10 ? 15 : 16,
                      ),
                    ),
                  ),
                  // Bottom-right value and suit (rotated)
                  Positioned(
                    bottom: 4 * scale,
                    //Center to the bottom middle
                    left:
                        card.value == 10
                            ? (100 * scale) / 2 - 18 * scale
                            : (100 * scale) / 2 - 10 * scale,
                    child: Transform.rotate(
                      angle: 3.1416, // 180 degrees in radians
                      child: Text(
                        cardNumberToString(card.value) == "A"
                            ? "1"
                            : cardNumberToString(card.value),
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: card.value == 10 ? 15 : 16,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4 * scale,
                    left: 4 * scale,
                    child: Image.asset(
                      card.suit == CardSuit.clubs
                          ? "assets/yellow_girl.png"
                          : card.suit == CardSuit.spades
                          ? "assets/green_girl.png"
                          : card.suit == CardSuit.hearts
                          ? "assets/red_boy.png"
                          : "assets/blue_boy.png",
                      width: 30 * scale,
                      height: 45 * scale,
                      fit: BoxFit.cover,

                      // Replace with your Dutch Blitz card background image
                    ),
                  ),
                  Positioned(
                    top: 4 * scale,
                    right: 4 * scale,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        card.suit == CardSuit.clubs
                            ? "assets/yellow_girl.png"
                            : card.suit == CardSuit.spades
                            ? "assets/green_girl.png"
                            : card.suit == CardSuit.hearts
                            ? "assets/red_boy.png"
                            : "assets/blue_boy.png",
                        width: 30 * scale,
                        height: 45 * scale,
                        fit: BoxFit.cover,

                        // Replace with your Dutch Blitz card background image
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4 * scale,
                    right: 4 * scale,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        card.suit == CardSuit.clubs
                            ? "assets/yellow_girl.png"
                            : card.suit == CardSuit.spades
                            ? "assets/green_girl.png"
                            : card.suit == CardSuit.hearts
                            ? "assets/red_boy.png"
                            : "assets/blue_boy.png",
                        width: 30 * scale,
                        height: 45 * scale,
                        fit: BoxFit.cover,

                        // Replace with your Dutch Blitz card background image
                      ),
                    ),
                  ),
                  // Center suit symbol (large, faded)
                  Center(
                    child: Image.asset(
                      card.suit == CardSuit.clubs
                          ? "assets/yellow_center.png"
                          : card.suit == CardSuit.spades
                          ? "assets/green_center.png"
                          : card.suit == CardSuit.hearts
                          ? "assets/red_center.png"
                          : "assets/blue_center.png",
                      // Replace with your center image
                      fit: BoxFit.cover,
                      width: 50 * scale,
                      height: 50 * scale,
                    ),
                  ),
                ],
              )
              : ClipRRect(
                borderRadius: BorderRadius.circular(8 * scale),

                child: Center(
                  child: Image.asset(
                    'assets/blitz_card_back.png',
                    // Replace with your card back image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
    );
  }
}
