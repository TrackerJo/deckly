import 'package:deckly/main.dart';
import 'package:deckly/styling.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';

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

  GamePlayer({required this.id, required this.name, this.isHost = false});

  factory GamePlayer.fromMap(Map<String, dynamic> m) =>
      GamePlayer(id: m['id'], name: m['name'], isHost: m['isHost'] ?? false);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'isHost': isHost};

  bool getIsHost() {
    return id.contains("-host");
  }
}

enum StackMode { overlay, spaced }

class DropZoneData {
  final String id;

  final StackMode stackMode;
  List<CardData> cards;
  DropZoneRules rules;
  bool canDragCardOut;
  double scale;
  bool isPublic;
  bool playable;

  DropZoneData({
    required this.id,

    required this.stackMode,
    required this.rules,
    this.canDragCardOut = true,
    this.scale = 1.0,
    this.isPublic = false,
    List<CardData> cards = const [],
    this.playable = true,
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

  MiniCard toMiniCard() {
    return MiniCard(value: value, suit: suit);
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

enum AllowedCards { all, sameSuit, sameValue, sameColor, alternateColor }

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
  });

  factory BlitzPlayer.fromMap(Map<String, dynamic> m) {
    return BlitzPlayer(
      id: m['id'],
      name: m['name'],
      score: m['score'] ?? 0,
      blitzDeckSize: m['blitzDeckSize'] ?? 0,
      isHost: m['isHost'] == "true" || m['isHost'] == true,
      isStuck: m['isStuck'] ?? false,
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

enum NertzGameState { waitingForPlayers, playing, leaderboard, gameOver }

enum EuchreGameState { teamSelection, waitingForPlayers, playing, gameOver }

enum EuchreGamePhase { decidingTrump, discardingCard, playing }

enum Game {
  nertz,
  euchre,
  blitz;

  @override
  String toString() {
    switch (this) {
      case Game.nertz:
        return 'Nertz';
      case Game.blitz:
        return 'Dutch Blitz';
      case Game.euchre:
        return 'Euchre';
    }
  }

  static Game fromString(String game) {
    return Game.values.firstWhere(
      (g) => g.toString() == game,
      orElse: () => Game.nertz, // Default to Nertz if not found
    );
  }
}
