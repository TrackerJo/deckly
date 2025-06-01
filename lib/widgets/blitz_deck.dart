import 'package:deckly/constants.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';

class BlitzDeckController {
  _BlitzDeckState? _state;

  void _attach(_BlitzDeckState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void removeCardFromPile(String cardId) {
    _state?.removeCardFromPile(cardId);
  }
}

class BlitzDeck extends StatefulWidget {
  final DragData currentDragData;
  final Function(DragData) onDragStarted;
  final Function() onDragEnd;
  final List<CardData> blitzDeck;
  final double scale;
  final BlitzDeckController? controller;

  const BlitzDeck({
    Key? key,
    required this.blitzDeck,
    required this.currentDragData,

    required this.onDragStarted,
    required this.onDragEnd,
    required this.scale,
    this.controller,
  }) : super(key: key);

  @override
  State<BlitzDeck> createState() => _BlitzDeckState();
}

class _BlitzDeckState extends State<BlitzDeck> {
  List<CardData> blitzDeck = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    blitzDeck = List.from(widget.blitzDeck);
    widget.controller?._attach(this);
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  @override
  void didUpdateWidget(BlitzDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blitzDeck != oldWidget.blitzDeck) {}
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
    widget.onDragEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: blitzDeck.isEmpty ? 220 * widget.scale : 220 * widget.scale,
      height: 175 * widget.scale, // Fixed height to prevent movement

      child:
          blitzDeck.isEmpty
              ? Center(
                child: SizedBox(
                  height: 70 * widget.scale,
                  width: 200 * widget.scale,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * widget.scale),
                      ),
                    ),
                    child: Text(
                      'Blitz!',
                      style: TextStyle(
                        fontSize: 24 * widget.scale,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
              : _buildOverlayStack(),
    );
  }

  Widget _buildOverlayStack() {
    return Container(
      padding: EdgeInsets.all(8 * widget.scale),
      child: SizedBox(
        width: 230 * widget.scale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100 * widget.scale,
              child: Stack(
                children:
                    blitzDeck.asMap().entries.map((entry) {
                      final index = entry.key;
                      final card = entry.value;
                      final isTopCard = index == blitzDeck.length - 1;

                      return Positioned(
                        top:
                            0, // All cards at same position - fully overlapping
                        left: 0,
                        child:
                            isTopCard
                                ? DraggableCardWidget(
                                  card: card,
                                  zoneId: 'blitz_deck',
                                  index: index,
                                  totalCards: blitzDeck.length,
                                  currentDragData: widget.currentDragData,
                                  getCardsFromIndex: (zoneId, cardIndex) {
                                    if (zoneId == 'blitz_deck' &&
                                        cardIndex < blitzDeck.length) {
                                      return <CardData>[blitzDeck[cardIndex]];
                                    }
                                    return <CardData>[];
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
                                )
                                : CardContent(
                                  scale: widget.scale,
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
            //Cards left indicator
            if (blitzDeck.isNotEmpty)
              Container(
                width: 100 * widget.scale,
                child: Center(
                  child: Text(
                    '${blitzDeck.length} ${blitzDeck.length == 1 ? 'Card' : 'Cards'} Left',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20 * widget.scale,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
