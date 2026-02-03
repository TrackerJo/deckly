import 'dart:io';

import 'package:deckly/main.dart';
import 'package:deckly/styling.dart';
import 'package:deckly/widgets/drop_zone.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';
import 'package:rate_my_app/rate_my_app.dart';

void nextScreen(context, page) {
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}

enum HapticLevel {
  none,
  light,
  medium,
  heavy;

  @override
  String toString() {
    switch (this) {
      case HapticLevel.none:
        return 'none';
      case HapticLevel.light:
        return 'light';
      case HapticLevel.medium:
        return 'medium';
      case HapticLevel.heavy:
        return 'heavy';
      default:
        return 'none';
    }
  }

  static HapticLevel fromString(String type) {
    switch (type) {
      case 'none':
        return HapticLevel.none;
      case 'light':
        return HapticLevel.light;
      case 'medium':
        return HapticLevel.medium;
      case 'heavy':
        return HapticLevel.heavy;
      default:
        return HapticLevel.none;
    }
  }
}

class GamePlayer {
  final String id;
  String name;
  bool isHost;
  bool isBot;
  final PlayerType type;

  GamePlayer({
    required this.id,
    required this.name,
    this.isHost = false,
    this.isBot = false,
    this.type = PlayerType.game,
  });

  factory GamePlayer.fromMap(Map<String, dynamic> m) {
    print("GamePlayer.fromMap: $m");
    final playerType = PlayerType.fromString(m['type'] as String? ?? 'game');
    switch (playerType) {
      case PlayerType.blitz:
        return BlitzPlayer.fromMap(m);
      case PlayerType.euchre:
        return EuchrePlayer.fromMap(m);
      case PlayerType.bot:
        return BotPlayer.fromMap(m);
      case PlayerType.crazyEight:
        return CrazyEightsPlayer.fromMap(m);
      case PlayerType.game:
        return GamePlayer(
          id: m['id'],
          name: m['name'],
          isHost: m['isHost'] == "true" || m['isHost'] == true,
          isBot: m['isBot'] == "true" || m['isBot'] == true,
          type: playerType,
        );
      case PlayerType.ohHell:
        return OhHellPlayer.fromMap(m);
      case PlayerType.kalamattack:
        return KalamattackPlayer.fromMap(m);
      // Default to GamePlayer if no specific type is found
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'isHost': isHost,
    'isBot': isBot,
    'type': type.toString(),
  };

  bool getIsHost() {
    return id.contains("-host");
  }
}

enum StackMode { overlay, spaced, spacedHorizontal }

class DropZoneData {
  final String id;

  final StackMode stackMode;
  final bool isDropArea;
  List<CardData> cards;
  DropZoneRules rules;
  bool canDragCardOut;
  double scale;
  bool isPublic;
  bool playable;
  DropZoneController? controller;
  bool isSolitaire;
  List<CardData> solitaireStartingCards;
  final Function(CardData)? onCardTapped;

  DropZoneData({
    required this.id,

    required this.stackMode,
    required this.rules,
    this.canDragCardOut = true,
    this.isDropArea = false,
    this.scale = 1.0,
    this.isPublic = false,
    List<CardData> cards = const [],
    this.playable = true,
    this.isSolitaire = false,
    this.solitaireStartingCards = const [],
    this.controller,
    this.onCardTapped,
  }) : cards = List.from(cards);

  factory DropZoneData.fromMap(Map<String, dynamic> m) {
    return DropZoneData(
      id: m['id'],
      canDragCardOut: m['canDragCardOut'] ?? true,

      stackMode: StackMode.values.firstWhere(
        (s) => s.toString() == m['stackMode'],
      ),
      rules: DropZoneRules.fromMap(m['rules'] as Map<String, dynamic>),
      scale: m['scale'] ?? 1,
      cards:
          (m['cards'] as List<dynamic>)
              .map((card) => CardData.fromMap(card as Map<String, dynamic>))
              .toList(),
      isPublic: m['isPublic'] ?? false,
      playable: m['playable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,

      'stackMode': stackMode.toString(),
      'cards': cards.map((c) => c.toMap()).toList(),
      'rules': rules.toMap(),
      'canDragCardOut': canDragCardOut,
      'scale': scale,
      'isPublic': isPublic,
      'playable': playable,
    };
  }
}

enum CardSuit {
  hearts,
  diamonds,
  clubs,
  spades;

  String toIcon() {
    switch (this) {
      case CardSuit.hearts:
        return '♥';
      case CardSuit.diamonds:
        return '♦';
      case CardSuit.clubs:
        return '♣';
      case CardSuit.spades:
        return '♠';
    }
  }

  @override
  String toString() {
    switch (this) {
      case CardSuit.hearts:
        return 'hearts';
      case CardSuit.diamonds:
        return 'diamonds';
      case CardSuit.clubs:
        return 'clubs';
      case CardSuit.spades:
        return 'spades';
    }
  }

  static CardSuit fromString(String suit) {
    return CardSuit.values.firstWhere(
      (s) => s.toString() == suit,
      orElse: () => CardSuit.hearts, // Default to hearts if not found
    );
  }

  CardSuit get alternateSuit {
    switch (this) {
      case CardSuit.hearts:
        return CardSuit.diamonds;
      case CardSuit.diamonds:
        return CardSuit.hearts;
      case CardSuit.clubs:
        return CardSuit.spades;
      case CardSuit.spades:
        return CardSuit.clubs;
    }
  }

  CardSuit get oppositeSuit {
    switch (this) {
      case CardSuit.hearts:
        return CardSuit.spades;
      case CardSuit.diamonds:
        return CardSuit.clubs;
      case CardSuit.clubs:
        return CardSuit.diamonds;
      case CardSuit.spades:
        return CardSuit.hearts;
    }
  }
}

class CardData {
  final String id;
  final int value;
  CardSuit suit;

  final bool isFaceUp;
  String? playedBy; // Optional field to track who played the card

  CardData({
    required this.id,
    required this.value,
    required this.suit,
    this.isFaceUp = true,
    this.playedBy,
  });
  factory CardData.fromMap(Map<String, dynamic> m) {
    return CardData(
      id: m['id'],
      value: m['value'],
      suit: CardSuit.fromString(m['suit'] as String),
      isFaceUp: m['isFaceUp'] ?? true,
      playedBy: m['playedBy'] as String?,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'value': value,
      'suit': suit.toString(),
      'isFaceUp': isFaceUp,
      'playedBy': playedBy,
    };
  }

  String displayValue() {
    return value.toString() + suit.toIcon();
  }

  MiniCard toMiniCard() {
    return MiniCard(value: value, suit: suit);
  }

  int toSortingValue({CardSuit? trumpSuit, bool isEuchre = false}) {
    // Convert card to value for scoring
    if (value == 1) {
      return 14; // Ace is third highest
    }
    if (value == 11 && suit.alternateSuit == trumpSuit && isEuchre) {
      return 15; // Jack of alternate trump suit is second highest
    }
    if (value == 11 && suit == trumpSuit) {
      return 16; // Jack of trump suit is highest
    }
    return value; // Other cards retain their value
  }
}

class DragData {
  List<CardData> cards;
  String sourceZoneId;
  int sourceIndex;

  DragData({
    required this.cards,
    required this.sourceZoneId,
    required this.sourceIndex,
  });
}

class MiniCard {
  final int value;
  final CardSuit suit;

  MiniCard({required this.value, required this.suit});

  factory MiniCard.fromCardData(CardData card) {
    return MiniCard(value: card.value, suit: card.suit);
  }

  factory MiniCard.fromMap(Map<String, dynamic> m) {
    return MiniCard(
      value: m['value'],
      suit: CardSuit.fromString(m['suit'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {'value': value, 'suit': suit.toString()};
  }

  bool compare(MiniCard other) {
    return value == other.value && suit == other.suit;
  }
}

enum CardOrder { ascending, descending, none }

enum AllowedCards { all, sameSuit, sameValue, sameColor, alternateColor, none }

class DropZoneRules {
  CardOrder cardOrder;
  AllowedCards allowedCards;
  List<MiniCard> bannedCards;
  List<MiniCard> startingCards;
  List<CardSuit> allowedSuits;
  DropZoneRules({
    required this.cardOrder,
    required this.allowedCards,
    required this.bannedCards,
    required this.startingCards,
    this.allowedSuits = const [],
  });

  factory DropZoneRules.fromMap(Map<String, dynamic> m) {
    return DropZoneRules(
      cardOrder: CardOrder.values.firstWhere(
        (o) => o.toString() == m['cardOrder'],
      ),
      allowedCards: AllowedCards.values.firstWhere(
        (a) => a.toString() == m['allowedCards'],
      ),
      bannedCards:
          (m['bannedCards'] as List<dynamic>)
              .map((c) => MiniCard.fromMap(c as Map<String, dynamic>))
              .toList(),
      startingCards:
          (m['startingCards'] as List<dynamic>)
              .map((c) => MiniCard.fromMap(c as Map<String, dynamic>))
              .toList(),
      allowedSuits:
          (m['allowedSuits'] as List<dynamic>)
              .map((s) => CardSuit.fromString(s as String))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardOrder': cardOrder.toString(),
      'allowedCards': allowedCards.toString(),
      'bannedCards': bannedCards.map((c) => c.toMap()).toList(),
      'startingCards': startingCards.map((c) => c.toMap()).toList(),
      'allowedSuits': allowedSuits.map((s) => s.toString()).toList(),
    };
  }
}

enum PlayerType {
  blitz,
  euchre,
  bot,
  crazyEight,
  ohHell,
  kalamattack,
  game;

  @override
  String toString() {
    switch (this) {
      case PlayerType.blitz:
        return 'Blitz';
      case PlayerType.euchre:
        return 'Euchre';
      case PlayerType.bot:
        return 'Bot';
      case PlayerType.game:
        return 'Game';
      case PlayerType.crazyEight:
        return 'Crazy Eight';
      case PlayerType.ohHell:
        return 'Oh Hell';
      case PlayerType.kalamattack:
        return 'Kalamattack';
    }
  }

  static PlayerType fromString(String type) {
    return PlayerType.values.firstWhere(
      (p) => p.toString() == type,
      orElse: () => PlayerType.game, // Default to game if not found
    );
  }
}

class BlitzPlayer extends GamePlayer {
  int score;
  int blitzDeckSize;
  bool isStuck;

  BlitzPlayer({
    required super.id,
    required super.name,
    required this.score,
    required this.blitzDeckSize,
    super.isHost = false,
    this.isStuck = false,
    super.isBot = false,
    super.type = PlayerType.blitz,
  });

  factory BlitzPlayer.fromMap(Map<String, dynamic> m) {
    return BlitzPlayer(
      id: m['id'],
      name: m['name'],
      score: m['score'] ?? 0,
      blitzDeckSize: m['blitzDeckSize'] ?? 0,
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      isStuck: m['isStuck'] ?? false,
      isBot: m['isBot'] == "true" || m['isBot'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'blitzDeckSize': blitzDeckSize,
      'isHost': isHost,
      'isStuck': isStuck,
      'type': type.toString(),
      'isBot': isBot,
    };
  }
}

class EuchrePlayer extends GamePlayer {
  bool isDealer;
  bool onTeamA;
  List<CardData> hand;
  bool myTurn;

  EuchrePlayer({
    required super.id,
    required super.name,
    this.isDealer = false,
    required this.onTeamA,
    required this.hand,
    super.isHost = false,
    this.myTurn = false,
    super.type = PlayerType.euchre,
    super.isBot = false,
  });

  factory EuchrePlayer.fromMap(Map<String, dynamic> m) {
    return EuchrePlayer(
      id: m['id'],
      name: m['name'],
      isDealer: m['isDealer'] ?? false,
      onTeamA: m['onTeamA'] ?? true,
      hand:
          (m['hand'] as List<dynamic>)
              .map((card) => CardData.fromMap(card as Map<String, dynamic>))
              .toList(),
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      myTurn: m['myTurn'] ?? false,
      isBot: m['isBot'] == "true" || m['isBot'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDealer': isDealer,
      'onTeamA': onTeamA,
      'hand': hand.map((c) => c.toMap()).toList(),
      'isHost': isHost,
      'myTurn': myTurn,
      'type': type.toString(),
      'isBot': isBot,
    };
  }
}

class EuchreTeam {
  List<EuchrePlayer> players;
  int score;
  bool madeIt;
  int tricksTaken;

  EuchreTeam({
    required this.players,
    this.score = 0,
    this.madeIt = false,
    this.tricksTaken = 0,
  });

  factory EuchreTeam.fromMap(Map<String, dynamic> m) {
    return EuchreTeam(
      players:
          (m['players'] as List<dynamic>)
              .map((p) => EuchrePlayer.fromMap(p as Map<String, dynamic>))
              .toList(),
      score: m['score'] ?? 0,
      madeIt: m['madeIt'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'players': players.map((p) => p.toMap()).toList(),
      'score': score,
      'madeIt': madeIt,
    };
  }
}

class CrazyEightsPlayer extends GamePlayer {
  List<CardData> hand;
  bool myTurn;

  CrazyEightsPlayer({
    required super.id,
    required super.name,
    this.hand = const [],
    super.isHost = false,
    this.myTurn = false,
    super.isBot = false,
    super.type = PlayerType.crazyEight,
  });

  factory CrazyEightsPlayer.fromMap(Map<String, dynamic> m) {
    return CrazyEightsPlayer(
      id: m['id'],
      name: m['name'],
      hand:
          (m['hand'] as List<dynamic>)
              .map((card) => CardData.fromMap(card as Map<String, dynamic>))
              .toList(),
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      myTurn: m['myTurn'] ?? false,
      isBot: m['isBot'] == "true" || m['isBot'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hand': hand.map((c) => c.toMap()).toList(),
      'isHost': isHost,
      'myTurn': myTurn,
      'type': type.toString(),
      'isBot': isBot,
    };
  }
}

class Shield {
  int health;
  int roundsLeft;

  Shield({required this.health, required this.roundsLeft});
  factory Shield.fromMap(Map<String, dynamic> m) {
    return Shield(health: m['health'] ?? 0, roundsLeft: m['roundsLeft'] ?? 0);
  }

  Map<String, dynamic> toMap() {
    return {'health': health, 'roundsLeft': roundsLeft};
  }
}

class KalamattackPlayer extends GamePlayer {
  List<CardData> hand;
  bool myTurn;
  int health;
  bool hasFunctionalKingdom;
  bool isPoisoned;
  int poisonedRoundsLeft; // Default to 0, can be set later
  bool isDefending;
  List<Shield> shields;

  KalamattackPlayer({
    required super.id,
    required super.name,
    this.hand = const [],
    super.isHost = false,
    this.myTurn = false,
    super.isBot = false,
    this.health = 20,
    this.hasFunctionalKingdom = false,
    this.isPoisoned = false,
    this.isDefending = false,
    this.poisonedRoundsLeft = 0, // Default to 0, can be set later
    List<Shield>? shields,
    super.type = PlayerType.kalamattack,
  }) : shields = shields ?? <Shield>[];

  factory KalamattackPlayer.fromMap(Map<String, dynamic> m) {
    return KalamattackPlayer(
      id: m['id'],
      name: m['name'],
      hand:
          (m['hand'] as List<dynamic>)
              .map((card) => CardData.fromMap(card as Map<String, dynamic>))
              .toList(),
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      myTurn: m['myTurn'] ?? false,
      isBot: m['isBot'] == "true" || m['isBot'] == true,
      health: m['health'] ?? 20,
      hasFunctionalKingdom: m['hasFunctionalKingdom'] ?? false,
      isPoisoned: m['isPoisoned'] ?? false,
      isDefending: m['isDefending'] ?? false,
      shields:
          (m['shields'] as List<dynamic>?)
              ?.map((s) => Shield.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      poisonedRoundsLeft: m['poisonedRoundsLeft'] ?? 0, // Default to 0
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hand': hand.map((c) => c.toMap()).toList(),
      'isHost': isHost,
      'myTurn': myTurn,
      'type': type.toString(),
      'isBot': isBot,
      'health': health,
      'hasFunctionalKingdom': hasFunctionalKingdom,
      'isPoisoned': isPoisoned,
      'isDefending': isDefending,
      'shields': shields.map((s) => s.toMap()).toList(),
      'poisonedRoundsLeft': poisonedRoundsLeft, // Include poisoned rounds left
    };
  }

  int get totalShieldHealth {
    return shields.fold(0, (total, shield) => total + shield.health);
  }

  void damage(int amount) {
    List<Shield> remainingShields = [...shields];
    int remainingAmount = amount;
    for (var shield in remainingShields) {
      if (remainingAmount <= 0) break;
      if (shield.health > 0) {
        if (shield.health >= remainingAmount) {
          shield.health -= remainingAmount;
          remainingAmount = 0;
        } else {
          remainingAmount -= shield.health;
          shield.health = 0;
        }
      }
      if (shield.health <= 0) {
        shields.remove(shield);
      }
    }
    if (remainingAmount > 0) {
      health -= remainingAmount;
      if (health < 0) {
        health = 0; // Prevent negative health
      }
    }
  }
}

class OhHellPlayer extends GamePlayer {
  int score;
  int bid;
  int tricksTaken;
  List<CardData> hand;
  bool myTurn;
  bool isDealer;
  OhHellPlayer({
    required super.id,
    required super.name,
    this.score = 0,
    this.bid = 0,
    this.tricksTaken = 0,
    this.hand = const [],
    super.isHost = false,
    this.myTurn = false,
    this.isDealer = false,
    super.isBot = false,
    super.type = PlayerType.ohHell,
  });

  factory OhHellPlayer.fromMap(Map<String, dynamic> m) {
    return OhHellPlayer(
      id: m['id'],
      name: m['name'],
      score: m['score'] ?? 0,
      bid: m['bid'] ?? 0,
      tricksTaken: m['tricksTaken'] ?? 0,
      isDealer: m['isDealer'] == "true" || m['isDealer'] == true,
      hand:
          ((m['hand'] ?? []) as List<dynamic>)
              .map((card) => CardData.fromMap(card as Map<String, dynamic>))
              .toList(),
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      myTurn: m['myTurn'] ?? false,
      isBot: m['isBot'] == "true" || m['isBot'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'bid': bid,
      'tricksTaken': tricksTaken,
      'hand': hand.map((c) => c.toMap()).toList(),
      'isHost': isHost,
      'myTurn': myTurn,
      'isDealer': isDealer,
      'type': type.toString(),
      'isBot': isBot,
    };
  }
}

List<CardData> fullDeck = [
  for (var suit in CardSuit.values)
    for (var value = 1; value <= 13; value++)
      CardData(
        id: '${suit.toString()}_$value',
        value: value,
        suit: suit,
        isFaceUp: true,
      ),
];

List<CardData> fullKalamattackDeck = [
  for (var suit in CardSuit.values)
    for (var value = 1; value <= 13; value++)
      CardData(
        id: '${suit.toString()}_$value',
        value: value,
        suit: suit,
        isFaceUp: true,
      ),
  CardData(id: "red_joker", value: 0, suit: CardSuit.hearts, isFaceUp: true),
  CardData(id: "black_joker", value: 0, suit: CardSuit.spades, isFaceUp: true),
];

List<CardData> fullBlitzDeck = [
  for (var suit in CardSuit.values)
    for (var value = 1; value <= 10; value++)
      CardData(
        id: '${suit.toString()}_$value',
        value: value,
        suit: suit,
        isFaceUp: true,
      ),
];

List<CardData> fullEuchreDeck = [
  for (var suit in CardSuit.values)
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

enum NertzGameState {
  waitingForPlayers,
  playing,
  leaderboard,
  gameOver,
  paused,
}

enum EuchreGameState {
  teamSelection,
  waitingForPlayers,
  playing,
  gameOver,
  paused,
}

enum EuchreGamePhase { decidingTrump, discardingCard, playing }

enum CrazyEightsGameState { waitingForPlayers, playing, gameOver, paused }

enum KalamattackGameState { waitingForPlayers, playing, gameOver, paused, dead }

enum KalamattackGamePhase {
  selectingMove,
  attacking,
  defending,
  discardingCard,
  othersAttacking,
  choosingKalamattack,
}

enum OhHellGameState { waitingForPlayers, playing, gameOver, paused }

enum OhHellGamePhase { bidding, playing }

enum Game {
  nertz,
  euchre,
  crazyEights,
  kalamattack,
  ohHell,
  dash;

  @override
  String toString() {
    switch (this) {
      case Game.nertz:
        return 'Nertz';
      case Game.dash:
        return 'Nordic Dash';
      case Game.euchre:
        return 'Euchre';
      case Game.crazyEights:
        return 'Crazy Eights';
      case Game.kalamattack:
        return 'Kalamattack';
      case Game.ohHell:
        return 'Oh Hell';
    }
  }

  static Game fromString(String game) {
    return Game.values.firstWhere(
      (g) => g.toString() == game,
      orElse: () => Game.nertz, // Default to Nertz if not found
    );
  }
}

enum BotDifficulty {
  easy,
  medium,
  hard;

  @override
  String toString() {
    switch (this) {
      case BotDifficulty.easy:
        return 'Easy';
      case BotDifficulty.medium:
        return 'Medium';
      case BotDifficulty.hard:
        return 'Hard';
    }
  }

  static BotDifficulty fromString(String difficulty) {
    return BotDifficulty.values.firstWhere(
      (d) => d.toString() == difficulty,
      orElse: () => BotDifficulty.easy, // Default to easy if not found
    );
  }
}

class BotPlayer extends GamePlayer {
  BotDifficulty difficulty;
  BotPlayer({
    required super.id,
    required super.name,
    super.isHost = false,
    required this.difficulty,
    super.isBot = true,
    super.type = PlayerType.bot,
  });

  factory BotPlayer.fromMap(Map<String, dynamic> m) {
    return BotPlayer(
      id: m['id'],
      name: m['name'],
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      difficulty: BotDifficulty.fromString(m['difficulty'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isHost': isHost,
      'difficulty': difficulty.toString(),
      'isBot': isBot,
      'type': type.toString(),
    };
  }
}

enum UpdateStatus { none, available, required }

void showSnackBar(BuildContext context, Color color, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 14)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ),
  );
}

List<Widget> nertzRules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Nertz",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText(
    'The goal of Nertz is to be the first player to get rid of all the cards '
    'in your Nertz pile. Everyone plays at the same time and tries to move cards as fast as possible.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Each player has:\n'
    '- A Nertz pile with 13 cards. Only the top card is face up and can be played.\n'
    '- A draw pile made from the rest of your cards. You flip through it three cards at a time.\n'
    '- Four work piles where you build cards from high to low, switching red and black colors.\n'
    '- Shared center piles where everyone builds piles starting with Aces, going up to Kings, in the same suit.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionText(
    'You can:\n'
    '- Move the top card of your Nertz pile to your work piles or the center piles.\n'
    '- Move cards between your work piles to make space.\n'
    '- Use the top card from your draw pile if it can be played.\n'
    '- Flip through your draw pile again and again.\n\n'
    'Everyone plays at the same time. When a player uses all the cards in their Nertz pile, '
    'they press “Nertz!” and the round ends.',
  ),

  sectionTitle('🧮 Scoring'),
  sectionText(
    'At the end of the round:\n'
    '- You get 1 point for each card played in the center piles.\n'
    '- You lose 1 point for each card left in your Nertz pile.\n'
    '- The player who called “Nertz” gets 5 extra points.',
  ),

  sectionTitle('🏁 Ending the Game'),
  sectionText(
    'Keep playing rounds until someone reaches a set number of points, like 100 or 150.\n'
    'You can also stop after a certain number of rounds or when one player is far ahead.',
  ),
];

List<Widget> dutchBlitzRules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Nordic Dash",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText(
    'The goal of Nordic Dash is to be the first player to get rid of all the cards '
    'in your Dash pile. Everyone plays at the same time and tries to move cards as fast as possible.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Each player has:\n'
    '- A Dash pile with 10 cards. Only the top card is face up and can be played.\n'
    '- A draw pile made from the rest of your cards. You flip through it three cards at a time.\n'
    '- Four work piles where you build cards from high to low, switching guys and girls.\n'
    '- Shared center piles where everyone builds piles starting with 1s, going up to 10s, in the same color.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionText(
    'You can:\n'
    '- Move the top card of your Dash pile to your work piles or the center piles.\n'
    '- Move cards between your work piles to make space.\n'
    '- Use the top card from your draw pile if it can be played.\n'
    '- Flip through your draw pile again and again.\n\n'
    'Everyone plays at the same time. When a player uses all the cards in their Dash pile, '
    'they press Dash!” and the round ends.',
  ),

  sectionTitle('🧮 Scoring'),
  sectionText(
    'At the end of the round:\n'
    '- You get 1 point for each card played in the center piles.\n'
    '- You lose 2 points for each card left in your Dash pile.',
  ),

  sectionTitle('🏁 Ending the Game'),
  sectionText(
    'Keep playing rounds until someone reaches a set number of points, like 100 or 150.\n'
    'You can also stop after a certain number of rounds or when one player is far ahead.',
  ),
];

List<Widget> euchreRules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Euchre",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText(
    'Be the first team to reach 10 points by winning tricks. A trick is one round where everyone plays one card.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Players: 4 players in 2 teams.\n'
    'Deck: 24 cards (9 through Ace in each suit).\n'
    'Deal: Each player gets 5 cards. The rest goes in a pile next to the dealer; top card is turned face up.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionHeader('1. Deciding Trump'),
  sectionText(
    '- The suit of the face-up card in the pile next to the dealer can be called trump (the strongest suit).\n'
    '- Going clockwise, each player decides whether to "order up" (make that suit trump) or pass.\n'
    '- If a player orders up, the dealer picks up the card and discards one from their hand.\n'
    '- If everyone passes, a second round of choosing a different trump suit happens.\n'
    '- Players can also choose to "go alone" (play without their partner for bonus points).\n'
    '- If no one calls trump, the dealer must pick a suit.\n\n'
    'In trump suits:\n'
    '- The highest card is the Jack of trump (called the Right Bower).\n'
    '- The second highest is the other Jack of the same color (called the Left Bower).\n'
    '- Then Ace, King, Queen, 10, 9 follow in that suit.',
  ),
  sectionHeader('2. Playing Tricks'),
  sectionText(
    '- The player to the left of the dealer starts.\n'
    '- Players must follow the suit led if they can.\n'
    '- If not, they can play any card.\n'
    '- The highest trump card wins the trick. If no trump is played, the highest card in the lead suit wins.\n'
    '- The winner of the trick leads the next one.',
  ),

  sectionTitle('🧮 Scoring'),
  sectionText(
    'Scoring is based on how many tricks your team wins, wether your team called trump, and if you went alone:\n'
    'If your team called trump:\n'
    '- 3 or 4 tricks: 1 point\n'
    '- 5 tricks: 2 points\n'
    'If your team went alone and won:\n'
    '- 3 or 4 tricks: 1 point\n'
    '- 5 tricks: 4 points\n'
    'If your team did not call trump:\n'
    '- 3+ tricks: 2 points',
  ),

  sectionTitle('🏁 Ending the Game'),
  sectionText('Play continues until one team reaches 10 points.'),
];

List<Widget> solitaireRules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Solitaire",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText(
    'Move all cards into the 4 foundation piles, sorted by suit (♠ ♥ ♦ ♣) and in order from Ace to King.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Players: 4 players in 2 teams.\n'
    'Deck: Standard 52-card deck\n'
    'Layout:\n'
    '\t\t- 7 tableau piles: The first pile has 1 card, the second has 2, and so on up to 7 cards in the last pile.\n'
    '\t\t- 4 foundation piles: These are empty at the start and will hold the sorted cards.\n'
    '\t\t- 24 cards in the stock pile: These are face down and will be drawn from during the game.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionHeader('1. Moving Cards'),
  sectionText(
    '- You can move cards between the 7 piles by stacking them in descending order, alternating red and black cards.\n'
    '- Only faceup cards can be moved. When a face-down card is uncovered, it will flip it over.',
  ),
  sectionHeader('2. Drawing Cards'),
  sectionText(
    '- Tap on the deck to draw three cards\n'
    '- Only the top drawn card is playable.\n'
    '- When the draw pile is empty, tap the refresh icon to move the cards back to the draw pile.',
  ),
  sectionHeader('3. Foundation Piles'),
  sectionText(
    '- Move cards to the foundation piles when they are in order (Ace to King) and in the same suit.\n'
    '- You can only move cards to the foundation piles if they are in the correct order and suit.',
  ),
  sectionHeader('4. Empty Tableau Piles'),
  sectionText(
    '- If you empty a tableau pile, you can only place a king there.',
  ),

  sectionTitle('🏁 Ending the Game'),
  sectionText(
    'You win when all 52 cards are placed in the foundation piles.\n'
    'If you can\'t make any more moves, the game is over.',
  ),
];

List<Widget> crazy8Rules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Crazy Eights",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText('Be the first player to get rid of all cards in your hand.'),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Players: 2-5\n'
    'Deck: Standard 52-card deck\n'
    'Deal:\n'
    '\t\t- 2 players: 7 cards each; 3+ players: 5 cards each.\n'
    '\t\t- Rest of the cards in the center as the draw pile\n'
    '\t\t- Top card of the draw pile is turned face up to start the discard pile.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionText(
    'Turns are taken clockwise, starting left of the dealer automatically for each round.',
  ),
  sectionHeader('1. Playing Cards'),
  sectionText(
    '- You may play a card that matches the rank (number/face) or suit of the top discard card.\n'
    '- All 8s are wild: play an 8 anytime and declare the next suit.',
  ),
  sectionHeader('2. Drawing Cards'),
  sectionText(
    '- If you can’t play, draw one card at a time until you get a playable card',
  ),
  sectionTitle('🏁 Ending the Game'),
  sectionText('The game ends as soon as someone plays their last card.'),
];

List<Widget> kalamatackRules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Kalamatack",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText(
    'Be the last player standing with health above 0 by attacking others and defending yourself using smart card combinations.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Players: 2-5\n'
    'Deck: Standard 54-card deck with Jokers\n'
    'Each player starts with 4 cards.\n'
    'Place the rest face-down as the draw pile. Turn 3 cards face-up next to it.\n'
    'Each player starts with 20 health points.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionText('Turns are taken clockwise'),
  sectionHeader('1. Drawing Cards'),
  sectionText(
    '- On your turn, you may draw from the draw pile or one of the 3 face-up cards.\n'
    '- If a face-up card is taken, it will be replaced with a new one from the draw pile.\n'
    '- You can hold up to 6 cards in your hand.\n'
    '\t\t- If you already have 6 cards, you can swap: draw one card, then choose any card to discard.',
  ),
  sectionHeader('2. Attacking'),
  sectionText(
    '- You can attack once per turn using one of these:\n'
    '\t\tSingle card (2–10 only): damage = card value\n'
    '\t\tPair (two of the same value): damage = sum + 2\n'
    '\t\tThree of a kind (three of the same value): damage = sum + 3\n'
    '\t\tRun (3 or 4 cards in sequence, suit doesn\'t matter): damage = sum\n'
    '- No Aces or face cards in attacks.\n'
    '- Players can only be attacked once between their own turns.\n'
    '- After attacking, discard used cards.\n'
    '- Attack takes up your whole turn.',
  ),
  sectionHeader('3. Defending'),
  sectionText(
    '- After being attacked, you can defend using one of these:\n'
    '\t\tSingle card: block damage = card value\n'
    '\t\tPair: block damage = sum + 2\n'
    '\t\tRun: block damage = sum\n'
    '\t\tAce:\n'
    '\t\t\t\t1 Ace: blocks 50%\n'
    '\t\t\t\t2 Aces: blocks 100%\n'
    '\t\tJoker:\n'
    '\t\t\t\t1 Joker: Reflects 50% of damage (attacker receives 50% damage, defender receives 50% damage)\n'
    '\t\t\t\t2 Jokers: Reflects 100% of damage (attacker receives 100% damage, defender receives 0% damage)\n'
    '- Discard all defense cards after use.\n'
    '- Defending does not skip your next turn.',
  ),
  sectionTitle('✨ Special Cards'),
  sectionHeader('🛡️ Shield'),
  sectionText(
    '- Play Jacks to gain 5 shield points each (max 4).\n'
    '- Shields absorb damage before HP.\n'
    '- Shields last 2 full turns after being played.\n'
    '- Playing shields uses up your turn.',
  ),
  sectionHeader('🏰 Functional Kingdom'),
  sectionText(
    '- If a player holds a Jack, Queen, and King, they can’t take more than 10 HP in a single hit.\n'
    '- This cap applies after defense cards are played.\n'
    '- You can fully defend attacks by playing one of the functional kingdom cards (Jack, Queen, King) as a defense card.',
  ),
  sectionHeader('☠️ Kalamattack'),
  sectionText(
    '- Play a King and Queen of opposite colors to poison any player.\n'
    '- Poison lasts 3 turns, dealing 5 damage at the start of each of their turns.\n'
    '- Poison can’t kill—it leaves them at 1 HP minimum.\n'
    '- Poison does not deal damage right away.\n'
    '- Poisoned players can’t defend against Kalamattack.\n'
    '- Playing a kalamattack uses up your turn.',
  ),
  sectionTitle('🏁 Ending the Game'),
  sectionText('The game ends when only one player has health above 0.'),
];

List<Widget> ohHellRules = [
  Padding(
    padding: const EdgeInsets.all(8.0),
    child: Text(
      "How to Play Oh Hell",
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  ),
  Divider(color: styling.primary, thickness: 1.5),
  sectionTitle('🎯 Goal'),
  sectionText(
    'End the game with the most points by correctly predicting how many tricks you’ll win in each round.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Players: 3-8\n'
    'Deck: Standard 52-card deck\n'
    'Deal: The first round everyone gets 10 cards (or 8 cards for 6 players, 7 cards for 7 players, and 6 cards for 8 players) then after each round the number of cards everyone gets goes down by one, ending at everyone getting 1 card.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionHeader('1. Bidding'),
  sectionText(
    '- Starting with the player left of the dealer, each player says how many tricks they think they’ll win\n'
    '- Dealer bids last, but their bid cannot make total bids equal total tricks (someone must fail)',
  ),
  sectionHeader('2. Playing Tricks'),
  sectionText(
    '- The player to the left of the dealer starts.\n'
    '- Players must follow the suit led if they can.\n'
    '- If not, they can play any card.\n'
    '- The highest trump card wins the trick. If no trump is played, the highest card in the lead suit wins.\n'
    '- The winner of the trick leads the next one.',
  ),

  sectionTitle('🧮 Scoring'),
  sectionText(
    '- Scoring is based on how many tricks you took and if your bid was correct:\n'
    '\t\tCorrect Bid:\n'
    '\t\t\t\t10 points + number of tricks taken\n'
    '\t\tIncorrect Bid:\n'
    '\t\t\t\tjust the number of tricks taken',
  ),

  sectionTitle('🏁 Ending the Game'),
  sectionText(
    '- Play continues until the last round where everyone gets 1 card.\n'
    '- The player with the most points at the end wins.',
  ),
];

Widget sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: styling.primary,
      ),
    ),
  );
}

Widget sectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}

Widget sectionText(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12.0),
    child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
  );
}

bool isTablet(BuildContext context) {
  var shortestSide = MediaQuery.sizeOf(context).shortestSide;

  // Determine if we should use mobile layout or not, 600 here is
  // a common breakpoint for a typical 7-inch tablet.
  return shortestSide >= 600;
}

class RateAppHelper {
  RateAppHelper({RateMyApp? rateMyApp})
    : _rateMyApp =
          rateMyApp ??
          RateMyApp(
            minDays: 0,
            minLaunches: 0,
            remindDays: 2,
            remindLaunches: 4,
            googlePlayIdentifier: 'com.kazoom.deckly',
            appStoreIdentifier: '6746527909',
          ) {
    initialize();
  }

  bool _isNativeReviewDialogSupported = false;

  final RateMyApp _rateMyApp;

  Future<void> initialize() async {
    await _rateMyApp.init();
    _isNativeReviewDialogSupported =
        await _rateMyApp.isNativeReviewDialogSupported ?? false;
  }

  void launchStore() async {
    print("RateMyApp: Launching store");
    await _rateMyApp.launchStore();
  }

  // Show native review dialog or standard.
  void showDialog(BuildContext context) {
    print("RateMyApp: shouldOpenDialog: ${_rateMyApp.shouldOpenDialog}");
    if (_rateMyApp.shouldOpenDialog || true) {
      if (Platform.isIOS && _isNativeReviewDialogSupported) {
        print("RateMyApp: Launching native review dialog");
        _rateMyApp.launchNativeReviewDialog();
      } else if (Platform.isAndroid) {
        _rateMyApp.showStarRateDialog(
          context,
          title: 'Rate App',
          message:
              "If you're enjoying the app, please leave a rating to support us!",
          actionsBuilder: (context, stars) {
            return [
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  // Launch store if user rates 5 stars.
                  if (stars != null && stars.round().toInt() >= 3) {
                    await _rateMyApp.launchStore();
                  }
                  await _rateMyApp.callEvent(
                    RateMyAppEventType.rateButtonPressed,
                  );

                  if (context.mounted) {
                    Navigator.pop<RateMyAppDialogButton>(
                      context,
                      RateMyAppDialogButton.rate,
                    );
                  }
                },
              ),
            ];
          },
        );
      } else {
        _rateMyApp.showStarRateDialog(
          context,
          title: 'Rate App',

          message:
              "If you're enjoying the app, please leave a rating to support us!",
          // actionsBuilder: (context, stars) {
          //   return [
          //     TextButton(
          //       child: const Text('OK'),
          //       onPressed: () async {
          //         // Launch store if user rates 5 stars.
          //         if (stars != null && stars.round().toInt() >= 3) {
          //           await _rateMyApp.launchStore();
          //         }
          //         await _rateMyApp.callEvent(
          //           RateMyAppEventType.rateButtonPressed,
          //         );

          //         if (context.mounted) {
          //           Navigator.pop<RateMyAppDialogButton>(
          //             context,
          //             RateMyAppDialogButton.rate,
          //           );
          //         }
          //       },
          //     ),
          //   ];
          // },
        );
      }
    }
  }
}

class GameJoinResult {
  final List<GamePlayer> players;
  final Game game;

  GameJoinResult({required this.players, required this.game});
}
