import 'dart:math';

import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:flutter/material.dart';
import 'playing_card.dart';

class CrazyEightsDeckController {
  _CrazyEightsDeckState? _state;

  void _attach(_CrazyEightsDeckState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void clearDeck() {
    _state?.clearDeck();
  }

  void dealCards() {
    print("CrazyEightsDeckController: Dealing cards");
    print("_state: $_state");
    _state?._dealCards();
  }
}

class CrazyEightsDeck extends StatefulWidget {
  final List<CardData> cards;
  final double handScale;
  final String deckId;
  final CrazyEightsDeckController? controller;
  final double scale;
  final Function(CardData) onCardDrawn;
  final Function() onReachEndOfDeck;
  final bool interactable;

  const CrazyEightsDeck({
    Key? key,
    required this.cards,

    required this.deckId,
    required this.onReachEndOfDeck,
    this.controller,
    required this.onCardDrawn,
    this.scale = 1.0,
    this.handScale = 1.0,
    this.interactable = true,
  }) : super(key: key);

  @override
  _CrazyEightsDeckState createState() => _CrazyEightsDeckState();
}

class _CrazyEightsDeckState extends State<CrazyEightsDeck> {
  List<CardData> deckCards = [];

  List<CardData> flipCards = [];
  bool isAnimating = false;

  @override
  void initState() {
    super.initState();

    deckCards = widget.cards;

    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    print("CardDeckAnim dispose called");
    // widget.controller?._detach();
    super.dispose();
  }

  void clearDeck() {
    setState(() {
      deckCards.clear();

      flipCards.clear();
    });
  }

  @override
  void didUpdateWidget(CrazyEightsDeck oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      print("CardDeckAnim didUpdateWidget called");
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  void _dealCards() {
    if (isAnimating) return; // Prevent dealing while animating
    final topCard = deckCards.removeLast();

    flipAnimation(topCard);
  }

  void flipAnimation(CardData card) async {
    // Start flip animation for the top card
    setState(() {
      isAnimating = true;
    });

    SharedPrefs.hapticInputSelect();
    // Add the card to flipCards
    flipCards.add(card);
    // Remove from deckCards

    await Future.delayed(
      Duration(milliseconds: 850),
    ); // Simulate animation delay
    setState(() {
      flipCards.clear(); // Clear the flipCards after animation

      isAnimating = false;
    });

    widget.onCardDrawn(card);

    // Update the UI to remove the card

    // Remove the card from flipCards after the animation

    if (deckCards.isEmpty) {
      widget.onReachEndOfDeck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Deck (face down cards)
        GestureDetector(
          onTap: widget.interactable ? _dealCards : null,
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
                      isDutchBlitz: false,
                    ),
                  )
                else
                  Container(),

                // Deck count indicator
              ],
            ),
          ),
        ),

        SizedBox(width: 12 * widget.scale),

        // Pile (face up cards)
        Container(
          width: 100 * widget.scale,
          height: 150 * widget.scale,
          child: Stack(
            children: [
              ...flipCards.map((card) {
                return CardFlip(
                  card: card,
                  isCrazyEights: true,
                  scale: widget.scale,
                  isDutchBlitz: false,
                  handScale: widget.handScale,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
