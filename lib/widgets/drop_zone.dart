import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';

class DropZoneController {
  _DropZoneWidgetState? _state;

  void _attach(_DropZoneWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void startFlash() {
    _state?.startFlash();
  }
}

class DropZoneWidget extends StatefulWidget {
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

  @override
  State<DropZoneWidget> createState() => _DropZoneWidgetState();
}

class _DropZoneWidgetState extends State<DropZoneWidget> {
  bool flashColor = false;
  GlobalKey testKey = GlobalKey();
  double zoneScale = 1.0;
  @override
  void initState() {
    super.initState();
    widget.zone.controller?._attach(this);
    setState(() {
      zoneScale = widget.zone.scale;
    });
  }

  @override
  void didUpdateWidget(covariant DropZoneWidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);

    if (widget.zone.controller != oldWidget.zone.controller) {
      oldWidget.zone.controller?._detach();
      widget.zone.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    widget.zone.controller?._detach();
  }

  void startFlash() {
    SharedPrefs.hapticButtonPress();
    if (mounted) {
      setState(() {
        flashColor = true;
      });
      Future.delayed(Duration(milliseconds: 1000), () {
        if (!mounted) return; // Check if the widget is still mounted
        setState(() {
          flashColor = false;
        });
      });
    }
  }

  bool willAcceptCard(DragTargetDetails<DragData> data) {
    if (data.data.sourceZoneId == widget.zone.id) return false;
    if (data.data.cards.length > 1 &&
        widget.zone.stackMode == StackMode.overlay) {
      return false;
    }
    if (widget.zone.cards.isEmpty) {
      // If the zone is empty, check if starting cards are allowed
      if (widget.zone.rules.startingCards.isNotEmpty) {
        // If starting cards are defined, check if any of the dragged cards match
        bool hasStartingCards = false;
        for (var card in data.data.cards) {
          if (widget.zone.rules.startingCards
              .where((c) => c.compare(card.toMiniCard()))
              .isNotEmpty) {
            hasStartingCards = true;
            break;
          }
        }
        if (!hasStartingCards) return false;
      } else if (widget.zone.rules.bannedCards.isNotEmpty) {
        // If banned cards are defined, check if any of the dragged cards are banned
        bool hasBannedCards = false;
        for (var card in data.data.cards) {
          if (widget.zone.rules.bannedCards
              .where((c) => c.compare(card.toMiniCard()))
              .isNotEmpty) {
            hasBannedCards = true;
            break;
          }
        }
        if (hasBannedCards) return false;
      }
      bool isValidSuit = false;
      if (widget.zone.rules.allowedSuits.isNotEmpty) {
        isValidSuit = data.data.cards.every(
          (card) => widget.zone.rules.allowedSuits.contains(card.suit),
        );
      } else {
        isValidSuit = true; // No specific suit restrictions
      }
      if (!isValidSuit) return false;
      if (widget.customWillAccept != null) {
        return widget.customWillAccept!();
      }
      return true; // If no rules, allow any card to start
    }
    if (widget.zone.rules.bannedCards.isNotEmpty) {
      // If banned cards are defined, check if any of the dragged cards are banned
      bool hasBannedCards = false;
      for (var card in data.data.cards) {
        if (widget.zone.rules.bannedCards
            .where((c) => c.compare(card.toMiniCard()))
            .isNotEmpty) {
          hasBannedCards = true;
          break;
        }
      }
      if (hasBannedCards) return false;
    }
    bool isValidCard = false;
    switch (widget.zone.rules.allowedCards) {
      case AllowedCards.sameColor:
        isValidCard = data.data.cards.every(
          (card) =>
              card.suit == widget.zone.cards.first.suit ||
              card.suit == widget.zone.cards.first.suit.alternateSuit,
        );
        break;
      case AllowedCards.alternateColor:
        //Is valid if all dragged cards are alternate colors to the first card in the zone
        CardSuit firstCardSuit = widget.zone.cards.last.suit;
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
          (card) =>
              widget.zone.cards.isEmpty ||
              card.suit == widget.zone.cards.first.suit,
        );
        break;

      case AllowedCards.sameValue:
        isValidCard = data.data.cards.every(
          (card) =>
              widget.zone.cards.isEmpty ||
              card.value == widget.zone.cards.first.value,
        );
        break;
    }
    if (!isValidCard) return false;
    bool isValidOrder = false;
    switch (widget.zone.rules.cardOrder) {
      case CardOrder.ascending:
        // Is valid if all dragged cards are in ascending order from the first card in the zone
        int firstValue = widget.zone.cards.last.value + 1;
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
        int firstValue = widget.zone.cards.last.value - 1;
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
    if (widget.zone.rules.allowedSuits.isNotEmpty) {
      isValidSuit = data.data.cards.every(
        (card) => widget.zone.rules.allowedSuits.contains(card.suit),
      );
    } else {
      isValidSuit = true; // No specific suit restrictions
    }
    if (!isValidSuit) return false;
    if (widget.customWillAccept != null) {
      return widget.customWillAccept!();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Your function call here

      // Print the width and height of the zone using testKey
      if (testKey.currentContext != null) {
        final renderBox =
            testKey.currentContext!.findRenderObject() as RenderBox;
        final size = renderBox.size;

        //Calculate the scale based on the size, the defualt is 100 x 150
        final scale = size.width / 120;
        widget.zone.scale = scale;

        if (zoneScale != scale && mounted) {
          setState(() {
            zoneScale = scale;
          });
        }
      }
    });

    return DragTarget<DragData>(
      onWillAcceptWithDetails:
          widget.zone.playable ? willAcceptCard : (d) => false,
      onAcceptWithDetails:
          (data) => widget.onMoveCards(data.data, widget.zone.id),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        return Stack(
          children: [
            Container(
              width: 120 * widget.zone.scale,
              height:
                  widget.zone.id == widget.currentDragData.sourceZoneId &&
                          widget.zone.cards.length ==
                              widget.currentDragData.cards.length
                      ? 175 * widget.zone.scale
                      : widget.zone.stackMode == StackMode.spaced &&
                          widget.zone.cards.isNotEmpty
                      ? ((widget.zone.cards.length - 1) * 35 + 175) *
                          widget.zone.scale
                      : 175 *
                          widget.zone.scale, // Fixed height to prevent movement

              decoration:
                  (widget.zone.cards.isEmpty ||
                              (widget.zone.cards.length -
                                          widget.currentDragData.cards.length ==
                                      0 &&
                                  widget.currentDragData.sourceZoneId ==
                                      widget.zone.id)) &&
                          widget.zone.playable
                      ? BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          12 * widget.zone.scale,
                        ),
                        border: Border.all(
                          color:
                              isHighlighted
                                  ? styling.primary
                                  : Colors.transparent,
                          width: 2,
                        ),

                        color: styling.backgroundLight,

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4 * widget.zone.scale,
                            offset: Offset(0, 2 * widget.zone.scale),
                          ),
                        ],
                      )
                      : null,
              child:
                  widget.zone.cards.isEmpty
                      ? widget.zone.playable
                          ? Center()
                          : Container()
                      : _buildCardStack(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardStack() {
    if (widget.zone.stackMode == StackMode.overlay) {
      return _buildOverlayStack();
    } else {
      return _buildSpacedStack();
    }
  }

  Widget _buildOverlayStack() {
    //Print the width and height of the zone using textKey

    return Container(
      key: testKey,
      padding: EdgeInsets.all(8 * zoneScale),
      child: Stack(
        children: [
          ...widget.zone.cards.asMap().entries.map((entry) {
            final index = entry.key;
            final card = entry.value;
            final isTopCard = index == widget.zone.cards.length - 1;

            return Positioned(
              top: 0, // All cards at same position - fully overlapping
              left: 0,
              child:
                  isTopCard
                      ? widget.zone.canDragCardOut
                          ? DraggableCardWidget(
                            card: card,
                            zoneId: widget.zone.id,
                            index: index,
                            totalCards: widget.zone.cards.length,
                            currentDragData: widget.currentDragData,
                            getCardsFromIndex: widget.getCardsFromIndex,
                            onDragStarted: widget.onDragStarted,
                            onDragEnd: widget.onDragEnd,
                            stackMode: widget.zone.stackMode,
                            scale: zoneScale,
                            isDutchBlitz: widget.isDutchBlitz,
                          )
                          : CardContent(
                            card: card,
                            scale: zoneScale,
                            isDutchBlitz: widget.isDutchBlitz,
                          )
                      : CardContent(
                        card: card,
                        scale: zoneScale,
                        isDutchBlitz: widget.isDutchBlitz,
                      ), // Only top card is draggable
            );
          }).toList(),
          if (widget.zone.stackMode == StackMode.overlay)
            AnimatedOpacity(
              opacity: flashColor ? 0.6 : 0.0,
              duration: Duration(milliseconds: 400),
              child: Container(
                width: 100 * zoneScale,
                height: 150 * zoneScale,

                // Fixed height to prevent movement
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8 * zoneScale),
                  color: styling.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpacedStack() {
    return Container(
      padding: EdgeInsets.all(8 * widget.zone.scale),
      child: Stack(
        children:
            widget.zone.cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;

              return Positioned(
                top:
                    index *
                    (35.0 *
                        widget
                            .zone
                            .scale), // Position from bottom up - each card 40px higher
                left: 0,
                child: DraggableCardWidget(
                  card: card,
                  zoneId: widget.zone.id,
                  index: index,
                  totalCards: widget.zone.cards.length,
                  currentDragData: widget.currentDragData,
                  getCardsFromIndex: widget.getCardsFromIndex,
                  onDragStarted: widget.onDragStarted,
                  onDragEnd: widget.onDragEnd,
                  stackMode: widget.zone.stackMode,
                  scale: widget.zone.scale,
                  isDutchBlitz: widget.isDutchBlitz,
                ),
              );
            }).toList(),
      ),
    );
  }
}
