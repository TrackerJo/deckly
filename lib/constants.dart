import 'package:deckly/main.dart';
import 'package:deckly/styling.dart';
import 'package:deckly/widgets/playing_card.dart';
import 'package:flutter/material.dart';

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
  final String name;
  final bool isHost;

  GamePlayer({required this.id, required this.name, this.isHost = false});

  factory GamePlayer.fromMap(Map<String, dynamic> m) =>
      GamePlayer(id: m['id'], name: m['name'], isHost: m['isHost'] ?? false);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'isHost': isHost};
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

  DropZoneData({
    required this.id,

    required this.stackMode,
    required this.rules,
    this.canDragCardOut = true,
    this.scale = 1.0,
    this.isPublic = false,
    List<CardData> cards = const [],
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
}

class CardData {
  final String id;
  final int value;
  final CardSuit suit;

  final bool isFaceUp;
  final String? playedBy; // Optional field to track who played the card

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
  DropZoneRules({
    required this.cardOrder,
    required this.allowedCards,
    required this.bannedCards,
    required this.startingCards,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardOrder': cardOrder.toString(),
      'allowedCards': allowedCards.toString(),
      'bannedCards': bannedCards.map((c) => c.toMap()).toList(),
      'startingCards': startingCards.map((c) => c.toMap()).toList(),
    };
  }
}

class BlitzPlayer {
  final String id;
  final String name;
  final int score;
  final int blitzDeckSize;
  final bool isHost;
  BlitzPlayer({
    required this.id,
    required this.name,
    required this.score,
    required this.blitzDeckSize,
    this.isHost = false,
  });

  factory BlitzPlayer.fromMap(Map<String, dynamic> m) {
    return BlitzPlayer(
      id: m['id'],
      name: m['name'],
      score: m['score'] ?? 0,
      blitzDeckSize: m['blitzDeckSize'] ?? 0,
      isHost: m['isHost'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'blitzDeckSize': blitzDeckSize,
      'isHost': isHost,
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
