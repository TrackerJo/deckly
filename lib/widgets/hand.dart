import 'package:deckly/constants.dart';

import 'package:deckly/widgets/playing_card.dart';

import 'package:flutter/material.dart';

class HandController {
  _HandState? _state;

  void _attach(_HandState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void removeCardFromPile(String cardId) {
    print('HandController: Removing card with ID: $cardId from hand');
    print("_state: $_state");
    _state?.removeCardFromPile(cardId);
  }

  void addCard(CardData card) {
    _state?.addCard(card);
  }

  void updateHand(List<CardData> newCards) {
    print('Updating hand with ${newCards.length} cards');
    print("_state: $_state");
    _state?.updateHand(newCards);
  }
}

class Hand extends StatefulWidget {
  final DragData currentDragData;
  final Function(DragData) onDragStarted;
  final Function() onDragEnd;
  final Function() onDragCompleted;
  final Function() onTapBlitz;
  final List<CardData> handCards;
  final double scale;
  final HandController? controller;
  final bool isDutchBlitz;
  final bool myHand;
  final bool draggableCards;
  final Function(CardData)? onTapCard;
  final bool Function(CardData)? isCardPlayable;

  const Hand({
    Key? key,
    required this.handCards,
    required this.currentDragData,
    required this.onDragCompleted,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.scale,
    required this.onTapBlitz,
    this.controller,
    this.isDutchBlitz = false,
    this.draggableCards = true, // Default to true for player's hand
    this.myHand = true,
    this.onTapCard, // Default to true for player's hand
    this.isCardPlayable, // Default to always playable
  }) : super(key: key);

  @override
  State<Hand> createState() => _HandState();
}

class _HandState extends State<Hand> {
  List<CardData> blitzDeck = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('Hand initState called with ${widget.handCards.length} cards');

    // If not my hand, we don't allow dragging
    if (!widget.myHand) {
      blitzDeck = widget.handCards;
    } else {
      blitzDeck = List.from(widget.handCards);
    }

    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(Hand oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.handCards != oldWidget.handCards) {
      print(
        'Hand didUpdateWidget: Updating hand with ${widget.handCards.length} cards',
      );
      setState(() {
        blitzDeck.clear();
        blitzDeck.addAll(widget.handCards);
      });
    }
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }

    if (widget.controller != null) {
      widget.controller!._detach(); // Detach first
      widget.controller!._attach(this); // Then reattach
    }
  }

  void removeCardFromPile(String cardId) {
    // print('Removing card with ID: $cardId from hand');
    setState(() {
      blitzDeck.removeWhere((card) => card.id == cardId);
    });
    // Ensure drag state is reset after successful card removal
    widget.onDragEnd();
  }

  void addCard(CardData card) {
    setState(() {
      blitzDeck.add(card);
    });
  }

  void updateHand(List<CardData> newCards) {
    print('Updating hand with ${newCards.length} cards');
    setState(() {
      blitzDeck.clear();
      blitzDeck.addAll(newCards);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230 * widget.scale,
      height: 175 * widget.scale, // Fixed height to prevent movement

      child: _buildOverlayStack(),
    );
  }

  Widget _buildOverlayStack() {
    return Container(
      padding: EdgeInsets.all(8 * widget.scale),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ...blitzDeck.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;

              return Positioned(
                top: 0, // All cards at same position - fully overlapping
                left:
                    widget.myHand
                        ? (20 * widget.scale) + // Adjusted for scale
                            (index * 50 * widget.scale)
                        : (index *
                            30 *
                            widget.scale), // Slight offset for visibility
                child:
                    widget.myHand &&
                            widget.draggableCards &&
                            (widget.isCardPlayable != null
                                ? widget.isCardPlayable!(card)
                                : true)
                        ? DraggableCardWidget(
                          card: card,
                          zoneId: 'hand',
                          index: index,
                          isCardPlayable:
                              widget.isCardPlayable != null
                                  ? widget.isCardPlayable!(card)
                                  : true, // Default to true if no function provided
                          totalCards: blitzDeck.length,
                          currentDragData: widget.currentDragData,
                          getCardsFromIndex: (zoneId, cardIndex) {
                            if (zoneId == 'hand' &&
                                cardIndex < blitzDeck.length) {
                              return <CardData>[blitzDeck[cardIndex]];
                            }
                            return <CardData>[];
                          },
                          onDragStarted: (dragData) {
                            print(
                              'Hand onDragStarted: ${dragData.cards} ${dragData.sourceIndex}',
                            );
                            widget.onDragStarted(dragData);
                          },
                          onDragEnd: widget.onDragEnd,
                          onDragCompleted: () {
                            widget.onDragCompleted();
                            // Remove the card from pile when drag is completed successfully
                            widget.controller?.removeCardFromPile(card.id);
                          },
                          stackMode: StackMode.overlay,
                          scale: widget.scale,
                          isDutchBlitz: widget.isDutchBlitz,
                        )
                        : widget.myHand
                        ? CardContent(
                          card: card,
                          scale: widget.scale,
                          isDutchBlitz: widget.isDutchBlitz,
                          isCardPlayable:
                              widget.isCardPlayable != null
                                  ? widget.isCardPlayable!(card)
                                  : true,
                          onTap:
                              widget
                                  .onTapCard, // Only allow tap if onTapCard is provided
                        )
                        : CardContent(
                          scale: widget.scale,
                          isDutchBlitz: widget.isDutchBlitz,
                          card: CardData(
                            id: 'deck_back',
                            value: 1,
                            suit: CardSuit.hearts, // Placeholder suit
                            isFaceUp: false,
                          ), // Only top card is draggable
                        ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
