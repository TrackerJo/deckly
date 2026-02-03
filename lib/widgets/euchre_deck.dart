import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:deckly/widgets/solid_action_button.dart';
import 'package:flutter/material.dart';

class EuchreDeckController {
  _EuchreDeckState? _state;

  void _attach(_EuchreDeckState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void removeCardFromPile(String cardId) {
    _state?.removeCardFromPile(cardId);
  }
}

class EuchreDeck extends StatefulWidget {
  final List<CardData> euchreDeck;
  final double scale;
  final EuchreDeckController? controller;
  final bool showTopCard;
  final bool linkDeck;

  const EuchreDeck({
    Key? key,
    required this.euchreDeck,

    required this.scale,

    this.controller,
    this.linkDeck = false, // Link deck by default
    this.showTopCard = true, // Show top card by default
  }) : super(key: key);

  @override
  State<EuchreDeck> createState() => _EuchreDeckState();
}

class _EuchreDeckState extends State<EuchreDeck> {
  List<CardData> blitzDeck = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.linkDeck) {
      // If linking deck, use the provided euchreDeck
      blitzDeck = widget.euchreDeck;
    } else {
      // Otherwise, create a new empty deck
      blitzDeck = List.from(widget.euchreDeck);
    }

    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(EuchreDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.euchreDeck != oldWidget.euchreDeck) {}
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  void removeCardFromPile(String cardId) {
    setState(() {
      blitzDeck.removeWhere((card) => card.id == cardId);
    });
    // Ensure drag state is reset after successful card removal
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120 * widget.scale,
      height: 175 * widget.scale, // Fixed height to prevent movement

      child: _buildOverlayStack(),
    );
  }

  Widget _buildOverlayStack() {
    return Container(
      padding: EdgeInsets.all(8 * widget.scale),
      child: SizedBox(
        width: 100 * widget.scale,
        child: Stack(
          children:
              blitzDeck.asMap().entries.map((entry) {
                final index = entry.key;
                final card = entry.value;
                final isTopCard = index == blitzDeck.length - 1;

                return Positioned(
                  top: 0, // All cards at same position - fully overlapping
                  left: 0,
                  child:
                      isTopCard && widget.showTopCard
                          ? CardContent(
                            scale: widget.scale,
                            isDutchBlitz: false,
                            card: card,
                          )
                          : CardContent(
                            scale: widget.scale,
                            isDutchBlitz: false,
                            card: CardData(
                              id: 'deck_back',
                              value: 1,
                              suit: CardSuit.hearts, // Placeholder suit
                              isFaceUp: false,
                            ), // Only top card is draggable
                          ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
