import 'dart:math';

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

class CardFlip extends StatefulWidget {
  final CardData card;
  final double scale; // Default scale, can be adjusted
  final bool isDutchBlitz;
  final bool isCrazyEights;
  final double handScale; // Optional parameter for Crazy Eights
  const CardFlip({
    super.key,
    required this.card,
    required this.scale,
    this.isDutchBlitz = false,
    this.isCrazyEights = false, // Optional parameter for Crazy Eights
    this.handScale = 1.0, // Default to 1.0 if not provided
  });

  @override
  State<CardFlip> createState() => _CardFlipState();
}

class _CardFlipState extends State<CardFlip> with TickerProviderStateMixin {
  late AnimationController _controller;
  bool isFront = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: widget.isCrazyEights ? 550 : 200),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * pi;

        print("HAND SCALE: ${widget.handScale}");

        Matrix4 transform;
        if (widget.isCrazyEights) {
          //Calculate the vertical translation based on distance from card to bottom of screen
          final screenHeight = MediaQuery.of(context).size.height;
          final cardHeight = 150 * widget.scale;

          // // Get the current widget's position on screen
          // final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          // double cardTopPosition = 0.0;

          // if (renderBox != null) {
          //   final position = renderBox.localToGlobal(Offset.zero);
          //   cardTopPosition = position.dy;
          // }

          // // Calculate distance from bottom of card to bottom of screen
          // final cardBottomPosition = cardTopPosition + cardHeight;
          // final distanceToBottom = screenHeight - cardBottomPosition + 75;

          // // Use distance to calculate translateY
          // // You can adjust this formula based on desired animation effect
          // double translateY = distanceToBottom * _controller.value;

          transform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..translate(
                  -(12 * widget.scale + 100 * widget.scale),
                ) // Move down as it flips
                ..rotateX(-angle);
        } else {
          final translateX =
              -(12 * widget.scale + 100 * widget.scale) +
              (100 * widget.scale * 2 + 12 * widget.scale) * _controller.value;
          transform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..translate(translateX, 0.0, 0.0) // Move right as it flips
                ..rotateY(angle); // Flip on Y axis
        }

        return Transform(
          transform: transform,
          alignment: widget.isCrazyEights ? Alignment.center : null,
          child:
              !isFrontImage(angle.abs())
                  ? Transform(
                    alignment: Alignment.center,
                    transform: (Matrix4.identity()..rotateX(pi)),

                    child: CardContent(
                      card: widget.card,
                      scale: widget.scale,
                      flipCenter:
                          !widget
                              .isCrazyEights, // Flip center for player's hand
                      isDutchBlitz: widget.isDutchBlitz,
                      flipX:
                          widget
                              .isCrazyEights, // Flip horizontally for Crazy Eights
                    ),
                  )
                  : CardContent(
                    card: CardData(
                      id: 'deck_back',
                      value: 1,
                      suit: CardSuit.hearts, // Placeholder suit
                      isFaceUp: false,
                    ),
                    scale: widget.scale,
                    isDutchBlitz: widget.isDutchBlitz,
                  ),
        );
      },
    );
  }

  bool isFrontImage(double angle) {
    final degree90 = pi / 2;
    final degree270 = 3 * pi / 2;

    return angle <= degree90 || angle >= degree270;
  }
}

class CardContent extends StatelessWidget {
  final CardData card;
  final bool isDragging;
  final double scale;
  final bool isDutchBlitz;
  final Function(CardData)? onTap;
  final bool isCardPlayable;
  final bool flipCenter;
  final bool flipX;

  const CardContent({
    Key? key,
    required this.card,
    this.isDragging = false,
    this.scale = 1.0,
    this.isDutchBlitz = false,
    this.onTap,
    this.isCardPlayable = true,
    this.flipX = false, // Default to false for normal cards
    this.flipCenter = false, // Default to true for player's hand
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

  double idealDutchFontSize() {
    // Adjust the range as needed
    //  final maxWidth = (30 * scale);
    // final maxHeight = (45 * scale);
    // final fontSize = min(maxWidth / 2, maxHeight / 2);
    // return fontSize.clamp(12.0, 18.0);
    final double containerWidth = 30 * scale;

    // Base font sizes for different card values based on their visual width
    Map<String, double> baseFontSizes = {
      '1': 18.0, // Narrow character
      '2': 16.0, // Medium width
      '3': 16.0, // Medium width
      '4': 15.0, // Medium width
      '5': 16.0, // Medium width
      '6': 16.0, // Medium width
      '7': 16.0, // Medium width
      '8': 15.0, // Medium width
      '9': 15.0, // Medium width
      '10': 12.0, // Widest - two characters
      'J': 16.0, // Medium width
      'Q': 14.0, // Wide character
      'K': 15.0, // Medium-wide
      'A': 16.0, // Medium width
    };

    // Get the display string for the card
    String displayValue = cardNumberToString(card.value);
    if (displayValue == "A")
      displayValue = "1"; // Dutch Blitz uses "1" instead of "A"

    // Get base font size for this character/string
    double baseFontSize = baseFontSizes[displayValue] ?? 16.0;

    // Scale the font size based on the scale factor
    double scaledFontSize = baseFontSize;

    // Ensure minimum readability
    double minFontSize = 8.0 * scale;

    // Ensure maximum size doesn't exceed container
    double maxFontSize = containerWidth * 0.8; // 80% of container width

    // Apply constraints
    scaledFontSize = scaledFontSize.clamp(minFontSize, maxFontSize);

    return scaledFontSize;
  }

  @override
  Widget build(BuildContext context) {
    print("FLIP X: $flipX");
    return isDutchBlitz
        ? scale < 0.5
            ? nordicDashCardMini(context)
            : nordicDashCard(context)
        : scale < 0.4
        ? playingCardMini()
        : playingCard();
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
                          if (card.value > 0)
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
                          if (card.value > 0)
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
                          if (card.value == 0)
                            SizedBox(
                              width: 2,
                              child: Text(
                                "Joker",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      card.suit == CardSuit.clubs ||
                                              card.suit == CardSuit.spades
                                          ? Colors.black
                                          : Colors.red[700],
                                ),
                              ), // Adjust height as needed
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
                            if (card.value > 0)
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
                            if (card.value > 0)
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
                            if (card.value == 0)
                              SizedBox(
                                width: 2,
                                child: Text(
                                  "Joker",

                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.bold,

                                    color:
                                        card.suit == CardSuit.clubs ||
                                                card.suit == CardSuit.spades
                                            ? Colors.black
                                            : Colors.red[700],
                                  ),
                                ), // Adjust height as needed
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Center suit symbol (large, faded)
                    if (flipCenter && card.value > 0)
                      Transform.flip(
                        flipY: true,
                        child: Center(
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
                      )
                    else if (card.value > 0 && flipX)
                      Transform.flip(
                        flipX: true,
                        child: Center(
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
                      )
                    else if (card.value > 0)
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
                    if (flipCenter && card.value == 0)
                      Transform.flip(
                        flipY: true,
                        child: Center(
                          child: Image.asset(
                            'assets/joker.png',
                            scale: 0.5, // Replace with your joker image
                          ),
                        ),
                      )
                    else if (card.value == 0 && flipX)
                      Transform.flip(
                        flipX: true,
                        child: Center(
                          child: Image.asset(
                            'assets/joker.png',
                            scale: 0.5, // Replace with your joker image
                          ),
                        ),
                      )
                    else if (card.value == 0)
                      Center(
                        child: SizedBox(
                          width: 120 * scale,
                          height: 120 * scale,
                          child: Image.asset(
                            'assets/joker.png',
                            scale: 0.5, // Replace with your joker image
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

  Widget playingCardMini() {
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

                    // Center suit symbol (large, faded)
                    Center(
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
                              fontSize: 18,
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
                    child: Transform.flip(
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
                  // Top-left value and suit
                  Positioned(
                    top: 4 * scale,
                    left: 4 * scale + (30 * scale),
                    child: Transform.flip(
                      child: Container(
                        width: (30 * scale),

                        child: Transform.flip(
                          flipX: flipCenter,
                          child: Text(
                            card.value.toString(),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: idealDutchFontSize(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom-right value and suit (rotated)
                  Positioned(
                    bottom: 4 * scale,
                    //Center to the bottom middle
                    left: 4 * scale + (30 * scale),
                    child: Transform.rotate(
                      angle: 3.1416, // 180 degrees in radians
                      child: Transform.flip(
                        flipX: flipCenter,
                        // flipX: true,
                        child: SizedBox(
                          width: (30 * scale),
                          child: Text(
                            cardNumberToString(card.value) == "A"
                                ? "1"
                                : cardNumberToString(card.value),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: idealDutchFontSize(),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4 * scale,
                    left: 4 * scale,
                    child: Transform.flip(
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

  Widget dutchBlitzCardMini(BuildContext context) {
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

                  // Bottom-right value and suit (rotated)
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
                    child: Text(
                      card.value.toString(),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: card.value == 10 ? 17 : 18,
                      ),
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

  Widget nordicDashCard(BuildContext context) {
    return Container(
      height: 150 * scale,
      width: 100 * scale,
      decoration: BoxDecoration(
        color:
            card.isFaceUp
                ? card.suit == CardSuit.clubs
                    ? Color.fromARGB(255, 255, 180, 0) // Brighter orange/yellow
                    : card.suit == CardSuit.spades
                    ? Color.fromARGB(255, 255, 20, 147) // Hot pink/magenta
                    : card.suit == CardSuit.hearts
                    ? Color.fromARGB(255, 0, 255, 100) // Bright green
                    : Color.fromARGB(255, 0, 191, 255)
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
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      direction: Axis.vertical,
                      spacing: -6, // Reduced spacing
                      children: [
                        Text(
                          card.value.toString(),
                          style: TextStyle(
                            color: Colors.black,

                            fontWeight: FontWeight.bold,
                            fontSize: 16,
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
                            card.value.toString(),
                            style: TextStyle(
                              color: Colors.black,

                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (flipCenter)
                    Transform.flip(
                      flipY: true,
                      child: Center(
                        child: Image.asset(
                          card.suit == CardSuit.clubs
                              ? "assets/nordic_girl.png"
                              : card.suit == CardSuit.spades
                              ? "assets/nordic_girl.png"
                              : card.suit == CardSuit.hearts
                              ? "assets/nordic_guy.png"
                              : "assets/nordic_guy.png",
                          width: 30 * scale,
                          height: 45 * scale,
                          fit: BoxFit.cover,

                          // Replace with your Dutch Blitz card background image
                        ),
                      ),
                    )
                  else
                    Center(
                      child: Image.asset(
                        card.suit == CardSuit.clubs
                            ? "assets/nordic_girl.png"
                            : card.suit == CardSuit.spades
                            ? "assets/nordic_girl.png"
                            : card.suit == CardSuit.hearts
                            ? "assets/nordic_guy.png"
                            : "assets/nordic_guy.png",
                        width: 30 * scale,
                        height: 45 * scale,
                        fit: BoxFit.cover,

                        // Replace with your Dutch Blitz card background image
                      ),
                    ),
                ],
              )
              : ClipRRect(
                borderRadius: BorderRadius.circular(8 * scale),

                child: Center(
                  child: Image.asset(
                    'assets/snowflake.png',
                    // Replace with your card back image
                    fit: BoxFit.fill,
                  ),
                ),
              ),
    );
  }

  Widget nordicDashCardMini(BuildContext context) {
    return Container(
      height: 150 * scale,
      width: 100 * scale,
      decoration: BoxDecoration(
        color:
            card.isFaceUp
                ? card.suit == CardSuit.clubs
                    ? Color.fromARGB(255, 255, 180, 0) // Brighter orange/yellow
                    : card.suit == CardSuit.spades
                    ? Color.fromARGB(255, 255, 20, 147) // Hot pink/magenta
                    : card.suit == CardSuit.hearts
                    ? Color.fromARGB(255, 0, 255, 100) // Bright green
                    : Color.fromARGB(255, 0, 191, 255)
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
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      direction: Axis.vertical,
                      spacing: -6, // Reduced spacing
                      children: [
                        Text(
                          card.value.toString(),
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: card.value == 10 ? 17 : 18,
                          ),
                        ),
                        const SizedBox(
                          height: 8,
                        ), // Add some space between value and suit
                        // Reduced spacing
                        Image.asset(
                          card.suit == CardSuit.clubs
                              ? "assets/nordic_girl.png"
                              : card.suit == CardSuit.spades
                              ? "assets/nordic_girl.png"
                              : card.suit == CardSuit.hearts
                              ? "assets/nordic_guy.png"
                              : "assets/nordic_guy.png",
                          width: 40 * scale,
                          height: 55 * scale,
                          fit: BoxFit.cover,

                          // Replace with your Dutch Blitz card background image
                        ),
                      ],
                    ),
                  ),

                  // Center suit symbol (large, faded)
                ],
              )
              : ClipRRect(
                borderRadius: BorderRadius.circular(8 * scale),

                child: Center(
                  child: Image.asset(
                    'assets/reindeer.png',
                    // Replace with your card back image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
    );
  }
}
