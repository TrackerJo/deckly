import 'package:deckly/main.dart';
import 'package:deckly/styling.dart';
import 'package:deckly/widgets/drop_zone.dart';
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
      case PlayerType.game:
        return GamePlayer(
          id: m['id'],
          name: m['name'],
          isHost: m['isHost'] == "true" || m['isHost'] == true,
          isBot: m['isBot'] == "true" || m['isBot'] == true,
          type: playerType,
        );
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
  DropZoneController? controller;

  DropZoneData({
    required this.id,

    required this.stackMode,
    required this.rules,
    this.canDragCardOut = true,
    this.scale = 1.0,
    this.isPublic = false,
    List<CardData> cards = const [],
    this.playable = true,
    this.controller,
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

  int toSortingValue({CardSuit? trumpSuit}) {
    // Convert card to value for scoring
    if (value == 1) {
      return 14; // Ace is third highest
    }
    if (value == 11 && suit.alternateSuit == trumpSuit) {
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

enum PlayerType {
  blitz,
  euchre,
  bot,
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
      "How to Play Dutch Blitz",
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
    'The goal of Dutch Blitz is to be the first player to get rid of all the cards '
    'in your Blitz pile. Everyone plays at the same time and tries to move cards as fast as possible.',
  ),
  sectionTitle('🧰 Setup'),
  sectionText(
    'Each player has:\n'
    '- A Blitz pile with 10 cards. Only the top card is face up and can be played.\n'
    '- A draw pile made from the rest of your cards. You flip through it three cards at a time.\n'
    '- Four work piles where you build cards from high to low, switching guys and girls.\n'
    '- Shared center piles where everyone builds piles starting with 1s, going up to 10s, in the same suit.',
  ),
  sectionTitle('🃏 Gameplay'),
  sectionText(
    'You can:\n'
    '- Move the top card of your Blitz pile to your work piles or the center piles.\n'
    '- Move cards between your work piles to make space.\n'
    '- Use the top card from your draw pile if it can be played.\n'
    '- Flip through your draw pile again and again.\n\n'
    'Everyone plays at the same time. When a player uses all the cards in their Blitz pile, '
    'they press Blitz!” and the round ends.',
  ),

  sectionTitle('🧮 Scoring'),
  sectionText(
    'At the end of the round:\n'
    '- You get 1 point for each card played in the center piles.\n'
    '- You lose 2 points for each card left in your Blitz pile.',
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
  secitonHeader('1. Deciding Trump'),
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
  secitonHeader('2. Playing Tricks'),
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

Widget secitonHeader(String title) {
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
