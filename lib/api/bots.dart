import 'package:deckly/constants.dart';

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
  BotDifficulty difficulty;
  bool playingRound;
  int playSpeed = 1000; // Speed of the bot's turn, can be adjusted
  //Hard: 3000ms
  //Medium: 6000ms
  //Easy: 9000ms

  NertzBot({
    required this.name,
    required this.id,
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
    List<CardData> shuffledDeck = [...fullDeck];
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

  void reset() {
    deck.clear();
    pile.clear();
    blitzDeck.clear();

    privateDropZones.clear();
    playingRound = false;
  }

  void gameLoop() async {
    if (!playingRound) {
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
    print(
      "Bot $name is playing its turn with blitz deck: ${blitzDeck.map((card) => card.value.toString()).join(', ')}",
    );
    if (checkBlitzDeckPlays()) {
      print("Bot $name played a card from the blitz deck.");
      // If we can play a card from the blitz deck, we do so
      //Call gameLoop again to continue the bot's turn
      await Future.delayed(Duration(milliseconds: playSpeed), () => gameLoop());
      return;
    } else if (checkPilePlays()) {
      print("Bot $name played a card from the pile.");
      // If we can play a card from the pile, we do so
      //Call gameLoop again to continue the bot's turn
      await Future.delayed(Duration(milliseconds: playSpeed), () => gameLoop());
      return;
    } else if (checkPileMoves()) {
      print("Bot $name moved cards between piles.");
      // If we can move cards between piles, we do so
      //Call gameLoop again to continue the bot's turn
      await Future.delayed(Duration(milliseconds: playSpeed), () => gameLoop());
      return;
    } else if (checkDeckMoves()) {
      print("Bot $name drew cards from the deck.");
      // If we can draw cards from the deck, we do so
      //Call gameLoop again to continue the bot's turn
      await Future.delayed(Duration(milliseconds: playSpeed), () => gameLoop());
      return;
    } else {
      print("Bot $name has no valid moves.");
      await Future.delayed(Duration(milliseconds: playSpeed), () {
        // If no moves are possible, end the bot's turn
        gameLoop();
      });
    }
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
    print(
      "Bot $name drew cards from the deck. New pile: ${pile.map((card) => card.value.toString()).join(', ')}",
    );
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
