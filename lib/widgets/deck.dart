import 'dart:math';

import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:flutter/material.dart';
import 'playing_card.dart';

class CardDeckController {
  _CardDeckState? _state;

  void _attach(_CardDeckState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void removeCardFromPile(String cardId) {
    _state?.removeCardFromPile(cardId);
  }

  void unstuck() {
    _state?.unstuck();
  }
}

class CardDeck extends StatefulWidget {
  final List<CardData> cards;
  final Function(DragData) onDragStarted;
  final Function() onDragEnd;
  final DragData currentDragData;
  final String deckId;
  final CardDeckController? controller;
  final double scale;
  final bool isDutchBlitz;
  final Function() onReachEndOfDeck;

  const CardDeck({
    Key? key,
    required this.cards,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.currentDragData,
    required this.deckId,
    required this.onReachEndOfDeck,
    this.controller,
    this.scale = 1.0,
    this.isDutchBlitz = false,
  }) : super(key: key);

  @override
  _CardDeckState createState() => _CardDeckState();
}

class _CardDeckState extends State<CardDeck> {
  List<CardData> deckCards = [];
  List<CardData> pileCards = [];

  @override
  void initState() {
    super.initState();
    deckCards = List.from(widget.cards);
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(CardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cards != oldWidget.cards) {
      deckCards = List.from(widget.cards);
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  void _dealCards() {
    SharedPrefs.hapticInputSelect();
    if (deckCards.isEmpty) {
      // If deck is empty, reset from pile (excluding currently visible cards)
      // if (pileCards.length > 3) {
      //   setState(() {
      //     deckCards = pileCards.reversed.take(pileCards.length - 3).toList();
      //     pileCards = pileCards.take(3).toList();
      //   });
      // }
      //return all cards to the deck
      if (pileCards.isNotEmpty) {
        setState(() {
          deckCards = List.from(pileCards);
          pileCards.clear();
        });
      }
      return;
    }

    setState(() {
      int cardsToDeal = deckCards.length >= 3 ? 3 : deckCards.length;
      List<CardData> dealtCards = deckCards.take(cardsToDeal).toList();

      // Remove dealt cards from deck
      deckCards.removeRange(0, cardsToDeal);

      // Add to pile (face up)
      pileCards.addAll(
        dealtCards.map(
          (card) => CardData(
            id: card.id,
            value: card.value,

            suit: card.suit,
            isFaceUp: true,
          ),
        ),
      );
      if (deckCards.isEmpty) {
        widget.onReachEndOfDeck();
      }
    });
  }

  void unstuck() {
    // Reset the drag state
    List<CardData> dealtCards = deckCards.toList();
    deckCards.clear();
    pileCards.addAll(
      dealtCards.map(
        (card) => CardData(
          id: card.id,
          value: card.value,
          suit: card.suit,
          isFaceUp: true,
        ),
      ),
    );
    deckCards = List.from(pileCards);
    pileCards.clear();
    CardData topCard = deckCards.first;
    deckCards.removeAt(0);
    pileCards.add(
      CardData(
        id: topCard.id,
        value: topCard.value,
        suit: topCard.suit,
        isFaceUp: true,
      ),
    );
    setState(() {});
  }

  // Public method that can be called from parent when a card is successfully moved
  void removeCardFromPile(String cardId) {
    setState(() {
      pileCards.removeWhere((card) => card.id == cardId);
    });
    // Ensure drag state is reset after successful card removal
    widget.onDragEnd();
  }

  List<CardData> _getTopThreeCards() {
    if (pileCards.length <= 3) {
      return pileCards;
    }
    return pileCards.sublist(pileCards.length - 3);
  }

  @override
  Widget build(BuildContext context) {
    List<CardData> visiblePileCards = _getTopThreeCards();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Deck (face down cards)
        GestureDetector(
          onTap: _dealCards,
          child: Container(
            width: 100 * widget.scale,
            height: 150 * widget.scale,
            child: Stack(
              children: [
                if (deckCards.isNotEmpty)
                  Positioned.fill(
                    child: CardContent(
                      card: CardData(
                        id: 'deck_back',
                        value: 1,
                        suit: CardSuit.hearts, // Placeholder suit
                        isFaceUp: false,
                      ),
                      scale: widget.scale,
                      isDutchBlitz: widget.isDutchBlitz,
                    ),
                  )
                else
                  FancyBorder(
                    child: Container(
                      width: 100 * widget.scale,
                      height: 150 * widget.scale,

                      child: Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 40 * widget.scale,
                      ),
                    ),
                  ),

                // Deck count indicator
              ],
            ),
          ),
        ),

        SizedBox(width: 20 * widget.scale),

        // Pile (face up cards)
        Container(
          width: 100 * widget.scale,
          height: 150 * widget.scale,
          child:
              visiblePileCards.isEmpty
                  ? Container()
                  : Stack(
                    children:
                        visiblePileCards.asMap().entries.map((entry) {
                          final index = entry.key;
                          final card = entry.value;
                          final actualIndex =
                              pileCards.length -
                              visiblePileCards.length +
                              index;
                          final isTopCard =
                              index == visiblePileCards.length - 1;
                          //Only offset the top three cards horizontally - currently not using horizontal offset

                          return Positioned(
                            top: 0,
                            left: 0,
                            child:
                                isTopCard
                                    ? DraggableCardWidget(
                                      card: card,
                                      zoneId: 'pile',
                                      index: actualIndex,
                                      totalCards: pileCards.length,
                                      currentDragData: widget.currentDragData,
                                      getCardsFromIndex: (zoneId, cardIndex) {
                                        if (zoneId == 'pile' &&
                                            cardIndex < pileCards.length) {
                                          return [pileCards[cardIndex]];
                                        }
                                        return [];
                                      },
                                      onDragStarted: (dragData) {
                                        widget.onDragStarted(dragData);
                                      },
                                      onDragEnd: widget.onDragEnd,
                                      onDragCompleted: () {
                                        // Remove the card from pile when drag is completed successfully
                                        widget.controller?.removeCardFromPile(
                                          card.id,
                                        );
                                      },
                                      stackMode: StackMode.overlay,
                                      scale: widget.scale,
                                      isDutchBlitz: widget.isDutchBlitz,
                                    )
                                    : CardContent(
                                      card: card,
                                      scale: widget.scale,
                                      isDutchBlitz: widget.isDutchBlitz,
                                    ),
                          );
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}
