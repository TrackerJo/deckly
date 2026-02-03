import 'dart:async';
import 'dart:math';

import 'package:deckly/api/bots.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/action_button.dart';

import 'package:deckly/widgets/crazy_eights_deck.dart';
import 'package:deckly/widgets/custom_app_bar.dart';

import 'package:deckly/widgets/drop_zone.dart';

import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/hand.dart';
import 'package:deckly/widgets/orientation_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

class CrazyEights extends StatefulWidget {
  final GamePlayer player;
  final List<GamePlayer> players;
  const CrazyEights({super.key, required this.player, required this.players});

  @override
  _CrazyEightsState createState() => _CrazyEightsState();
}

class _CrazyEightsState extends State<CrazyEights> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<CrazyEightsPlayer> players = [];
  List<CrazyEightsBot> bots = [];
  CrazyEightsPlayer? currentPlayer;
  CrazyEightsPlayer? winningPlayer;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  late StreamSubscription<dynamic> _playersSub;
  List<CardData> handCards = [];
  CrazyEightsGameState gameState = CrazyEightsGameState.playing;
  DragData currentDragData = DragData(
    cards: [],
    sourceZoneId: '',
    sourceIndex: -1,
  );
  final HandController handController = HandController();
  final CrazyEightsDeckController deckController = CrazyEightsDeckController();

  List<String> playOrder = [];
  CardSuit? crazyEightSuit; // Track the suit of the Crazy Eight played
  bool playedCrazyEight = false; // Track if a Crazy Eight has been played
  // Default trump suit

  @override
  void initState() {
    super.initState();
    _initializeData();
    initListeners();
  }

  void initListeners() {
    _dataSub = connectionService.gameDataStream.listen((dataMap) {
      print("Type of data: ${dataMap['type']}");
      if (dataMap['type'] == 'update_zone') {
        final zoneId = dataMap['zoneId'] as String;
        final cardsData = dataMap['cards'] as List;
        final cards =
            cardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        final playedBy = dataMap['playedBy'] as String;

        final indexOfPlayer = players.indexWhere((p) => p.id == playedBy);
        final card = cards.first;
        setState(() {
          final targetZone = dropZones.firstWhere((zone) => zone.id == zoneId);
          targetZone.cards.clear();
          targetZone.cards.addAll(cards);
          card.playedBy = playedBy;

          players[indexOfPlayer].hand.removeWhere((c) => c.id == card.id);
        });
      } else if (dataMap['type'] == 'player_played') {
        print("Player played a card");
        SharedPrefs.hapticButtonPress();
        final playerId = dataMap['playerId'] as String;
        final nextPlayerId = dataMap['nextPlayerId'] as String;
        final player = players.firstWhere((p) => p.id == playerId);
        final nextPlayer = players.firstWhere((p) => p.id == nextPlayerId);
        final deckData = dataMap['deckCards'] as List;
        setState(() {
          players[players.indexOf(player)].myTurn = false;

          players[players.indexOf(nextPlayer)].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
          deckCards.clear();
          deckCards.addAll(
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList(),
          );

          print(
            "Deck cards updated: ${deckCards.map((e) => e.displayValue()).toList()}",
          );

          print(
            "Last few cards in deck: ${deckCards.reversed.take(5).map((e) => e.displayValue()).toList()}",
          );
        });

        // if (nextPlayer.isBot && currentPlayer!.getIsHost()) {
        //   Future.delayed(Duration(seconds: 1), () {
        //     List<CardData> playedCards = [];
        //     for (var zone in dropZones) {
        //       if (zone.isPublic) {
        //         playedCards.addAll(zone.cards);
        //       }
        //     }
        //     bots
        //         .firstWhere((b) => b.id == nextPlayer.id)
        //         .playCard(playedCards, leadSuit, players);
        //   });
        // }
      } else if (dataMap['type'] == 'player_played_crazy_eight') {
        SharedPrefs.hapticButtonPress();
        final playerId = dataMap['playerId'] as String;
        final nextPlayerId = dataMap['nextPlayerId'] as String;
        final crazyEightSuitString = dataMap['suit'] as String;
        CardSuit crazyEightSuit = CardSuit.fromString(crazyEightSuitString);
        final player = players.firstWhere((p) => p.id == playerId);
        final nextPlayer = players.firstWhere((p) => p.id == nextPlayerId);
        final deckData = dataMap['deckCards'] as List;
        setState(() {
          this.crazyEightSuit = crazyEightSuit;
          dropZones.first.cards.last.suit = crazyEightSuit;
          players[players.indexOf(player)].myTurn = false;

          players[players.indexOf(nextPlayer)].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);

          player.myTurn = false;
          deckCards.clear();
          deckCards.addAll(
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList(),
          );

          nextPlayer.myTurn = true;
        });

        // if (nextPlayer.isBot && currentPlayer!.getIsHost()) {
        //   Future.delayed(Duration(seconds: 1), () {
        //     List<CardData> playedCards = [];
        //     for (var zone in dropZones) {
        //       if (zone.isPublic) {
        //         playedCards.addAll(zone.cards);
        //       }
        //     }
        //     bots
        //         .firstWhere((b) => b.id == nextPlayer.id)
        //         .playCard(playedCards, leadSuit, players);
        //   });
        // }
      } else if (dataMap['type'] == 'game_over') {
        final winnerId = dataMap['winnerId'] as String;
        final winner = players.firstWhere((p) => p.id == winnerId);
        SharedPrefs.addCrazyEightsGamesPlayed(1);
        setState(() {
          gameState = CrazyEightsGameState.gameOver;
          winningPlayer = winner;
        });
      } else if (dataMap['type'] == 'host_left') {
        // Handle host left scenario
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Timer(Duration(seconds: 2), () {
              connectionService.dispose();
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Close the game screen
            });
            return Dialog(
              backgroundColor: Colors.transparent,

              child: Container(
                width: 400,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [styling.primary, styling.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  margin: EdgeInsets.all(2), // Creates the border thickness
                  decoration: BoxDecoration(
                    color: styling.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "The host has left the game!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      } else if (dataMap['type'] == 'play_again') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    CrazyEights(player: widget.player, players: widget.players),
          ),
        );
      } else if (dataMap['type'] == 'deal_cards') {
        final playersData = dataMap['players'] as List;
        players =
            playersData
                .map(
                  (p) => CrazyEightsPlayer.fromMap(p as Map<String, dynamic>),
                )
                .toList();
        final playOrder = (dataMap['playOrder'] as String).split(',');
        players.sort((a, b) {
          return playOrder.indexOf(a.id).compareTo(playOrder.indexOf(b.id));
        });
        players = [
          ...players.skipWhile((p) => p.id != currentPlayer!.id),
          ...players.takeWhile((p) => p.id != currentPlayer!.id),
        ];
        final deckData = dataMap['deck'] as List;
        final upCardData = dataMap['upCard'] as Map<String, dynamic>;
        CardData upCard = CardData.fromMap(upCardData);
        deckCards.addAll(
          deckData
              .map((c) => CardData.fromMap(c as Map<String, dynamic>))
              .toList(),
        );
        currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);

        handCards = sortHand(currentPlayer!.hand);
        handController.updateHand(handCards);

        dropZones.first.cards.clear();
        dropZones.first.cards.add(upCard);

        setState(() {});
      }
    });

    _stateSub = connectionService.connectionStateStream.listen((state) {});

    _playersSub = connectionService.playersStream.listen((playersData) {});
  }

  List<CardData> sortHand(List<CardData> hand) {
    List<CardData> sortedHand = [];
    //sort hand by suit then by value, alternate colors so it should go hearts, clubs, diamonds, spades
    List<CardData> heartCards = [];
    List<CardData> clubCards = [];
    List<CardData> diamondCards = [];
    List<CardData> spadeCards = [];

    List<CardData> eights = hand.where((c) => c.value == 8).toList();

    for (var card in hand) {
      final cardCopy = CardData(
        id: card.id,
        suit: card.suit,
        value: card.value,
        playedBy: card.playedBy,
      );
      if (card.value == 8) {
        continue; // Skip sorting eights
      }
      if (cardCopy.suit == CardSuit.hearts) {
        heartCards.add(card);
      } else if (cardCopy.suit == CardSuit.clubs) {
        clubCards.add(card);
      } else if (cardCopy.suit == CardSuit.diamonds) {
        diamondCards.add(card);
      } else if (cardCopy.suit == CardSuit.spades) {
        spadeCards.add(card);
      }
    }

    heartCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: null)
          .compareTo(b.toSortingValue(trumpSuit: null)),
    );
    clubCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: null)
          .compareTo(b.toSortingValue(trumpSuit: null)),
    );
    diamondCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: null)
          .compareTo(b.toSortingValue(trumpSuit: null)),
    );
    spadeCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: null)
          .compareTo(b.toSortingValue(trumpSuit: null)),
    );

    List<String> sortPlan = ["hearts", "clubs", "diamonds", "spades"];
    if (heartCards.isEmpty) {
      sortPlan.remove("hearts");
    }
    if (clubCards.isEmpty) {
      sortPlan.remove("clubs");
    }
    if (diamondCards.isEmpty) {
      sortPlan.remove("diamonds");
    }
    if (spadeCards.isEmpty) {
      sortPlan.remove("spades");
    }
    List<String> newSortPlan = [];
    //sort sortPlan so the colors alternate, so it should go (hearts or diamonds), (clubs or spades), (hearts or diamonds), (clubs or spades)
    if (sortPlan.length == 4) {
      newSortPlan = ["hearts", "clubs", "diamonds", "spades"];
    } else if (sortPlan.length == 3) {
      if (sortPlan.contains("hearts")) {
        newSortPlan.add("hearts");
        if (sortPlan.contains("clubs")) {
          newSortPlan.add("clubs");
          if (sortPlan.contains("diamonds")) {
            newSortPlan.add("diamonds");
          } else {
            newSortPlan = ["clubs", "hearts", "spades"];
          }
        } else {
          newSortPlan = ["hearts", "spades", "diamonds"];
        }
      } else {
        newSortPlan = ["clubs", "diamonds", "spades"];
      }
    } else if (sortPlan.length == 2) {
      if (sortPlan.contains("hearts")) {
        newSortPlan.add("hearts");
        if (sortPlan.contains("clubs")) {
          newSortPlan.add("clubs");
        } else {
          if (sortPlan.contains("spades")) {
            newSortPlan.add("spades");
          } else {
            newSortPlan = ["hearts", "diamonds"];
          }
        }
      } else {
        if (sortPlan.contains("clubs")) {
          newSortPlan.add("clubs");
          if (sortPlan.contains("diamonds")) {
            newSortPlan.add("diamonds");
          } else {
            newSortPlan = ["clubs", "spades"];
          }
        } else {
          newSortPlan = ["diamonds", "spades"];
        }
      }
    } else if (sortPlan.length == 1) {
      newSortPlan = sortPlan;
    }

    for (var suit in newSortPlan) {
      if (suit == "hearts") {
        sortedHand.addAll(heartCards);
      } else if (suit == "clubs") {
        sortedHand.addAll(clubCards);
      } else if (suit == "diamonds") {
        sortedHand.addAll(diamondCards);
      } else if (suit == "spades") {
        sortedHand.addAll(spadeCards);
      }
    }
    sortedHand.addAll(eights); // Add eights at the end

    return sortedHand;
  }

  bool customDropZoneValidator(CardData card) {
    if (playedCrazyEight) return true;
    final cardCopy = CardData(
      id: card.id,
      suit: card.suit,
      value: card.value,
      playedBy: card.playedBy,
    );

    final topCard =
        dropZones.first.cards.isNotEmpty ? dropZones.first.cards.last : null;

    if (topCard == null) {
      // If no top card, any card can be played
      return true;
    }

    if (cardCopy.value == 8) {
      // If the card is a Crazy Eight, it can be played on any card
      return true;
    }

    // Check if the card matches the top card's suit or value
    if (cardCopy.suit == topCard.suit ||
        cardCopy.value == topCard.value ||
        cardCopy.value == 8) {
      return true;
    }

    return false;
  }

  void _initializeData() async {
    print("Initializing Crazy Eights data");
    print("Current player: ${widget.player.id}");
    currentPlayer = CrazyEightsPlayer(
      id: widget.player.id,
      name: widget.player.name,

      hand: [],
      isHost: widget.player.isHost,
    );
    for (var p in widget.players) {
      CrazyEightsPlayer player = CrazyEightsPlayer(
        id: p.id,
        name: p.name,

        hand: [],
        isHost: p.isHost,
        isBot: p is BotPlayer,
      );
      if (p is BotPlayer) {
        bots.add(
          CrazyEightsBot(
            id: player.id,
            name: player.name,
            botPlayer: player,
            deckCards: deckCards,
            difficulty: p.difficulty,
            onPlayCard: onPlayCardBot,
            setState: setState,
          ),
        );
      } else {
        player.isBot = false; // Ensure isBot is set correctly
      }

      players.add(player);
    }

    dropZones.add(
      DropZoneData(
        id: "pile",
        canDragCardOut: false,
        isPublic: true,
        stackMode: StackMode.overlay,
        rules: DropZoneRules(
          startingCards: [],
          bannedCards: [],
          allowedCards: AllowedCards.all,
          cardOrder: CardOrder.none,
          allowedSuits: [],
        ),
      ),
    );
    //Start at the next player after the current player and add a drop zone for them, if reaches the end of the list, wrap around, till reached the current player again

    playOrder = generatePlayOrder();

    //sort players based on play order but keep the current player at the start
    players.sort((a, b) {
      return playOrder.indexOf(a.id).compareTo(playOrder.indexOf(b.id));
    });
    players[0].myTurn = true; // Set the first player as current player
    //rotate the players so that the current player is first
    players = [
      ...players.skipWhile((p) => p.id != currentPlayer!.id),
      ...players.takeWhile((p) => p.id != currentPlayer!.id),
    ];
    setState(() {});

    if (widget.player.getIsHost()) {
      List<CardData> shuffledDeck = [...fullDeck];
      print("Shuffled deck: ${shuffledDeck.length}");
      final numberOfCardsToDeal = players.length == 2 ? 7 : 5;
      shuffledDeck.shuffle();

      handCards = shuffledDeck.sublist(0, numberOfCardsToDeal);
      shuffledDeck.removeRange(0, numberOfCardsToDeal);
      currentPlayer!.hand = [...handCards];
      players.forEach((player) {
        if (player.id != currentPlayer!.id) {
          print("CARDS LENGTH: ${shuffledDeck.length}");
          player.hand = shuffledDeck.sublist(0, numberOfCardsToDeal);
          shuffledDeck.removeRange(0, numberOfCardsToDeal);
        } else {
          player.hand = [...handCards];
        }
      });
      // Initialize deck cards
      deckCards.addAll([...shuffledDeck]);
      final topCard = deckCards.isNotEmpty ? deckCards.last : null;
      if (topCard != null) {
        // Flip the top card

        deckCards.removeLast(); // Remove the top card from the deck
        dropZones.first.cards.add(topCard); // Add it to the pile zone
      }
      print("Deck cards: ${deckCards.length}");
      await connectionService.broadcastMessage({
        'type': 'deal_cards',
        'players': players.map((p) => p.toMap()).toList(),
        'deck': deckCards.map((c) => c.toMap()).toList(),
        'upCard': topCard?.toMap(),
        'playOrder': playOrder.join(','),
      }, currentPlayer!.id);
      handCards = sortHand(currentPlayer!.hand);

      setState(() {});
    }

    // Update currentPlayer to reference the actual object in the sorted list
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    // dealCards();

    int indexOfPlayersTurn = players.indexWhere((p) => p.myTurn);
    if (players[indexOfPlayersTurn].isBot) {
      final bot = bots.firstWhere(
        (b) => b.id == players[indexOfPlayersTurn].id,
      );
      Future.delayed(Duration(milliseconds: 500), () {
        bot.playCard(dropZones.first.cards);
      });
    }
    setState(() {});
  }

  void dealCards() async {}

  void _moveCards(DragData dragData, String targetZoneId) async {
    final targetZone = dropZones.firstWhere((zone) => zone.id == targetZoneId);
    final draggedCard = dragData.cards.first;
    currentPlayer!.hand.removeWhere(
      (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
    );
    players[0].hand.removeWhere(
      (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
    );
    handCards.removeWhere((c) => c.id == draggedCard.id);
    setState(() {
      //
      if (targetZone.isPublic) {
        print("Played to goal zone: ${targetZone.id}");
      }
      targetZone.cards.addAll(dragData.cards);
      dragData.cards.forEach((card) {
        card.playedBy = currentPlayer!.id; // Set the player who played the card
      });

      // Set lead suit to the first card played
    });

    if (targetZone.isPublic) {
      print("Played to goal zone: ${targetZone.id}");
      connectionService.broadcastMessage({
        'type': 'update_zone',
        'zoneId': targetZone.id,
        'cards': dragData.cards.map((c) => c.toMap()).toList(),
        'playedBy': currentPlayer!.id,
      }, currentPlayer!.id);
    }

    if (currentPlayer!.hand.isEmpty) {
      // Game over, current player has no cards left
      gameState = CrazyEightsGameState.gameOver;
      winningPlayer = currentPlayer;
      SharedPrefs.addCrazyEightsGamesWon(1);
      SharedPrefs.addCrazyEightsGamesPlayed(1);
      setState(() {});
      connectionService.broadcastMessage({
        'type': 'game_over',
        'winnerId': currentPlayer!.id,
      }, currentPlayer!.id);
      return;
    }
    if (draggedCard.value == 8) {
      // If a Crazy Eight is played, set the crazyEightSuit

      playedCrazyEight = true;

      return;
    }

    CrazyEightsPlayer nextPlayer = players[1];

    setState(() {
      currentPlayer!.myTurn = false;
      players[0].myTurn = false;
    });

    setState(() {
      players[1].myTurn = true;
    });

    connectionService.broadcastMessage({
      'type': 'player_played',
      'playerId': currentPlayer!.id,
      'nextPlayerId': nextPlayer.id,
      'deckCards': deckCards.map((c) => c.toMap()).toList(),
    }, currentPlayer!.id);
    if (nextPlayer.isBot) {
      final bot = bots.firstWhere((b) => b.id == nextPlayer.id);

      Future.delayed(Duration(milliseconds: 1000), () {
        bot.playCard(dropZones.first.cards);
      });
    }
  }

  void onPlayCardBot(CardData card, String botId) {
    SharedPrefs.hapticButtonPress();
    final indexOfBot = players.indexWhere((p) => p.id == botId);
    final targetZone = dropZones.first;
    players[indexOfBot].myTurn = false;

    setState(() {
      //
      if (targetZone.isPublic) {
        print("Played to goal zone: ${targetZone.id}");
      }
      card.playedBy = botId;
      targetZone.cards.add(card);

      // Set lead suit to the first card played
    });

    if (targetZone.isPublic) {
      print("Played to goal zone: ${targetZone.id}");
      connectionService.broadcastMessage({
        'type': 'update_zone',
        'zoneId': targetZone.id,
        'cards': [card.toMap()],
        'playedBy': botId,
      }, currentPlayer!.id);
    }

    // Check if the bot has no cards left
    if (players[indexOfBot].hand.isEmpty) {
      // Game over, bot has no cards left
      winningPlayer = players[indexOfBot];
      gameState = CrazyEightsGameState.gameOver;
      SharedPrefs.addCrazyEightsGamesPlayed(1);
      setState(() {});
      connectionService.broadcastMessage({
        'type': 'game_over',
        'winnerId': botId,
      }, currentPlayer!.id);
      return;
    }

    int nextPlayerIndex = (indexOfBot + 1) % players.length;

    CrazyEightsPlayer nextPlayer = players[nextPlayerIndex];

    setState(() {
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    });

    players[players.indexWhere((p) => p.id == nextPlayer.id)].myTurn = true;
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);

    setState(() {});
    print(
      "BOT HAND: ${players[indexOfBot].hand.map((e) => e.displayValue()).toList()}",
    );
    connectionService.broadcastMessage({
      'type': 'player_played',
      'playerId': botId,
      'nextPlayerId': nextPlayer.id,
      'deckCards': deckCards.map((c) => c.toMap()).toList(),
    }, currentPlayer!.id);
    if (players[players.indexWhere((p) => p.id == nextPlayer.id)].isBot) {
      Future.delayed(Duration(seconds: 1), () {
        final bot = bots.firstWhere((b) => b.id == players[nextPlayerIndex].id);

        bot.playCard(dropZones.first.cards);
      });
    }
  }

  void chooseCrazyEightSuit(CardSuit suit) {
    crazyEightSuit = suit;
    print("Crazy Eight suit chosen: $crazyEightSuit");
    playedCrazyEight = false;
    dropZones.first.cards.last.suit =
        suit; // Update the suit of the Crazy Eight played
    setState(() {});

    CrazyEightsPlayer nextPlayer = players[1];

    setState(() {
      currentPlayer!.myTurn = false;
      players[0].myTurn = false;
    });

    setState(() {
      players[players.indexWhere((p) => p.id == nextPlayer.id)].myTurn = true;
    });

    connectionService.broadcastMessage({
      'type': 'player_played_crazy_eight',
      'playerId': currentPlayer!.id,
      'nextPlayerId': nextPlayer.id,
      'suit': suit.toString(),
      'deckCards': deckCards.map((c) => c.toMap()).toList(),
    }, currentPlayer!.id);

    if (nextPlayer.isBot) {
      final bot = bots.firstWhere((b) => b.id == nextPlayer.id);

      Future.delayed(Duration(milliseconds: 1000), () {
        bot.playCard(dropZones.first.cards);
      });
    }
  }

  List<CardData> _getCardsFromIndex(String zoneId, int index) {
    if (zoneId == 'hand') {
      return <CardData>[];
    }
    final zone = dropZones.firstWhere((zone) => zone.id == zoneId);
    return zone.cards.sublist(index);
  }

  void _onDragStarted(DragData dragData) {
    setState(() {
      currentDragData = dragData;
    });
  }

  void _onDragEnd() {
    setState(() {
      currentDragData = DragData(cards: [], sourceZoneId: '', sourceIndex: -1);
    });
  }

  void onPlayedFromBlitzDeck() {}

  double _calculateHandScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 32.0; // 16px padding on each side
    final availableWidth = screenWidth - padding;

    // Hand width is 5 cards + 4 gaps (8px each)
    int cardsInHand = currentPlayer!.hand.length.clamp(
      5,
      12,
    ); // Limit to 12 cards for scaling
    final handWidth = 100 + (cardsInHand * 50); // 116 is card width + padding

    return availableWidth / handWidth;
  }

  double _calculateDropZoneScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    final padding = 32.0; // 16px padding on each side
    final availableWidth = screenWidth - padding;
    final availableHeight =
        screenHeight -
        appBarHeight -
        MediaQuery.of(context).padding.top -
        padding;

    final ratio =
        785.0 / (150 * 0.8); // 120 is card width + padding, 0.8 is scale factor

    return availableHeight / (ratio * 150); // 116 is card width + padding
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _stateSub.cancel();
    _dataSub.cancel();
    _playersSub.cancel();
  }

  List<String> generatePlayOrder() {
    List<String> order = [];
    List<CrazyEightsPlayer> sortedPlayers = List.from(players);
    sortedPlayers.shuffle();
    for (var player in sortedPlayers) {
      order.add(player.id);
    }

    return order;
  }

  @override
  Widget build(BuildContext context) {
    final calculatedScale = 0.8;
    final handScale = _calculateHandScale(context);
    final dropZoneScale = _calculateDropZoneScale(context);

    // Update scale for all drop zones
    for (var zone in dropZones) {
      zone.scale = dropZoneScale;
    }

    return PopScope(
      canPop: false,
      child: OrientationChecker(
        allowedOrientations: [
          Orientation.portrait,
          if (isTablet(context)) Orientation.landscape,
        ],
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: CustomAppBar(
              title: "Crazy Eights",
              showBackButton: true,
              onBackButtonPressed: (context) {
                connectionService.dispose();
                Navigator.pop(context);
              },
              actions: [
                IconButton(
                  icon: SFIcon(
                    SFIcons.sf_pencil_and_list_clipboard, // 'heart.fill'
                    // fontSize instead of size
                    fontWeight: FontWeight.bold, // fontWeight instead of weight
                    color: styling.primary,
                  ),
                  onPressed: () {
                    SharedPrefs.hapticButtonPress();
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: styling.background,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(23),
                          topRight: Radius.circular(23),
                        ),
                      ),
                      isScrollControlled: true,
                      builder: (BuildContext context) {
                        return StatefulBuilder(
                          builder: (context, setState) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.8,
                              width: double.infinity,
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: crazy8Rules,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
              customBackButton: FancyWidget(
                child: IconButton(
                  splashColor: Colors.transparent,
                  splashRadius: 25,
                  icon: Transform.flip(
                    flipX: true,
                    child: const SFIcon(
                      SFIcons
                          .sf_rectangle_portrait_and_arrow_right, // 'heart.fill'
                      // fontSize instead of size
                      fontWeight:
                          FontWeight.bold, // fontWeight instead of weight
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () async {
                    SharedPrefs.hapticButtonPress();
                    //Confirm with user before leaving
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Dialog(
                          backgroundColor: Colors.transparent,

                          child: Container(
                            width: 400,
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [styling.primary, styling.secondary],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              margin: EdgeInsets.all(
                                2,
                              ), // Creates the border thickness
                              decoration: BoxDecoration(
                                color: styling.background,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Are you sure you want to leave the game?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ActionButton(
                                        height: 40,
                                        width: 100,
                                        onTap: () {
                                          Navigator.of(context).pop();
                                        },
                                        text: Text(
                                          "Cancel",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      ActionButton(
                                        height: 40,
                                        width: 100,
                                        onTap: () async {
                                          connectionService.dispose();

                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                        },
                                        text: Text(
                                          "Leave",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  color: Colors.white,
                ),
              ),
            ),
          ),
          backgroundColor: styling.background,
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            padding: EdgeInsets.only(left: 8.0, right: 8.0),

            child:
                gameState == CrazyEightsGameState.playing
                    ? buildPlayingScreen(calculatedScale, context, handScale)
                    : gameState == CrazyEightsGameState.gameOver
                    ? buildGameOverScreen()
                    : Container(),
          ),
        ),
      ),
    );
  }

  Widget buildPlayingScreen(
    double calculatedScale,
    BuildContext context,
    double handScale,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Container(
            height: 100.0,
            width: double.infinity,

            child: SingleChildScrollView(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var player in players.where(
                    (p) => p.id != currentPlayer!.id,
                  ))
                    FancyBorder(
                      borderWidth: player.myTurn ? 2 : 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              player.name,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4.0),
                            Text(
                              '${player.hand.length} cards left',
                              style: TextStyle(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,

            child: SizedBox(
              width: MediaQuery.of(context).size.width,

              child: Hand(
                handCards: handCards,
                currentDragData: currentDragData,
                onDragCompleted: onPlayedFromBlitzDeck,
                onDragStarted: _onDragStarted,
                onDragEnd: _onDragEnd,
                scale: handScale,
                onTapBlitz: () {},
                controller: handController,
                draggableCards: players[0].myTurn && !playedCrazyEight,
                onTapCard: null,
                isCardPlayable:
                    players[0].myTurn ? customDropZoneValidator : null,
              ),
            ),
          ),
          Positioned(
            top:
                (MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        32) /
                    2 -
                (400 * dropZones[0].scale) / 2,
            left:
                (MediaQuery.of(context).size.width - 32) / 2 -
                (120 * dropZones[0].scale) / 2 -
                (150 * dropZones[0].scale) / 2,
            child: CrazyEightsDeck(
              cards: deckCards,
              deckId: 'deck',
              scale: dropZones[0].scale + 0.1,
              handScale: handScale,
              onReachEndOfDeck: () {
                List<CardData> pileCards = dropZones.first.cards;
                final topCard = pileCards.last;
                pileCards.removeLast(); // Remove the top card from the pile

                deckCards.addAll(pileCards); // Add all cards back to the deck
                dropZones.first.cards.clear();
                deckCards.shuffle();
                dropZones.first.cards.add(
                  topCard,
                ); // Add the top card back to the pile
              },
              interactable: currentPlayer!.myTurn && !playedCrazyEight,
              controller: deckController,
              onCardDrawn: (card) async {
                handCards.add(card);
                currentPlayer!.hand.add(card);
                handCards = sortHand(handCards);
                currentPlayer!.hand = sortHand(currentPlayer!.hand);
                handController.updateHand(currentPlayer!.hand);
                if (!customDropZoneValidator(card)) {
                  print(
                    "Card drawn: ${card.displayValue()} does not match top card, so no cards can be played",
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                  deckController.dealCards();
                }
                setState(() {});
              },
            ),
          ),

          Positioned(
            top:
                (MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        32) /
                    2 -
                (400 * dropZones[0].scale) / 2,
            left:
                (MediaQuery.of(context).size.width - 32) / 2 -
                (120 * dropZones[0].scale) / 2 +
                (150 * dropZones[0].scale) / 2,
            child: DropZoneWidget(
              zone: dropZones[0],
              currentDragData: currentDragData,
              onMoveCards: _moveCards,
              getCardsFromIndex: _getCardsFromIndex,
              onDragStarted: _onDragStarted,
              onDragEnd: _onDragEnd,
              customWillAccept:
                  () => customDropZoneValidator(currentDragData.cards.first),
            ),
          ),

          ...buildBottomBar(calculatedScale, context, handScale),
        ],
      ),
    );
  }

  List<Widget> buildBottomBar(
    double calculatedScale,
    BuildContext context,
    double handScale,
  ) {
    return [
      if (currentPlayer!.myTurn && playedCrazyEight)
        Positioned(
          bottom: 150 * handScale + (40 * handScale),
          left: 32,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionButton(
                width: 50 * calculatedScale,
                height: 50 * calculatedScale,
                useFancyText: false,
                text: Text(
                  "♥",
                  style: TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.left,
                ),
                onTap: () {
                  chooseCrazyEightSuit(CardSuit.hearts);
                },
              ),

              SizedBox(width: 8 * calculatedScale),

              ActionButton(
                width: 50 * calculatedScale,
                height: 50 * calculatedScale,
                useFancyText: false,
                text: Text(
                  "♦",
                  style: TextStyle(fontSize: 14, color: Colors.red),
                  textAlign: TextAlign.left,
                ),
                onTap: () {
                  chooseCrazyEightSuit(CardSuit.diamonds);
                },
              ),

              SizedBox(width: 8 * calculatedScale),

              ActionButton(
                width: 50 * calculatedScale,
                height: 50 * calculatedScale,
                useFancyText: false,
                text: Text(
                  "♣",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.left,
                ),
                onTap: () {
                  chooseCrazyEightSuit(CardSuit.clubs);
                },
              ),

              SizedBox(width: 8 * calculatedScale),

              ActionButton(
                width: 50 * calculatedScale,
                height: 50 * calculatedScale,
                useFancyText: false,
                text: Text(
                  "♠",
                  style: TextStyle(fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.left,
                ),
                onTap: () {
                  chooseCrazyEightSuit(CardSuit.spades);
                },
              ),
            ],
          ),
        ),
    ];
  }

  Widget buildGameOverScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FancyWidget(
          child: Text(
            'Game Over',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          "Winner: ${winningPlayer?.name}",
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        const SizedBox(height: 16.0),
        if (currentPlayer!.getIsHost())
          ActionButton(
            text: Text(
              'Play Again',
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
            onTap: () async {
              await connectionService.broadcastMessage({
                "type": "play_again",
              }, currentPlayer!.id);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => CrazyEights(
                        player: widget.player,
                        players: widget.players,
                      ),
                ),
              );
            },
            width: 200.0,
            height: 50.0,
          ),
      ],
    );
  }
}
