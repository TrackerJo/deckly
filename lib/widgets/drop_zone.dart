import 'package:deckly/constants.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';

class DropZoneWidget extends StatelessWidget {
  final DropZoneData zone;
  final DragData currentDragData;
  final Function(DragData, String) onMoveCards;
  final Function(String, int) getCardsFromIndex;
  final Function(DragData) onDragStarted;
  final Function() onDragEnd;

  const DropZoneWidget({
    Key? key,
    required this.zone,
    required this.currentDragData,
    required this.onMoveCards,
    required this.getCardsFromIndex,
    required this.onDragStarted,
    required this.onDragEnd,
  }) : super(key: key);

  bool willAcceptCard(DragTargetDetails<DragData> data) {
    if (data.data.sourceZoneId == zone.id) return false;
    if (data.data.cards.length > 1 && zone.stackMode == StackMode.overlay) {
      return false;
    }
    if (zone.cards.isEmpty) {
      // If the zone is empty, check if starting cards are allowed
      if (zone.rules.startingCards.isNotEmpty) {
        // If starting cards are defined, check if any of the dragged cards match
        bool hasStartingCards = false;
        for (var card in data.data.cards) {
          if (zone.rules.startingCards
              .where((c) => c.compare(card.toMiniCard()))
              .isNotEmpty) {
            hasStartingCards = true;
            break;
          }
        }
        if (!hasStartingCards) return false;
      } else if (zone.rules.bannedCards.isNotEmpty) {
        // If banned cards are defined, check if any of the dragged cards are banned
        bool hasBannedCards = false;
        for (var card in data.data.cards) {
          if (zone.rules.bannedCards
              .where((c) => c.compare(card.toMiniCard()))
              .isNotEmpty) {
            hasBannedCards = true;
            break;
          }
        }
        if (hasBannedCards) return false;
      }
      return true; // If no rules, allow any card to start
    }
    if (zone.rules.bannedCards.isNotEmpty) {
      // If banned cards are defined, check if any of the dragged cards are banned
      bool hasBannedCards = false;
      for (var card in data.data.cards) {
        if (zone.rules.bannedCards
            .where((c) => c.compare(card.toMiniCard()))
            .isNotEmpty) {
          hasBannedCards = true;
          break;
        }
      }
      if (hasBannedCards) return false;
    }
    bool isValidCard = false;
    switch (zone.rules.allowedCards) {
      case AllowedCards.sameColor:
        isValidCard = data.data.cards.every(
          (card) =>
              card.suit == zone.cards.last.suit ||
              card.suit == zone.cards.last.suit.alternateSuit,
        );
        break;
      case AllowedCards.alternateColor:
        isValidCard = data.data.cards.every(
          (card) =>
              card.suit != zone.cards.last.suit.alternateSuit &&
              card.suit != zone.cards.last.suit,
        );
        print('Alternate color check: $isValidCard');
        break;
      case AllowedCards.all:
        isValidCard = true;
        break;

      case AllowedCards.sameSuit:
        isValidCard = data.data.cards.every(
          (card) => zone.cards.isEmpty || card.suit == zone.cards.last.suit,
        );
        break;

      case AllowedCards.sameValue:
        isValidCard = data.data.cards.every(
          (card) => zone.cards.isEmpty || card.value == zone.cards.last.value,
        );
        break;
    }
    if (!isValidCard) return false;
    bool isValidOrder = false;
    switch (zone.rules.cardOrder) {
      case CardOrder.ascending:
        isValidOrder = data.data.cards.every(
          (card) =>
              zone.cards.isEmpty || card.value == zone.cards.last.value + 1,
        );
        break;
      case CardOrder.descending:
        isValidOrder = data.data.cards.every(
          (card) =>
              zone.cards.isEmpty || card.value == zone.cards.last.value - 1,
        );
        break;
      case CardOrder.none:
        isValidOrder = true; // No specific order required
        break;
    }
    if (!isValidOrder) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: willAcceptCard,
      onAcceptWithDetails: (data) => onMoveCards(data.data, zone.id),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Container(
          width: 120 * zone.scale,
          height:
              zone.stackMode == StackMode.spaced && zone.cards.isNotEmpty
                  ? ((zone.cards.length - 1) * 35 + 175) * zone.scale
                  : 175 * zone.scale, // Fixed height to prevent movement

          decoration:
              zone.cards.isEmpty
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12 * zone.scale),
                    border: Border.all(
                      color:
                          isHighlighted
                              ? Colors.blue
                              : const Color.fromARGB(255, 255, 255, 255),
                      width: isHighlighted ? 3 * zone.scale : 1 * zone.scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4 * zone.scale,
                        offset: Offset(0, 2 * zone.scale),
                      ),
                    ],
                  )
                  : null,
          child: zone.cards.isEmpty ? Center() : _buildCardStack(),
        );
      },
    );
  }

  Widget _buildCardStack() {
    if (zone.stackMode == StackMode.overlay) {
      return _buildOverlayStack();
    } else {
      return _buildSpacedStack();
    }
  }

  Widget _buildOverlayStack() {
    return Container(
      padding: EdgeInsets.all(8 * zone.scale),
      child: Stack(
        children:
            zone.cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              final isTopCard = index == zone.cards.length - 1;

              return Positioned(
                top: 0, // All cards at same position - fully overlapping
                left: 0,
                child:
                    isTopCard
                        ? zone.canDragCardOut
                            ? DraggableCardWidget(
                              card: card,
                              zoneId: zone.id,
                              index: index,
                              totalCards: zone.cards.length,
                              currentDragData: currentDragData,
                              getCardsFromIndex: getCardsFromIndex,
                              onDragStarted: onDragStarted,
                              onDragEnd: onDragEnd,
                              stackMode: zone.stackMode,
                              scale: zone.scale,
                            )
                            : CardContent(card: card, scale: zone.scale)
                        : CardContent(
                          card: card,
                          scale: zone.scale,
                        ), // Only top card is draggable
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSpacedStack() {
    return Container(
      padding: EdgeInsets.all(8 * zone.scale),
      child: Stack(
        children:
            zone.cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;

              return Positioned(
                top:
                    index *
                    (35.0 *
                        zone.scale), // Position from bottom up - each card 40px higher
                left: 0,
                child: DraggableCardWidget(
                  card: card,
                  zoneId: zone.id,
                  index: index,
                  totalCards: zone.cards.length,
                  currentDragData: currentDragData,
                  getCardsFromIndex: getCardsFromIndex,
                  onDragStarted: onDragStarted,
                  onDragEnd: onDragEnd,
                  stackMode: zone.stackMode,
                  scale: zone.scale,
                ),
              );
            }).toList(),
      ),
    );
  }
}
