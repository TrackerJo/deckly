import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';

class DropZoneWidget extends StatelessWidget {
  final DropZoneData zone;
  final DragData currentDragData;
  final Function(DragData, String) onMoveCards;
  final Function(String, int) getCardsFromIndex;
  final Function(DragData) onDragStarted;
  final Function() onDragEnd;
  final bool isDutchBlitz;
  final bool Function()? customWillAccept;

  const DropZoneWidget({
    Key? key,
    required this.zone,
    required this.currentDragData,
    required this.onMoveCards,
    required this.getCardsFromIndex,
    required this.onDragStarted,
    required this.onDragEnd,
    this.isDutchBlitz = false,
    this.customWillAccept,
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
      bool isValidSuit = false;
      if (zone.rules.allowedSuits.isNotEmpty) {
        isValidSuit = data.data.cards.every(
          (card) => zone.rules.allowedSuits.contains(card.suit),
        );
      } else {
        isValidSuit = true; // No specific suit restrictions
      }
      if (!isValidSuit) return false;
      if (customWillAccept != null) {
        return customWillAccept!();
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
              card.suit == zone.cards.first.suit ||
              card.suit == zone.cards.first.suit.alternateSuit,
        );
        break;
      case AllowedCards.alternateColor:
        //Is valid if all dragged cards are alternate colors to the first card in the zone
        CardSuit firstCardSuit = zone.cards.last.suit;
        for (var card in data.data.cards) {
          if (card.suit == firstCardSuit ||
              card.suit == firstCardSuit.alternateSuit) {
            isValidCard = false;
            break;
          } else {
            firstCardSuit = firstCardSuit.oppositeSuit;
            isValidCard = true;
          }
        }
        print('Alternate color check: $isValidCard');
        break;
      case AllowedCards.all:
        isValidCard = true;
        break;

      case AllowedCards.sameSuit:
        isValidCard = data.data.cards.every(
          (card) => zone.cards.isEmpty || card.suit == zone.cards.first.suit,
        );
        break;

      case AllowedCards.sameValue:
        isValidCard = data.data.cards.every(
          (card) => zone.cards.isEmpty || card.value == zone.cards.first.value,
        );
        break;
    }
    if (!isValidCard) return false;
    bool isValidOrder = false;
    switch (zone.rules.cardOrder) {
      case CardOrder.ascending:
        // Is valid if all dragged cards are in ascending order from the first card in the zone
        int firstValue = zone.cards.last.value + 1;
        for (var card in data.data.cards) {
          if (card.value != firstValue) {
            isValidOrder = false;
            break;
          } else {
            firstValue++;
            isValidOrder = true;
          }
        }

        break;
      case CardOrder.descending:
        // Is valid if all dragged cards are in descending order from the first card in the zone
        int firstValue = zone.cards.last.value - 1;
        for (var card in data.data.cards) {
          if (card.value != firstValue) {
            isValidOrder = false;
            break;
          } else {
            firstValue--;
            isValidOrder = true;
          }
        }
        break;
      case CardOrder.none:
        isValidOrder = true; // No specific order required
        break;
    }
    if (!isValidOrder) return false;
    bool isValidSuit = false;
    if (zone.rules.allowedSuits.isNotEmpty) {
      isValidSuit = data.data.cards.every(
        (card) => zone.rules.allowedSuits.contains(card.suit),
      );
    } else {
      isValidSuit = true; // No specific suit restrictions
    }
    if (!isValidSuit) return false;
    if (customWillAccept != null) {
      return customWillAccept!();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<DragData>(
      onWillAcceptWithDetails: zone.playable ? willAcceptCard : (d) => false,
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
              zone.cards.isEmpty && zone.playable
                  ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12 * zone.scale),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [styling.primaryColor, styling.secondaryColor],
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
          child:
              zone.cards.isEmpty
                  ? zone.playable
                      ? Container(
                        margin: EdgeInsets.all(
                          isHighlighted ? 3 * zone.scale : 1.5 * zone.scale,
                        ),
                        decoration: BoxDecoration(
                          color: styling.backgroundColor,
                          borderRadius: BorderRadius.circular(
                            (12 - (isHighlighted ? 3 : 1.5)) * zone.scale,
                          ),
                        ),
                        child: Center(),
                      )
                      : Container()
                  : _buildCardStack(),
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
                              isDutchBlitz: isDutchBlitz,
                            )
                            : CardContent(
                              card: card,
                              scale: zone.scale,
                              isDutchBlitz: isDutchBlitz,
                            )
                        : CardContent(
                          card: card,
                          scale: zone.scale,
                          isDutchBlitz: isDutchBlitz,
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
                  isDutchBlitz: isDutchBlitz,
                ),
              );
            }).toList(),
      ),
    );
  }
}
