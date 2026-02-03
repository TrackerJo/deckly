import 'dart:math';

import 'package:deckly/constants.dart';
import 'package:flutter/material.dart';

class NertzBot {
  String name;
  String id;
  bool isDutchBlitz;

  List<CardData> deck;
  List<CardData> blitzDeck;
  List<CardData> pile;
  List<DropZoneData> publicDropZones;
  List<DropZoneData> privateDropZones;

  Function(String botId) onBlitz;
  Function(String zoneId, List<CardData> cards) updatePublicDropZone;
  Function(List<CardData> cards, String botId) updateBitzDeck;
  NertzGameState Function() getGameState;
  BotDifficulty difficulty;
  bool playingRound;
  int playSpeed = 1000; // Speed of the bot's turn, can be adjusted
  //Hard: 3000ms
  //Medium: 6000ms
  //Easy: 9000ms
  int cyclesStuck = 0; // Counter for cycles stuck

  NertzBot({
    required this.name,
    required this.id,
    required this.getGameState,
    List<CardData>? deck,
    List<CardData>? pile,
    List<DropZoneData>? publicDropZones,
    List<DropZoneData>? privateDropZones,
    List<CardData>? blitzDeck,
    required this.onBlitz,
    required this.updatePublicDropZone,
    this.playingRound = false,
    required this.updateBitzDeck,
    required this.difficulty,
    this.isDutchBlitz = false,
  }) : deck = deck ?? <CardData>[], // ✅ Create modifiable lists
       pile = pile ?? <CardData>[], // ✅ Create modifiable lists
       publicDropZones =
           publicDropZones ?? <DropZoneData>[], // ✅ Create modifiable lists
       privateDropZones =
           privateDropZones ?? <DropZoneData>[], // ✅ Create modifiable lists
       blitzDeck = blitzDeck ?? <CardData>[]; // ✅ Create modifiable lists

  void initialize(List<DropZoneData> publicDropZones) async {
    switch (difficulty) {
      case BotDifficulty.hard:
        playSpeed = 3000; // Hard bots play faster
        break;
      case BotDifficulty.medium:
        playSpeed = 6000; // Medium bots play at a moderate speed
        break;
      case BotDifficulty.easy:
        playSpeed = 9000; // Easy bots take longer to make decisions
        break;
    }
    this.publicDropZones = publicDropZones;
    List<CardData> shuffledDeck;
    if (isDutchBlitz) {
      shuffledDeck = [...fullBlitzDeck];
    } else {
      shuffledDeck = [...fullDeck];
    }
    shuffledDeck.shuffle();
    privateDropZones = [
      DropZoneData(
        id: 'pile1',
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[0]],
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile2',
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[1]],
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile3',
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[2]],
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        scale: 1.0,
      ),
      DropZoneData(
        id: 'pile4',
        stackMode: StackMode.spaced,
        cards: [shuffledDeck[3]],
        rules: DropZoneRules(
          cardOrder: CardOrder.descending,
          allowedCards: AllowedCards.alternateColor,
          startingCards: [],
          bannedCards: [],
        ),
        scale: 1.0,
      ),
    ];
    if (isDutchBlitz) {
      privateDropZones.removeLast();
    }
    shuffledDeck.removeRange(0, (isDutchBlitz ? 3 : 4));
    blitzDeck = shuffledDeck.sublist(0, (isDutchBlitz ? 10 : 13));

    shuffledDeck.removeRange(0, (isDutchBlitz ? 10 : 13));
    deck = shuffledDeck;
    playingRound = true;
    //Wait between 1 and 3 seconds before starting the game loop
  }

  void pauseGame() {
    playingRound = false;
  }

  void reset() {
    deck.clear();
    pile.clear();
    blitzDeck.clear();

    privateDropZones.clear();
    playingRound = false;
  }

  void gameLoop() async {
    try {
      if (!playingRound) {
        return;
      }
      NertzGameState currentState = getGameState();
      if (currentState != NertzGameState.playing) {
        return;
      }
      // Implement the bot's game logic here
      // This could include making decisions based on the current state of the game,
      // playing cards, drawing from the deck, etc.
      if (blitzDeck.isEmpty) {
        // If the blitz deck is empty, we can't play any more cards from it
        onBlitz(id);
        playingRound = false; // End the bot's turn
        return;
      }

      if (checkBlitzDeckPlays()) {
        cyclesStuck = 0; // Reset cycles stuck counter
        // If we can play a card from the blitz deck, we do so
        //Call gameLoop again to continue the bot's turn
        await Future.delayed(
          Duration(milliseconds: playSpeed),
          () => gameLoop(),
        );
        return;
      } else if (checkPilePlays()) {
        cyclesStuck = 0; // Reset cycles stuck counter
        // If we can play a card from the pile, we do so
        //Call gameLoop again to continue the bot's turn
        await Future.delayed(
          Duration(milliseconds: playSpeed),
          () => gameLoop(),
        );
        return;
      } else if (checkPileMoves()) {
        cyclesStuck = 0; // Reset cycles stuck counter
        // If we can move cards between piles, we do so
        //Call gameLoop again to continue the bot's turn
        await Future.delayed(
          Duration(milliseconds: playSpeed),
          () => gameLoop(),
        );
        return;
      } else if (checkDeckMoves()) {
        cyclesStuck = 0; // Reset cycles stuck counter
        // If we can draw cards from the deck, we do so
        //Call gameLoop again to continue the bot's turn
        await Future.delayed(
          Duration(milliseconds: playSpeed),
          () => gameLoop(),
        );
        return;
      } else {
        cyclesStuck++;

        if (cyclesStuck >= 11) {
          unstuckBot();
        }
        await Future.delayed(Duration(milliseconds: playSpeed), () {
          // If no moves are possible, end the bot's turn
          gameLoop();
        });
      }
    } catch (e) {
      print("Error in bot game loop: $e");
      // End the bot's turn on error
    }
  }

  void unstuckBot() {
    // If the bot is stuck, we can reset its state or take some action

    cyclesStuck = 0; // Reset cycles stuck counter
    pile.addAll(deck);
    deck = List.from(pile);
    pile.clear();
    pile.add(deck[0]);
    deck.removeAt(0);
  }

  bool checkBlitzDeckPlays() {
    final blitzDeckUpCard = blitzDeck.last;
    for (var dropZone in publicDropZones) {
      if (dropZone.id.contains('pile')) continue; // Skip pile zones
      final topCard = dropZone.cards.isNotEmpty ? dropZone.cards.last : null;
      if (topCard == null && blitzDeckUpCard.value == 1) {
        // If the drop zone is empty and the top card of the blitz deck is an Ace, we can play it
        blitzDeckUpCard.playedBy = id; // Set the player who played the card
        publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(
          blitzDeckUpCard,
        );
        updatePublicDropZone(
          dropZone.id,
          publicDropZones[publicDropZones.indexOf(dropZone)].cards,
        );
        blitzDeck.removeLast();
        updateBitzDeck(blitzDeck, id);
        return true;
      }
      if (topCard != null) {
        if (topCard.suit == blitzDeckUpCard.suit &&
            topCard.value == blitzDeckUpCard.value - 1) {
          // If the top card of the drop zone is one less than the blitz deck up card and of the same suit, we can play it
          blitzDeckUpCard.playedBy = id; // Set the player who played the card
          publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(
            blitzDeckUpCard,
          );
          updatePublicDropZone(
            dropZone.id,
            publicDropZones[publicDropZones.indexOf(dropZone)].cards,
          );
          blitzDeck.removeLast();
          updateBitzDeck(blitzDeck, id);
          return true;
        }
      }
    }
    for (var pileZone in privateDropZones) {
      if (pileZone.cards.isEmpty) {
        pileZone.cards.add(blitzDeckUpCard);
        blitzDeck.removeLast();
        updateBitzDeck(blitzDeck, id);
        return true;
      }
      final topCard = pileZone.cards.last;
      if (topCard.suit != blitzDeckUpCard.suit &&
          topCard.suit != blitzDeckUpCard.suit.alternateSuit &&
          topCard.value == blitzDeckUpCard.value + 1) {
        pileZone.cards.add(blitzDeckUpCard);
        blitzDeck.removeLast();
        updateBitzDeck(blitzDeck, id);
        return true;
      }
    }
    return false;
  }

  bool checkPilePlays() {
    for (var pileZone in privateDropZones) {
      if (pileZone.cards.isEmpty) continue;
      final topCard = pileZone.cards.last;
      for (var dropZone in publicDropZones) {
        if (dropZone.id.contains('pile')) continue;
        final topPublicCard =
            dropZone.cards.isNotEmpty ? dropZone.cards.last : null;
        if (topPublicCard == null && topCard.value == 1) {
          // If the drop zone is empty and the top card of the pile is an Ace, we can play it
          topCard.playedBy = id; // Set the player who played the card
          publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(topCard);
          updatePublicDropZone(
            dropZone.id,
            publicDropZones[publicDropZones.indexOf(dropZone)].cards,
          );
          pileZone.cards.removeLast();
          return true;
        }
        if (topPublicCard != null &&
            topPublicCard.suit == topCard.suit &&
            topPublicCard.value == topCard.value - 1) {
          // If the top card of the drop zone is one less than the pile up card and of the same suit, we can play it
          topCard.playedBy = id; // Set the player who played the card
          publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(topCard);
          updatePublicDropZone(
            dropZone.id,
            publicDropZones[publicDropZones.indexOf(dropZone)].cards,
          );
          pileZone.cards.removeLast();
          return true;
        }
      }
    }
    return false;
  }

  bool checkPileMoves() {
    for (var pileZone in privateDropZones) {
      if (pileZone.cards.isEmpty) continue;
      final startingCard = pileZone.cards.first;
      for (var dropZone in privateDropZones) {
        if (dropZone.id == pileZone.id) continue; // Don't move to the same pile
        final topCard = dropZone.cards.isNotEmpty ? dropZone.cards.last : null;
        if (topCard == null) continue;
        if (topCard.suit != startingCard.suit &&
            topCard.suit != startingCard.suit.alternateSuit &&
            topCard.value == startingCard.value + 1) {
          // If the top card of the destination pile is one more than the starting card and of a different suit, we can move it
          dropZone.cards.addAll(pileZone.cards);
          pileZone.cards.clear(); // Remove the first card from the pile
          return true;
        }
      }
    }
    return false;
  }

  bool checkDeckMoves() {
    //First check the top card of pile
    if (pile.isNotEmpty) {
      final topCard = pile.last;
      for (var dropZone in publicDropZones) {
        if (dropZone.id.contains('pile')) continue;
        final topPublicCard =
            dropZone.cards.isNotEmpty ? dropZone.cards.last : null;
        if (topPublicCard == null && topCard.value == 1) {
          // If the drop zone is empty and the top card of the pile is an Ace, we can play it
          topCard.playedBy = id; // Set the player who played the card
          publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(topCard);
          updatePublicDropZone(
            dropZone.id,
            publicDropZones[publicDropZones.indexOf(dropZone)].cards,
          );
          pile.removeLast();
          return true;
        }
        if (topPublicCard != null &&
            topPublicCard.suit == topCard.suit &&
            topPublicCard.value == topCard.value - 1) {
          // If the top card of the drop zone is one less than the pile up card and of the same suit, we can play it
          topCard.playedBy = id; // Set the player who played the card
          publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(topCard);
          updatePublicDropZone(
            dropZone.id,
            publicDropZones[publicDropZones.indexOf(dropZone)].cards,
          );
          pile.removeLast();
          return true;
        }
      }
      for (var pileZone in privateDropZones) {
        if (pileZone.cards.isEmpty) {
          continue;
        }
        final topPileCard = pileZone.cards.last;
        if (topPileCard.suit != topCard.suit &&
            topPileCard.suit != topCard.suit.alternateSuit &&
            topPileCard.value == topCard.value + 1) {
          pileZone.cards.add(topCard);
          pile.removeLast();
          return true;
        }
      }
    }
    if (deck.isEmpty) {
      // If the deck is empty, we can't draw any more cards
      deck = List.from(pile);
      pile.clear();
    }
    //Deal 3 cards from the deck to the pile
    if (deck.length >= 3) {
      pile.addAll(deck.sublist(0, 3));
      deck.removeRange(0, 3);
    } else if (deck.isNotEmpty) {
      pile.addAll(deck);
      deck.clear();
    }

    final topCard = pile.last;
    for (var dropZone in publicDropZones) {
      if (dropZone.id.contains('pile')) continue;
      final topPublicCard =
          dropZone.cards.isNotEmpty ? dropZone.cards.last : null;
      if (topPublicCard == null && topCard.value == 1) {
        // If the drop zone is empty and the top card of the pile is an Ace, we can play it
        topCard.playedBy = id; // Set the player who played the card
        publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(topCard);
        updatePublicDropZone(
          dropZone.id,
          publicDropZones[publicDropZones.indexOf(dropZone)].cards,
        );
        pile.removeLast();
        return true;
      }
      if (topPublicCard != null &&
          topPublicCard.suit == topCard.suit &&
          topPublicCard.value == topCard.value - 1) {
        // If the top card of the drop zone is one less than the pile up card and of the same suit, we can play it
        topCard.playedBy = id; // Set the player who played the card
        publicDropZones[publicDropZones.indexOf(dropZone)].cards.add(topCard);
        updatePublicDropZone(
          dropZone.id,
          publicDropZones[publicDropZones.indexOf(dropZone)].cards,
        );
        pile.removeLast();
        return true;
      }
    }
    for (var pileZone in privateDropZones) {
      if (pileZone.cards.isEmpty) {
        continue;
      }
      final topPileCard = pileZone.cards.last;
      if (topPileCard.suit != topCard.suit &&
          topPileCard.suit != topCard.suit.alternateSuit &&
          topPileCard.value == topCard.value + 1) {
        pileZone.cards.add(topCard);
        pile.removeLast();
        return true;
      }
    }
    return false;
  }

  void dispose() {
    // Clean up any resources used by the bot
    publicDropZones.clear();
    privateDropZones.clear();
    deck.clear();
    pile.clear();
    blitzDeck.clear();
    playingRound = false;
  }
}

class EuchreBot {
  String name;
  String id;
  BotDifficulty difficulty;

  CardSuit? trumpSuit;

  bool onTeamA;

  EuchrePlayer botPlayer;

  Function(CardSuit? trump, String botId, bool alone) onDecideTrump;
  Function(CardData card, String botId) onDiscard;
  Function(CardData card, String botId) onPlayCard;
  List<CardData> playedCards;

  EuchreBot({
    required this.name,
    required this.id,
    required this.difficulty,
    required this.botPlayer,
    required this.playedCards,

    this.onTeamA = false,

    this.trumpSuit,

    required this.onDecideTrump,
    required this.onDiscard,
    required this.onPlayCard,
    List<EuchrePlayer>? players,
  }); // ✅ Create modifiable lists

  CardData getWinningCard(List<CardData> trick, CardSuit leadSuit, CardSuit trumpSuit) {
    CardData? highCard;
    List<CardData> playedCards = [...trick];
    //filter out the played cards that weren't of the lead suit or trump suit
    playedCards =
        playedCards.where((card) {
          return card.suit == leadSuit ||
              (card.value == 11 && card.suit.alternateSuit == trumpSuit) ||
              card.suit == trumpSuit;
        }).toList();
    if (playedCards.any(
      (card) =>
          (card.value == 11 && card.suit.alternateSuit == trumpSuit) ||
          card.suit == trumpSuit,
    )) {
      // Trump played in suit
      final trumpCards =
          playedCards
              .where(
                (card) =>
                    (card.value == 11 &&
                        card.suit.alternateSuit == trumpSuit) ||
                    card.suit == trumpSuit,
              )
              .toList();
      CardData highestTrumpCard = trumpCards.reduce(
        (a, b) =>
            a.toSortingValue(trumpSuit: trumpSuit) >
                    b.toSortingValue(trumpSuit: trumpSuit)
                ? a
                : b,
      );
      print(
        "Highest trump card played: ${highestTrumpCard.value} of ${highestTrumpCard.suit}",
      );
      highCard = highestTrumpCard;
    } else {
      // No trump played
      CardData highestCard = playedCards.reduce(
        (a, b) =>
            a.toSortingValue(trumpSuit: trumpSuit) >
                    b.toSortingValue(trumpSuit: trumpSuit)
                ? a
                : b,
      );
      print("Highest card played: ${highestCard.value} of ${highestCard.suit}");
      highCard = highestCard;
    }
    return highCard;
  }

  int valueSuitEasy(CardSuit suit) {
    int cardsInHand =
        botPlayer.hand
            .where(
              (card) =>
                  card.suit == suit ||
                  card.value == 11 && card.suit.alternateSuit == suit,
            )
            .length;
    //If contains right bower, add a point
    if (botPlayer.hand.any((card) => card.value == 11 && card.suit == suit)) {
      cardsInHand += 1;
    }
    return cardsInHand;
  }

  int valueSuitMedium(CardSuit suit, CardData? upCard) {
    List<CardData> hand = [...botPlayer.hand];
    if (upCard != null && upCard.suit == suit) {
      hand.add(upCard);
    }

    /*
    Medium Card Values:
    Jack of trump suit: 5 points
    Jack of same color as trump suit: 4 points
    Ace of trump suit: 3 points
    King of trump suit: 2 points
    Other trump cards: 1 point
    Non-trump Ace: 1 point
    Other non-trump cards: 0 points

    */
    int value = 0;
    for (var card in hand) {
      if (card.value == 11 && card.suit == suit) {
        value += 5;
      } else if (card.value == 11 && card.suit.alternateSuit == suit) {
        value += 4;
      } else if (card.value == 14 && card.suit == suit) {
        value += 3;
      } else if (card.value == 13 && card.suit == suit) {
        value += 2;
      } else if (card.suit == suit) {
        value += 1;
      } else if (card.value == 14) {
        value += 1;
      }
    }
    return value;
  }

  int valueSuitHard(
    CardSuit suit,
    CardData? upCard,
    List<EuchrePlayer> players,
  ) {
    int value = 0;

    List<CardData> hand = [...botPlayer.hand];
    if (upCard != null && upCard.suit == suit && botPlayer.isDealer == true) {
      hand.add(upCard);
      discardCardHardSim(suit, hand);
    }
    int teammateIndex = players.indexWhere(
      (p) => p.onTeamA == botPlayer.onTeamA && p.id != botPlayer.id,
    );
    EuchrePlayer teammate = players[teammateIndex];
    if (upCard != null && upCard.suit == suit && teammate.isDealer == true) {
      if (upCard.value == 11) {
        value += 2;
      } else if (upCard.value == 1) {
        value += 1;
      }
    }

    /*
    Hard Card Values:
    Jack of trump suit: 6 points
    Jack of same color as trump suit: 5 points
    Ace of trump suit: 4 points
    King of trump suit: 3 points
    Other trump cards: 2 point
    Non-trump solo Ace: 2 points
    Non-trump Ace: 1 point
    Other non-trump cards: 0 points

    Suit Distribution:
    4 suited: -1 point
    3 suited: 0 points
    2 suited: +2 points


    Barebones to make:
    Hand: Right bower, Ace of trump, other trump, 2 other cards
    6 + 4 + 2 + 0 + 0 = 12 points

    Alone:
    Hand: Right bower, Left Bower, King of trump, other trump or 2 other cards of same suit
    17 points

    */
    Map<CardSuit, int> suitCounts = {
      CardSuit.hearts: 0,
      CardSuit.diamonds: 0,
      CardSuit.clubs: 0,
      CardSuit.spades: 0,
    };
    for (var card in hand) {
      if (card.value == 11 && card.suit.alternateSuit == suit) {
        suitCounts[suit] = (suitCounts[suit] ?? 0) + 1;
      } else {
        suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
      }
    }
    int numberOfSuitsInHand =
        suitCounts.values.where((count) => count > 0).length;
    if (numberOfSuitsInHand == 4) {
      //4 suited
      return -1;
    } else if (numberOfSuitsInHand == 3) {
      //3 suited
      //No change
    } else if (numberOfSuitsInHand == 2) {
      //2 suited
      return 1;
    } else if (numberOfSuitsInHand == 1) {
      //1 suited
      return 2;
    }

    for (var card in hand) {
      if (card.value == 11 && card.suit == suit) {
        value += 6;
      } else if (card.value == 11 && card.suit.alternateSuit == suit) {
        value += 5;
      } else if (card.value == 14 && card.suit == suit) {
        value += 4;
      } else if (card.value == 13 && card.suit == suit) {
        value += 3;
      } else if (card.suit == suit) {
        value += 2;
      } else if (card.value == 14) {
        //Check if solo ace
        if (suitCounts[card.suit] == 1) {
          value += 2;
        } else {
          value += 1;
        }
      }
    }
    return value;
  }

  CardSuit? decideTrumpEasy(List<CardSuit> availableSuits, bool hasToPick) {
    Map<CardSuit, int> suitValues = {};
    for (var suit in availableSuits) {
      suitValues[suit] = valueSuitEasy(suit);
    }
    // If has to pick, choose the suit with the highest value even if it's 0
    if (hasToPick) {
      return suitValues.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    } else {
      // If not forced to pick, only choose a suit if its value is greater than 0
      var bestEntry = suitValues.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      return bestEntry.value >= 4 ? bestEntry.key : null;
    }
  }

  CardSuit? decideTrumpMedium(
    List<CardSuit> availableSuits,
    bool hasToPick,
    CardData? upCard,
  ) {
    Map<CardSuit, int> suitValues = {};
    for (var suit in availableSuits) {
      suitValues[suit] = valueSuitMedium(suit, upCard);
    }
    // If has to pick, choose the suit with the highest value even if it's 0
    if (hasToPick) {
      return suitValues.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    } else {
      // If not forced to pick, only choose a suit if its value is greater than 0
      var bestEntry = suitValues.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      return bestEntry.value >= 10 ? bestEntry.key : null;
    }
  }

  (CardSuit? decision, bool alone) decideTrumpHard(
    List<CardSuit> availableSuits,
    bool hasToPick,
    CardData? upCard,
    List<EuchrePlayer> players,
  ) {
    Map<CardSuit, int> suitValues = {};
    for (var suit in availableSuits) {
      suitValues[suit] = valueSuitHard(suit, upCard, players);
    }
    // If has to pick, choose the suit with the highest value even if it's 0
    if (hasToPick) {
      var bestValue = suitValues.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );

      if (bestValue.value >= 17) {
        return (bestValue.key, true);
      } else {
        return (bestValue.key, false);
      }
    } else {
      // If not forced to pick, only choose a suit if its value is greater than 0
      var bestEntry = suitValues.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      if (bestEntry.value >= 17) {
        return (bestEntry.key, true);
      } else if (bestEntry.value >= 12) {
        return (bestEntry.key, false);
      } else {
        return (null, false);
      }
    }
  }

  CardData discardCardEasy() {
    // Discard the lowest value card that is not trump
    botPlayer.hand.sort((a, b) {
      int aValue = a.value;
      int bValue = b.value;
      if (a.suit == trumpSuit ||
          (a.value == 11 && a.suit.alternateSuit == trumpSuit))
        aValue += 20; // Trump cards are more valuable
      if (b.suit == trumpSuit ||
          (b.value == 11 && b.suit.alternateSuit == trumpSuit))
        bValue += 20; // Trump cards are more valuable
      return aValue.compareTo(bValue);
    });
    CardData discardedCard = botPlayer.hand.first;
    botPlayer.hand.removeAt(0);
    return discardedCard;
    // Remove the lowest value card
  }

  CardData discardCardMedium() {
    //See if any singles suits in hand
    List<CardData> nonTrumpCards =
        botPlayer.hand
            .where(
              (card) =>
                  card.suit != trumpSuit &&
                  !(card.value == 11 && card.suit.alternateSuit == trumpSuit),
            )
            .toList();
    if (nonTrumpCards.isEmpty) {
      //All cards are trump, discard the lowest value trump card
      botPlayer.hand.sort(
        (a, b) => a
            .toSortingValue(trumpSuit: trumpSuit)
            .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
      );
      CardData discardedCard = botPlayer.hand.first;
      botPlayer.hand.removeWhere((card) => card.id == discardedCard.id);
      return discardedCard;
    }
    Map<CardSuit, List<CardData>> suitMap = {};
    for (var card in nonTrumpCards) {
      suitMap.putIfAbsent(card.suit, () => []).add(card);
    }
    //If any single suits, discard the lowest value card from the single suit
    List<CardData> singleSuitCards = [];
    suitMap.forEach((suit, cards) {
      if (cards.length == 1) {
        singleSuitCards.addAll(cards);
      }
    });
    if (singleSuitCards.isNotEmpty) {
      singleSuitCards.sort(
        (a, b) => a
            .toSortingValue(trumpSuit: trumpSuit)
            .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
      );
      CardData discardedCard = singleSuitCards.first;
      botPlayer.hand.removeWhere((card) => card.id == discardedCard.id);
      return discardedCard;
    }
    //If no single suits, discard the lowest value non trump card
    nonTrumpCards.sort(
      (a, b) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    CardData discardedCard = nonTrumpCards.first;
    botPlayer.hand.removeWhere((card) => card.id == discardedCard.id);
    return discardedCard;
  }

  CardData discardCardHardSim(CardSuit trumpSuit, List<CardData> hand) {
    //See if any singles suits in hand
    List<CardData> nonTrumpCards =
        hand
            .where(
              (card) =>
                  card.suit != trumpSuit &&
                  !(card.value == 11 && card.suit.alternateSuit == trumpSuit),
            )
            .toList();
    if (nonTrumpCards.isEmpty) {
      //All cards are trump, discard the lowest value trump card
      hand.sort(
        (a, b) => a
            .toSortingValue(trumpSuit: trumpSuit)
            .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
      );
      CardData discardedCard = hand.first;
      hand.removeWhere((card) => card.id == discardedCard.id);
      return discardedCard;
    }
    Map<CardSuit, List<CardData>> suitMap = {};
    for (var card in nonTrumpCards) {
      suitMap.putIfAbsent(card.suit, () => []).add(card);
    }
    //If any single suits, discard the lowest value card from the single suit
    List<CardData> singleSuitCards = [];
    suitMap.forEach((suit, cards) {
      if (cards.length == 1) {
        singleSuitCards.addAll(cards);
      }
    });
    if (singleSuitCards.isNotEmpty) {
      singleSuitCards.sort(
        (a, b) => a
            .toSortingValue(trumpSuit: trumpSuit)
            .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
      );
      CardData discardedCard = singleSuitCards.first;
      hand.removeWhere((card) => card.id == discardedCard.id);
      return discardedCard;
    }
    //If no single suits, discard the lowest value non trump card
    nonTrumpCards.sort(
      (a, b) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    CardData discardedCard = nonTrumpCards.first;
    hand.removeWhere((card) => card.id == discardedCard.id);
    return discardedCard;
  }

  CardData discardCardHard() {
    //See if any singles suits in hand
    List<CardData> nonTrumpCards =
        botPlayer.hand
            .where(
              (card) =>
                  card.suit != trumpSuit &&
                  !(card.value == 11 && card.suit.alternateSuit == trumpSuit),
            )
            .toList();
    if (nonTrumpCards.isEmpty) {
      //All cards are trump, discard the lowest value trump card
      botPlayer.hand.sort(
        (a, b) => a
            .toSortingValue(trumpSuit: trumpSuit)
            .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
      );
      CardData discardedCard = botPlayer.hand.first;
      botPlayer.hand.removeWhere((card) => card.id == discardedCard.id);
      return discardedCard;
    }
    Map<CardSuit, List<CardData>> suitMap = {};
    for (var card in nonTrumpCards) {
      suitMap.putIfAbsent(card.suit, () => []).add(card);
    }
    //If any single suits, discard the lowest value card from the single suit
    List<CardData> singleSuitCards = [];
    suitMap.forEach((suit, cards) {
      if (cards.length == 1) {
        singleSuitCards.addAll(cards);
      }
    });
    if (singleSuitCards.isNotEmpty) {
      singleSuitCards.sort(
        (a, b) => a
            .toSortingValue(trumpSuit: trumpSuit)
            .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
      );
      CardData discardedCard = singleSuitCards.first;
      botPlayer.hand.removeWhere((card) => card.id == discardedCard.id);
      return discardedCard;
    }

    //If no single suits, discard the lowest value non trump card
    nonTrumpCards.sort(
      (a, b) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    CardData discardedCard = nonTrumpCards.first;
    botPlayer.hand.removeWhere((card) => card.id == discardedCard.id);
    return discardedCard;
  }

  CardData playCardEasy(List<CardData> currentTrick, CardSuit? leadSuit) {
    print("Trump Suit: $trumpSuit");
    List<CardData> playableCards;
    if (leadSuit != null &&
        botPlayer.hand.any(
          (card) =>
              card.suit == leadSuit ||
              (card.value == 11 &&
                  card.suit.alternateSuit == leadSuit &&
                  leadSuit == trumpSuit),
        )) {
      // If we have cards of the lead suit, we must play one of them
      playableCards =
          botPlayer.hand
              .where(
                (card) =>
                    card.suit == leadSuit ||
                    (card.value == 11 &&
                        card.suit.alternateSuit == leadSuit &&
                        leadSuit == trumpSuit),
              )
              .toList();
    } else {
      // Otherwise, we can play any card
      playableCards = List.from(botPlayer.hand);
    }

    //Check if has right bower
    if (playableCards.any(
      (card) => card.value == 11 && card.suit == trumpSuit,
    )) {
      print("SHOULD PLAY BOWER");
      CardData rightBower = playableCards.firstWhere(
        (card) => card.value == 11 && card.suit == trumpSuit,
      );
      print("Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}");
      botPlayer.hand.removeWhere((card) => card.id == rightBower.id);
      print(
        "NEW Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}",
      );
      return rightBower;
    }
    //Check if has any non trump ace
    if (playableCards.any(
      (card) => card.value == 14 && card.suit != trumpSuit,
    )) {
      CardData aceCard = playableCards.firstWhere(
        (card) => card.value == 14 && card.suit != trumpSuit,
      );
      print("Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}");
      botPlayer.hand.removeWhere((card) => card.id == aceCard.id);
      print(
        "NEW Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}",
      );
      return aceCard;
    }
    //Check if has any non trump king
    if (playableCards.any(
      (card) => card.value == 13 && card.suit != trumpSuit,
    )) {
      CardData kingCard = playableCards.firstWhere(
        (card) => card.value == 13 && card.suit != trumpSuit,
      );
      print("Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}");
      botPlayer.hand.removeWhere((card) => card.id == kingCard.id);
      print(
        "NEW Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}",
      );
      return kingCard;
    }
    //sort playable cards by value
    playableCards.sort(
      (a, b) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    print(
      "Playable cards: ${playableCards.map((e) => e.displayValue()).toList()}",
    );
    print("Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}");
    // Play the highest value playable card
    CardData cardToPlay = playableCards.last;
    botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
    print("NEW Hand: ${botPlayer.hand.map((e) => e.displayValue()).toList()}");
    return cardToPlay;
  }

  CardData playCardMedium(
    List<CardData> currentTrick,
    CardSuit? leadSuit,
    List<EuchrePlayer> players,
  ) {
    if (leadSuit == null) {
      //Check if bot has right bower
      if (botPlayer.hand.any(
        (card) => card.value == 11 && card.suit == trumpSuit,
      )) {
        CardData rightBower = botPlayer.hand.firstWhere(
          (card) => card.value == 11 && card.suit == trumpSuit,
        );
        botPlayer.hand.removeWhere((card) => card.id == rightBower.id);
        return rightBower;
      }
      //Play highest non trump card
      List<CardData> nonTrumpCards =
          botPlayer.hand
              .where(
                (card) =>
                    card.suit != trumpSuit &&
                    !(card.value == 11 && card.suit.alternateSuit == trumpSuit),
              )
              .toList();
      if (nonTrumpCards.isNotEmpty) {
        nonTrumpCards.sort(
          (a, b) => b
              .toSortingValue(trumpSuit: trumpSuit)
              .compareTo(a.toSortingValue(trumpSuit: trumpSuit)),
        );
        CardData cardToPlay = nonTrumpCards.first;
        botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
        return cardToPlay;
      } else {
        //If no non trump cards, play highest trump card
        List<CardData> trumpCards =
            botPlayer.hand
                .where(
                  (card) =>
                      card.suit == trumpSuit ||
                      (card.value == 11 &&
                          card.suit.alternateSuit == trumpSuit),
                )
                .toList();
        trumpCards.sort(
          (a, b) => a
              .toSortingValue(trumpSuit: trumpSuit)
              .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
        );
        CardData cardToPlay = trumpCards.last;
        botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
        return cardToPlay;
      }
    } else {
      List<CardData> playableCards;
      if (botPlayer.hand.any(
        (card) =>
            card.suit == leadSuit ||
            (card.value == 11 &&
                card.suit.alternateSuit == leadSuit &&
                leadSuit == trumpSuit),
      )) {
        // If we have cards of the lead suit, we must play one of them
        playableCards =
            botPlayer.hand
                .where(
                  (card) =>
                      card.suit == leadSuit ||
                      (card.value == 11 &&
                          card.suit.alternateSuit == leadSuit &&
                          leadSuit == trumpSuit),
                )
                .toList();
      } else {
        // Otherwise, we can play any card
        playableCards = List.from(botPlayer.hand);
      }
      CardData winningCard = getWinningCard(currentTrick, leadSuit, trumpSuit!);
      String partnerId =
          players
              .firstWhere(
                (player) =>
                    player.onTeamA == botPlayer.onTeamA && player.id != id,
              )
              .id;
      bool partnerWinning = winningCard.playedBy == partnerId;
      if (partnerWinning) {
        List<CardData> nonTrumpPlayableCards =
            playableCards
                .where(
                  (card) =>
                      card.suit != trumpSuit &&
                      !(card.value == 11 &&
                          card.suit.alternateSuit == trumpSuit),
                )
                .toList();
        if (nonTrumpPlayableCards.isNotEmpty) {
          //Play lowest non trump playable card
          nonTrumpPlayableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = nonTrumpPlayableCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        } else {
          //If no non trump playable cards, play lowest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
      } else {
        if (leadSuit == trumpSuit) {
          //Play highest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.last;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
        //Can follow suit
        bool canFollowSuit = playableCards.any((card) => card.suit == leadSuit);
        if (canFollowSuit) {
          //Play highest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.last;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        } else {
          //See if can play trump
          List<CardData> trumpPlayableCards =
              playableCards
                  .where(
                    (card) =>
                        card.suit == trumpSuit ||
                        (card.value == 11 &&
                            card.suit.alternateSuit == trumpSuit),
                  )
                  .toList();
          if (trumpPlayableCards.isNotEmpty) {
            //Play lowest trump playable card
            trumpPlayableCards.sort(
              (a, b) => a
                  .toSortingValue(trumpSuit: trumpSuit)
                  .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
            );
            CardData cardToPlay = trumpPlayableCards.first;
            botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
            return cardToPlay;
          }
          //If can't play trump, play lowest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
      }
    }
  }

  CardData? highestCardInSuit(CardSuit suit) {
    List<CardData> allPossibleCards = [
      for (var value = 9; value <= 14; value++)
        CardData(
          id: '${suit.toString()}_${value == 14 ? 1 : value}',
          value:
              value == 14
                  ? 1
                  : value, // Ace is 1, Jack is 11, Queen is 12, King is 13
          suit: suit,
          isFaceUp: true,
        ),
    ];

    if (suit == trumpSuit) {
      allPossibleCards.add(
        CardData(
          id: '${suit.alternateSuit.toString()}_11',
          value: 11,
          suit: suit.alternateSuit,
          isFaceUp: true,
        ),
      );
    } else if (suit.alternateSuit == trumpSuit) {
      //remove left bower from possible cards
      allPossibleCards.removeWhere((card) => card.value == 11);
    }
    //Remove played cards from all possible cards
    allPossibleCards.removeWhere(
      (card) => playedCards.any((playedCard) => playedCard.id == card.id),
    );
    if (allPossibleCards.isEmpty) {
      return null; // No cards available in this suit
    }
    //Sort by sorting value
    allPossibleCards.sort(
      (a, b) => b
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(a.toSortingValue(trumpSuit: trumpSuit)),
    );

    return allPossibleCards.first;
  }

  CardData playCardHard(
    List<CardData> currentTrick,
    CardSuit? leadSuit,
    List<EuchrePlayer> players,
  ) {
    if (leadSuit == null) {
      //Check if bot has highest card in trump suit
      CardData? highestTrumpCard = highestCardInSuit(trumpSuit!);
      if (highestTrumpCard != null &&
          botPlayer.hand.any((card) => card.id == highestTrumpCard.id)) {
        print(
          "Playing highest trump card: ${highestTrumpCard.value} of ${highestTrumpCard.suit}",
        );
        botPlayer.hand.removeWhere((card) => card.id == highestTrumpCard.id);
        return highestTrumpCard;
      }
      //Check if bot has highest card in any non trump suit
      List<CardSuit> nonTrumpSuits =
          CardSuit.values.where((suit) => suit != trumpSuit).toList();
      for (var suit in nonTrumpSuits) {
        CardData? highestCard = highestCardInSuit(suit);
        if (highestCard != null &&
            botPlayer.hand.any(
              (card) =>
                  card.id == highestCard.id &&
                  (card.value == 11 && card.suit.alternateSuit == trumpSuit
                      ? false
                      : true),
            )) {
          print(
            "Playing highest card in $suit: ${highestCard.value} of ${highestCard.suit}",
          );
          botPlayer.hand.removeWhere((card) => card.id == highestCard.id);
          return highestCard;
        }
      }
      //Check if bot has any single suits
      Map<CardSuit, int> suitCounts = {
        CardSuit.hearts: 0,
        CardSuit.diamonds: 0,
        CardSuit.clubs: 0,
        CardSuit.spades: 0,
      };
      for (var card in botPlayer.hand) {
        if (card.value == 11 && card.suit.alternateSuit == trumpSuit) {
          suitCounts[trumpSuit!] = (suitCounts[trumpSuit] ?? 0) + 1;
        } else {
          suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
        }
      }
      List<CardSuit> singleSuits = [];
      suitCounts.forEach((suit, count) {
        if (count == 1) {
          singleSuits.add(suit);
        }
      });
      //remove trump suit from single suits
      singleSuits.removeWhere((suit) => suit == trumpSuit);
      if (singleSuits.isNotEmpty) {
        //Play highest card from single suit
        List<CardData> singleSuitCards =
            botPlayer.hand
                .where((card) => singleSuits.contains(card.suit))
                .toList();

        singleSuitCards.sort(
          (a, b) => b
              .toSortingValue(trumpSuit: trumpSuit)
              .compareTo(a.toSortingValue(trumpSuit: trumpSuit)),
        );
        print(
          "Playing highest card from single suit: ${singleSuitCards.first.value} of ${singleSuitCards.first.suit}",
        );
        CardData cardToPlay = singleSuitCards.first;
        botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
        return cardToPlay;
      }

      //Play highest non trump card
      List<CardData> nonTrumpCards =
          botPlayer.hand
              .where(
                (card) =>
                    card.suit != trumpSuit &&
                    !(card.value == 11 && card.suit.alternateSuit == trumpSuit),
              )
              .toList();
      if (nonTrumpCards.isNotEmpty) {
        nonTrumpCards.sort(
          (a, b) => b
              .toSortingValue(trumpSuit: trumpSuit)
              .compareTo(a.toSortingValue(trumpSuit: trumpSuit)),
        );
        print(
          "Playing highest non trump card: ${nonTrumpCards.first.value} of ${nonTrumpCards.first.suit}",
        );
        CardData cardToPlay = nonTrumpCards.first;
        botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
        return cardToPlay;
      } else {
        //If no non trump cards, play highest trump card

        botPlayer.hand.sort(
          (a, b) => a
              .toSortingValue(trumpSuit: trumpSuit)
              .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
        );
        print(
          "Playing highest trump card: ${botPlayer.hand.last.value} of ${botPlayer.hand.last.suit}",
        );
        CardData cardToPlay = botPlayer.hand.last;
        botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
        return cardToPlay;
      }
    } else {
      List<CardData> playableCards;
      if (botPlayer.hand.any(
        (card) =>
            card.suit == leadSuit ||
            (card.value == 11 &&
                card.suit.alternateSuit == leadSuit &&
                leadSuit == trumpSuit),
      )) {
        // If we have cards of the lead suit, we must play one of them
        playableCards =
            botPlayer.hand
                .where(
                  (card) =>
                      card.suit == leadSuit ||
                      (card.value == 11 &&
                          card.suit.alternateSuit == leadSuit &&
                          leadSuit == trumpSuit),
                )
                .toList();
      } else {
        // Otherwise, we can play any card
        playableCards = List.from(botPlayer.hand);
      }
      CardData winningCard = getWinningCard(currentTrick, leadSuit, trumpSuit!);
      String partnerId =
          players
              .firstWhere(
                (player) =>
                    player.onTeamA == botPlayer.onTeamA && player.id != id,
              )
              .id;
      bool partnerWinning = winningCard.playedBy == partnerId;
      if (partnerWinning) {
        List<CardData> nonTrumpPlayableCards =
            playableCards
                .where(
                  (card) =>
                      card.suit != trumpSuit &&
                      !(card.value == 11 &&
                          card.suit.alternateSuit == trumpSuit),
                )
                .toList();
        if (nonTrumpPlayableCards.isNotEmpty) {
          Map<CardSuit, int> suitCounts = {
            CardSuit.hearts: 0,
            CardSuit.diamonds: 0,
            CardSuit.clubs: 0,
            CardSuit.spades: 0,
          };
          for (var card in nonTrumpPlayableCards) {
            if (card.value == 11 && card.suit.alternateSuit == trumpSuit) {
              suitCounts[trumpSuit!] = (suitCounts[trumpSuit] ?? 0) + 1;
            } else {
              suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
            }
          }
          List<CardSuit> singleSuits = [];
          suitCounts.forEach((suit, count) {
            if (count == 1) {
              singleSuits.add(suit);
            }
          });
          if (singleSuits.isNotEmpty) {
            //Play lowest card from single suit
            List<CardData> singleSuitCards = [];
            for (var suit in singleSuits) {
              singleSuitCards.addAll(
                nonTrumpPlayableCards.where((card) => card.suit == suit),
              );
            }
            singleSuitCards.sort(
              (a, b) => a
                  .toSortingValue(trumpSuit: trumpSuit)
                  .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
            );
            CardData cardToPlay = singleSuitCards.first;
            botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
            return cardToPlay;
          }

          //Play lowest non trump playable card
          nonTrumpPlayableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = nonTrumpPlayableCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        } else {
          //If no non trump playable cards, play lowest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
      } else {
        if (leadSuit == trumpSuit) {
          //Play highest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.last;
          if (cardToPlay.toSortingValue(trumpSuit: trumpSuit) <=
                  winningCard.toSortingValue(trumpSuit: trumpSuit) ||
              cardToPlay.suit != winningCard.suit) {
            //Play lowest playable card if can't win
            CardData cardToPlay = playableCards.first;
            botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
            return cardToPlay;
          }
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
        //Can follow suit
        bool canFollowSuit = playableCards.any((card) => card.suit == leadSuit);
        if (canFollowSuit) {
          //Play highest playable card
          playableCards.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = playableCards.last;
          if (cardToPlay.toSortingValue(trumpSuit: trumpSuit) <=
              winningCard.toSortingValue(trumpSuit: trumpSuit)) {
            //Play lowest playable card if can't win
            CardData cardToPlay = playableCards.first;
            botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
            return cardToPlay;
          }
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        } else {
          //See if can play trump
          List<CardData> trumpPlayableCards =
              playableCards
                  .where(
                    (card) =>
                        card.suit == trumpSuit ||
                        (card.value == 11 &&
                            card.suit.alternateSuit == trumpSuit),
                  )
                  .toList();
          if (trumpPlayableCards.isNotEmpty) {
            //Play lowest trump playable card
            trumpPlayableCards.sort(
              (a, b) => a
                  .toSortingValue(trumpSuit: trumpSuit)
                  .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
            );
            List<CardData> winningTrumpCards =
                trumpPlayableCards
                    .where(
                      (card) =>
                          winningCard.suit != trumpSuit ||
                          card.toSortingValue(trumpSuit: trumpSuit) >
                              winningCard.toSortingValue(trumpSuit: trumpSuit),
                    )
                    .toList();

            if (winningTrumpCards.isNotEmpty) {
              //Play lowest winning trump card
              winningTrumpCards.sort(
                (a, b) => a
                    .toSortingValue(trumpSuit: trumpSuit)
                    .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
              );
              CardData cardToPlay = winningTrumpCards.first;

              botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
              return cardToPlay;
            }
            //play lowest playable non trump card if can't win
            List<CardData> playableNonTrumpCards =
                playableCards
                    .where(
                      (card) =>
                          card.suit != trumpSuit &&
                          !(card.value == 11 &&
                              card.suit.alternateSuit == trumpSuit),
                    )
                    .toList();
            if (playableNonTrumpCards.isNotEmpty) {
              playableNonTrumpCards.sort(
                (a, b) => a
                    .toSortingValue(trumpSuit: trumpSuit)
                    .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
              );
              CardData cardToPlay = playableNonTrumpCards.first;
              botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
              return cardToPlay;
            }
          }
          //If can't play trump, play lowest playable card
          botPlayer.hand.sort(
            (a, b) => a
                .toSortingValue(trumpSuit: trumpSuit)
                .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
          );
          CardData cardToPlay = botPlayer.hand.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
      }
    }
  }

  void decideTrump(
    List<CardSuit> availableSuits,
    bool hasToPick,
    CardData? upCard,
    List<EuchrePlayer> players,
  ) {
    print("Deciding trump...");
    print("Difficulty: $difficulty");
    switch (difficulty) {
      case BotDifficulty.hard:
        // Implement hard strategy here
        // return decideTrumpEasy(availableSuits, hasToPick);
        var (decision, alone) = decideTrumpHard(
          availableSuits,
          hasToPick,
          upCard,
          players,
        );
        onDecideTrump(decision, id, alone);
        return;
      case BotDifficulty.medium:
        // Implement medium strategy here
        CardSuit? decision = decideTrumpMedium(
          availableSuits,
          hasToPick,
          botPlayer.isDealer ? upCard : null,
        );
        onDecideTrump(decision, id, false);
        return;
      case BotDifficulty.easy:
        CardSuit? decision = decideTrumpEasy(availableSuits, hasToPick);
        onDecideTrump(decision, id, false);
        return;
    }
  }

  void discardCard() {
    switch (difficulty) {
      case BotDifficulty.hard:
        // Implement hard strategy here
        // discardCardEasy();
        CardData discard = discardCardHard();
        onDiscard(discard, id);
        return;
      case BotDifficulty.medium:
        // Implement medium strategy here
        // discardCardEasy();
        CardData discard = discardCardMedium();
        onDiscard(discard, id);
        return;
      case BotDifficulty.easy:
        CardData discard = discardCardEasy();
        onDiscard(discard, id);
        return;
    }
  }

  void playCard(
    List<CardData> currentTrick,
    CardSuit? leadSuit,
    List<EuchrePlayer> players,
  ) {
    switch (difficulty) {
      case BotDifficulty.hard:
        // Implement hard strategy here
        // return playCardEasy(currentTrick, leadSuit);
        CardData card = playCardHard(currentTrick, leadSuit, players);
        onPlayCard(card, id);
        return;

      case BotDifficulty.medium:
        // Implement medium strategy here
        // return playCardEasy(currentTrick, leadSuit);
        CardData card = playCardMedium(currentTrick, leadSuit, players);
        onPlayCard(card, id);
        return;
      case BotDifficulty.easy:
        CardData card = playCardEasy(currentTrick, leadSuit);
        onPlayCard(card, id);
        return;
    }
  }
}

class CrazyEightsBot {
  String name;
  String id;
  BotDifficulty difficulty;
  CrazyEightsPlayer botPlayer;
  List<CardData> deckCards;

  Function(CardData card, String playerId) onPlayCard;
  Function(VoidCallback) setState;

  CrazyEightsBot({
    required this.name,
    required this.id,
    required this.difficulty,
    required this.botPlayer,
    required this.onPlayCard,
    required this.deckCards,
    required this.setState,
  });

  Future<CardData> playCardEasy(List<CardData> pile) async {
    final CardData upCard = pile.last;
    // Play the first playable card
    List<CardData> playableCards =
        botPlayer.hand.where((card) {
          return card.suit == upCard.suit ||
              card.value == upCard.value ||
              card.value == 8;
        }).toList();
    while (playableCards.isEmpty) {
      // If no playable cards, draw a card
      if (deckCards.isEmpty) {
        List<CardData> pileCards = List.from(pile);
        final CardData upCard = pileCards.removeLast();
        deckCards.addAll(pile);
        pile.clear();
        deckCards.shuffle();
        pile.add(upCard);
        // Simulate thinking time
      }
      CardData drawnCard = deckCards.removeLast();
      botPlayer.hand.add(drawnCard);
      playableCards =
          botPlayer.hand.where((card) {
            return card.suit == upCard.suit ||
                card.value == upCard.value ||
                card.value == 8;
          }).toList();
      setState(() {
        // Update the UI after reshuffling the deck
      });
      await Future.delayed(Duration(milliseconds: 500));
    }
    // Play the first playable card
    CardData cardToPlay = playableCards.first;
    botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
    return cardToPlay;
  }

  Future<CardData> playCardMedium(List<CardData> pile) async {
    final CardData upCard = pile.last;
    // Play the first playable card
    List<CardData> playableCards =
        botPlayer.hand.where((card) {
          return card.suit == upCard.suit ||
              card.value == upCard.value ||
              card.value == 8;
        }).toList();
    while (playableCards.isEmpty) {
      // If no playable cards, draw a card
      if (deckCards.isEmpty) {
        List<CardData> pileCards = List.from(pile);
        final CardData upCard = pileCards.removeLast();
        deckCards.addAll(pile);
        pile.clear();
        deckCards.shuffle();
        pile.add(upCard);
      }
      CardData drawnCard = deckCards.removeLast();
      botPlayer.hand.add(drawnCard);
      playableCards =
          botPlayer.hand.where((card) {
            return card.suit == upCard.suit ||
                card.value == upCard.value ||
                card.value == 8;
          }).toList();
      setState(() {
        // Update the UI after drawing a card
      });
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Simulate thinking time
    }
    //Check if bot has any single suits
    Map<CardSuit, int> suitCounts = {
      CardSuit.hearts: 0,
      CardSuit.diamonds: 0,
      CardSuit.clubs: 0,
      CardSuit.spades: 0,
    };
    for (var card in playableCards) {
      if (card.value == 8) {
        // Ignore eights
        continue;
      }

      suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
    }
    //choose suit with most cards
    CardSuit? chosenSuit;
    int maxCount = 0;
    suitCounts.forEach((suit, count) {
      if (count > maxCount) {
        maxCount = count;
        chosenSuit = suit;
      }
    });
    if (chosenSuit != null && maxCount >= 1) {
      // If there is a suit with more than one card, play the random card of that suit
      List<CardData> suitCards =
          playableCards.where((card) => card.suit == chosenSuit).toList();
      if (suitCards.isNotEmpty) {
        //remove eights from suit cards
        suitCards.removeWhere((card) => card.value == 8);
        if (suitCards.isNotEmpty) {
          // Play a random card from the chosen suit
          suitCards.shuffle();
          CardData cardToPlay = suitCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        } else {
          // If no cards of the chosen suit, play the first playable card
          CardData cardToPlay = playableCards.first;
          botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
          return cardToPlay;
        }
      }
    }
    // If no single suits or only one card of a suit, play the first playable card
    CardData cardToPlay = playableCards.first;
    botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
    return cardToPlay;
  }

  Future<CardData> playCardHard(List<CardData> pile) async {
    final CardData upCard = pile.last;
    // Play the first playable card
    List<CardData> playableCards =
        botPlayer.hand.where((card) {
          return card.suit == upCard.suit ||
              card.value == upCard.value ||
              card.value == 8;
        }).toList();
    while (playableCards.isEmpty) {
      // If no playable cards, draw a card
      if (deckCards.isEmpty) {
        List<CardData> pileCards = List.from(pile);
        final CardData upCard = pileCards.removeLast();
        deckCards.addAll(pile);
        pile.clear();
        deckCards.shuffle();
        pile.add(upCard);
      }
      CardData drawnCard = deckCards.removeLast();
      print("Drawing card: ${drawnCard.displayValue()}");
      if (deckCards.isNotEmpty)
        print("NEXT CARD: ${deckCards.last.displayValue()}");
      botPlayer.hand.add(drawnCard);
      playableCards =
          botPlayer.hand.where((card) {
            return card.suit == upCard.suit ||
                card.value == upCard.value ||
                card.value == 8;
          }).toList();
      setState(() {
        // Update the UI after drawing a card
      });
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Simulate thinking time
    }
    List<CardData> playableCardsWithoutEights =
        playableCards.where((card) => card.value != 8).toList();
    if (playableCardsWithoutEights.isEmpty) {
      //Check if bot has any single suits
      Map<CardSuit, int> suitCounts = {
        CardSuit.hearts: 0,
        CardSuit.diamonds: 0,
        CardSuit.clubs: 0,
        CardSuit.spades: 0,
      };

      for (var card in botPlayer.hand) {
        if (card.value == 8) {
          // Ignore eights
          continue;
        }

        suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
      }
      CardData firstEight = playableCards.firstWhere((card) => card.value == 8);
      botPlayer.hand.removeWhere((card) => card.id == firstEight.id);
      CardSuit? chosenSuit;
      int maxCount = 0;
      suitCounts.forEach((suit, count) {
        if (count > maxCount) {
          maxCount = count;
          chosenSuit = suit;
        }
      });
      firstEight.suit = chosenSuit ?? firstEight.suit;

      print(
        "Playing first eight with suit: ${firstEight.suit} and value: ${firstEight.value}",
      );
      return firstEight;
    }
    //Check if bot has any single suits
    Map<CardSuit, int> suitCounts = {
      CardSuit.hearts: 0,
      CardSuit.diamonds: 0,
      CardSuit.clubs: 0,
      CardSuit.spades: 0,
    };

    for (var card in playableCardsWithoutEights) {
      if (card.value == 8) {
        // Ignore eights
        continue;
      }

      suitCounts[card.suit] = (suitCounts[card.suit] ?? 0) + 1;
    }

    //choose suit with most cards
    CardSuit? chosenSuit;
    int maxCount = 0;
    suitCounts.forEach((suit, count) {
      if (count > maxCount) {
        maxCount = count;
        chosenSuit = suit;
      }
    });
    if (chosenSuit != null && maxCount >= 1) {
      // If there is a suit with more than one card, play the random card of that suit
      List<CardData> suitCards =
          playableCards.where((card) => card.suit == chosenSuit).toList();
      if (suitCards.isNotEmpty) {
        //remove eights from suit cards

        suitCards.shuffle();
        CardData cardToPlay = suitCards.first;
        botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
        return cardToPlay;
      }
    }
    // If no single suits or only one card of a suit, play the first playable card
    CardData cardToPlay = playableCards.first;
    botPlayer.hand.removeWhere((card) => card.id == cardToPlay.id);
    return cardToPlay;
  }

  void playCard(List<CardData> pile) async {
    print("Playing card...");
    print("Difficulty: $difficulty");
    switch (difficulty) {
      case BotDifficulty.hard:
        CardData card = await playCardHard(pile);
        onPlayCard(card, id);
        return;
      case BotDifficulty.medium:
        CardData card = await playCardMedium(pile);
        onPlayCard(card, id);
        return;
      case BotDifficulty.easy:
        CardData card = await playCardEasy(pile);
        onPlayCard(card, id);
        return;
    }
  }
}
