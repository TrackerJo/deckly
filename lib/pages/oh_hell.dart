import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:deckly/api/bots.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/blitz_deck.dart';
import 'package:deckly/widgets/custom_app_bar.dart';

import 'package:deckly/widgets/drop_zone.dart';
import 'package:deckly/widgets/euchre_deck.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/hand.dart';
import 'package:deckly/widgets/orientation_checker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

class OhHell extends StatefulWidget {
  final GamePlayer player;
  final List<GamePlayer> players;
  const OhHell({super.key, required this.player, required this.players});
  // const Euchre({super.key});
  @override
  _OhHellState createState() => _OhHellState();
}

class _OhHellState extends State<OhHell> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<OhHellPlayer> players = [];
  List<EuchreBot> bots = [];
  int round = 10;
  OhHellPlayer? currentPlayer;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  late StreamSubscription<dynamic> _playersSub;
  List<CardData> handCards = [];
  OhHellGameState gameState = OhHellGameState.playing;
  DragData currentDragData = DragData(
    cards: [],
    sourceZoneId: '',
    sourceIndex: -1,
  );
  final HandController handController = HandController();

  List<String> playOrder = [];
  CardSuit? trumpSuit; // Default trump suit
  OhHellGamePhase gamePhase = OhHellGamePhase.bidding;

  CardSuit? leadSuit;

  List<CardData> cardsPlayedInRound = [];

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
          cardsPlayedInRound.add(card);
          players[indexOfPlayer].hand.removeWhere((c) => c.id == card.id);

          if (leadSuit == null && cards.isNotEmpty) {
            final playedCard = cards.first;
            if (playedCard.value == 11 &&
                playedCard.suit.alternateSuit == trumpSuit &&
                leadSuit == null) {
              leadSuit =
                  trumpSuit; // If a Jack of trump suit is played, set lead suit to trump suit
            } else if (leadSuit == null) {
              leadSuit =
                  playedCard
                      .suit; // Otherwise, set lead suit to the suit of the played card
            }
          }
        });
      }
    });

    _stateSub = connectionService.connectionStateStream.listen((state) {});

    _playersSub = connectionService.playersStream.listen((playersData) {});
  }

  List<CardData> sortHand(List<CardData> hand, CardSuit? trumpSuit) {
    print("Sorting hand for player with trump suit: " + trumpSuit.toString());
    List<CardData> sortedHand = [];
    //sort hand by suit then by value, alternate colors so it should go hearts, clubs, diamonds, spades
    List<CardData> heartCards = [];
    List<CardData> clubCards = [];
    List<CardData> diamondCards = [];
    List<CardData> spadeCards = [];

    for (var card in hand) {
      final cardCopy = CardData(
        id: card.id,
        suit: card.suit,
        value: card.value,
        playedBy: card.playedBy,
      );
      if (cardCopy.value == 11 && cardCopy.suit.alternateSuit == trumpSuit) {
        cardCopy.suit = trumpSuit!; // Jack of trump suit
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
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    clubCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    diamondCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
    );
    spadeCards.sort(
      (b, a) => a
          .toSortingValue(trumpSuit: trumpSuit)
          .compareTo(b.toSortingValue(trumpSuit: trumpSuit)),
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
    print("Sort plan: $sortPlan");
    print("New sort plan: $newSortPlan");
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

    return sortedHand;
  }

  bool customDropZoneValidator(CardData card) {
    final cardCopy = CardData(
      id: card.id,
      suit: card.suit,
      value: card.value,
      playedBy: card.playedBy,
    );
    if (leadSuit == null) {
      return true; // No lead suit defined yet
    }

    if (cardCopy.value == 11 && cardCopy.suit.alternateSuit == trumpSuit) {
      cardCopy.suit = trumpSuit!; // Jack of trump suit is always valid
    }
    if (cardCopy.suit == leadSuit) {
      return true; // Card matches the lead suit
    }
    print("Hand cards: ${currentPlayer!.hand.map((c) => c.id).join(', ')}");
    bool handHasLeadSuit = false;
    for (var c in currentPlayer!.hand) {
      final cCopy = CardData(
        id: c.id,
        suit: c.suit,
        value: c.value,
        playedBy: c.playedBy,
      );
      if (cCopy.value == 11 && cCopy.suit.alternateSuit == trumpSuit) {
        cCopy.suit = trumpSuit!; // Jack of trump suit is also valid
      }
      if (cCopy.suit == leadSuit) {
        handHasLeadSuit = true;
        break;
      }
    }
    if (handHasLeadSuit) {
      print(
        "Player must follow lead suit: ${leadSuit.toString()} but played ${cardCopy.id} with suit ${cardCopy.suit}",
      );
      return false; // Player must follow the lead suit if they have it
    }
    print("Accepted card: ${cardCopy.id} with suit ${cardCopy.suit}");

    return true;
  }

  void _initializeData() {
    currentPlayer = OhHellPlayer(
      id: widget.player.id,
      name: widget.player.name,

      hand: [],
      isHost: widget.player.isHost,
    );
    for (var p in widget.players) {
      OhHellPlayer player = OhHellPlayer(
        id: p.id,
        name: p.name,

        hand: [],
        isHost: p.isHost,
        isBot: p is BotPlayer,
      );
      if (p is BotPlayer) {
        // bots.add(
        //   EuchreBot(
        //     name: p.name,
        //     id: p.id,
        //     difficulty: p.difficulty,
        //     botPlayer: player,
        //     onDecideTrump: onDecideTrumpBot,
        //     onDiscard: onDiscardBot,
        //     onPlayCard: onPlayCardBot,
        //     playedCards: cardsPlayedInRound,
        //   ),
        // );
      }
      print("Adding player: ${player.name} with id: ${player.id}");
      players.add(player);
    }
    if (players.length == 6) round = 8;
    if (players.length == 7) round = 7;
    if (players.length == 8) round = 6;
    dropZones.add(
      DropZoneData(
        id: currentPlayer!.id,
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
        cards: [],
      ),
    );
    //Start at the next player after the current player and add a drop zone for them, if reaches the end of the list, wrap around, till reached the current player again

    for (int i = 0; i < players.length; i++) {
      if (players[i].id == currentPlayer!.id) {
        continue; // Skip the current player
      }
      dropZones.add(
        DropZoneData(
          id: players[i].id,
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
          cards: [],
          playable: true,
        ),
      );
    }
    print(
      "Drop zones initialized: ${dropZones.length} with ids: ${dropZones.map((zone) => zone.id).join(', ')}",
    );
    //sort players by who is next in line to play, the current player should be first, then the next player, and so on, so it should go 3,4,1,2
    Map<String, int> originalIndices = {}; // Use String ID instead of object
    for (int i = 0; i < players.length; i++) {
      originalIndices[players[i].id] = i; // Use player.id as key
    }

    int currentPlayerOriginalIndex =
        originalIndices[currentPlayer!.id]!; // Use ID lookup

    players.sort((a, b) {
      int aIndex =
          (originalIndices[a.id]! - currentPlayerOriginalIndex) %
          players.length;
      int bIndex =
          (originalIndices[b.id]! - currentPlayerOriginalIndex) %
          players.length;
      return aIndex.compareTo(bIndex);
    });

    // // Update currentPlayer to reference the actual object in the sorted list
    playOrder = generatePlayOrder();
    print("Play order: $playOrder");
    //sort players based on play order but keep the current player at the start
    players.sort((a, b) {
      return playOrder.indexOf(a.id).compareTo(playOrder.indexOf(b.id));
    });
    //rotate the players so that the current player is first
    players = [
      ...players.skipWhile((p) => p.id != currentPlayer!.id),
      ...players.takeWhile((p) => p.id != currentPlayer!.id),
    ];
    dropZones.sort((a, b) {
      final aIndex = players.indexWhere((p) => p.id == a.id);
      final bIndex = players.indexWhere((p) => p.id == b.id);
      return aIndex.compareTo(bIndex);
    });
    //decide randomly who is the dealer
    final dealerIndex = math.Random().nextInt(players.length);
    players[dealerIndex].isDealer = true;
    final nextPlayerIndex =
        (dealerIndex + 1) % players.length; // Next player after dealer

    players[nextPlayerIndex].myTurn = true;
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    dealCards();

    setState(() {});
  }

  void dealCards() {
    List<CardData> shuffledDeck = [...fullDeck];
    print("Shuffled deck: ${shuffledDeck.length}");
    shuffledDeck.shuffle();

    handCards = shuffledDeck.sublist(0, round);
    shuffledDeck.removeRange(0, round);
    currentPlayer!.hand = [...handCards];
    players.forEach((player) {
      if (player.id != currentPlayer!.id) {
        player.hand = shuffledDeck.sublist(0, round);
        shuffledDeck.removeRange(0, round);
      } else {
        player.hand = [...handCards];
      }
    });
    // Initialize deck cards
    deckCards = [...shuffledDeck];
    print("Deck cards: ${deckCards.length}");
    handCards = sortHand(currentPlayer!.hand, trumpSuit);

    setState(() {});
  }

  void _moveCards(DragData dragData, String targetZoneId) async {
    final targetZone = dropZones.firstWhere((zone) => zone.id == targetZoneId);
    final draggedCard = dragData.cards.first;
    setState(() {
      currentPlayer!.hand.removeWhere(
        (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
      );
      players[0].hand.removeWhere(
        (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
      );
      handCards.removeWhere((c) => c.id == draggedCard.id);
      cardsPlayedInRound.addAll(dragData.cards);

      //
      if (targetZone.isPublic) {
        print("Played to goal zone: ${targetZone.id}");
      }
      targetZone.cards.addAll(dragData.cards);
      dragData.cards.forEach((card) {
        card.playedBy = currentPlayer!.id; // Set the player who played the card
      });
      final playedCard = dragData.cards.first;
      if (playedCard.value == 11 &&
          playedCard.suit.alternateSuit == trumpSuit &&
          leadSuit == null) {
        leadSuit =
            trumpSuit; // If a Jack of trump suit is played, set lead suit to trump suit
      } else if (leadSuit == null) {
        leadSuit =
            playedCard
                .suit; // Otherwise, set lead suit to the suit of the played card
      }
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

    OhHellPlayer nextPlayer = players[1];

    final nextPlayersDropZone = dropZones.firstWhere(
      (zone) => zone.id == nextPlayer.id,
    );
    setState(() {
      currentPlayer!.myTurn = false;
      players[0].myTurn = false;
    });
    if (nextPlayersDropZone.cards.isEmpty) {
      setState(() {
        players[players.indexWhere((p) => p.id == nextPlayer.id)].myTurn = true;
      });

      connectionService.broadcastMessage({
        'type': 'player_played',
        'playerId': currentPlayer!.id,
        'nextPlayerId': nextPlayer.id,
      }, currentPlayer!.id);
      // if (nextPlayer.isBot) {
      //   final bot = bots.firstWhere((b) => b.id == nextPlayer.id);
      //   List<CardData> playedCards = [];
      //   for (var zone in dropZones) {
      //     if (zone.isPublic) {
      //       playedCards.addAll(zone.cards);
      //     }
      //   }
      //   Future.delayed(Duration(milliseconds: 1000), () {
      //     bot.playCard([...playedCards], leadSuit, players);
      //   });
      // }
    } else {
      //Score the played cards
      scorePlayedCards();
    }
  }

  void onPlayCardBot(CardData card, String botId) {
    SharedPrefs.hapticButtonPress();
    final indexOfBot = players.indexWhere((p) => p.id == botId);
    final targetZone = dropZones.firstWhere((zone) => zone.id == botId);
    players[indexOfBot].myTurn = false;

    setState(() {
      //
      if (targetZone.isPublic) {
        print("Played to goal zone: ${targetZone.id}");
      }
      card.playedBy = botId;
      targetZone.cards.add(card);
      cardsPlayedInRound.add(card);
      if (card.value == 11 &&
          card.suit.alternateSuit == trumpSuit &&
          leadSuit == null) {
        leadSuit =
            trumpSuit; // If a Jack of trump suit is played, set lead suit to trump suit
      } else if (leadSuit == null) {
        leadSuit =
            card.suit; // Otherwise, set lead suit to the suit of the played card
      }
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

    int nextPlayerIndex = (indexOfBot + 1) % players.length;

    OhHellPlayer nextPlayer = players[nextPlayerIndex];

    final nextPlayersDropZone = dropZones.firstWhere(
      (zone) => zone.id == nextPlayer.id,
    );
    setState(() {
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    });

    if (nextPlayersDropZone.cards.isEmpty) {
      players[players.indexWhere((p) => p.id == nextPlayer.id)].myTurn = true;
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);

      // if (currentPlayer!.myTurn) {
      //   showDialog(
      //     context: context,

      //     builder: (BuildContext dialogContext) {
      //       Timer(Duration(seconds: 1), () {
      //         try {
      //           if (dialogContext.mounted)
      //             Navigator.of(dialogContext).pop();
      //           else
      //             print("Dialog context is not mounted, cannot pop dialog.");
      //         } catch (e) {
      //           print("Error popping dialog: $e");
      //         }
      //       });
      //       return Dialog(
      //         backgroundColor: Colors.transparent,

      //         child: Container(
      //           width: 400,
      //           height: 200,
      //           decoration: BoxDecoration(
      //             gradient: LinearGradient(
      //               begin: Alignment.topLeft,
      //               end: Alignment.bottomRight,
      //               colors: [styling.primary, styling.secondary],
      //             ),
      //             borderRadius: BorderRadius.circular(12),
      //           ),
      //           child: Container(
      //             margin: EdgeInsets.all(2), // Creates the border thickness
      //             decoration: BoxDecoration(
      //               color: styling.background,
      //               borderRadius: BorderRadius.circular(10),
      //             ),
      //             child: Column(
      //               mainAxisSize: MainAxisSize.min,
      //               mainAxisAlignment: MainAxisAlignment.center,
      //               crossAxisAlignment: CrossAxisAlignment.center,
      //               children: [
      //                 Text(
      //                   "It's your turn now!",
      //                   style: TextStyle(color: Colors.white, fontSize: 18),
      //                 ),
      //               ],
      //             ),
      //           ),
      //         ),
      //       );
      //     },
      //   );
      // }
      setState(() {});
      print(
        "BOT HAND: ${players[indexOfBot].hand.map((e) => e.displayValue()).toList()}",
      );
      connectionService.broadcastMessage({
        'type': 'player_played',
        'playerId': botId,
        'nextPlayerId': nextPlayer.id,
      }, currentPlayer!.id);
      // if (players[players.indexWhere((p) => p.id == nextPlayer.id)].isBot) {
      //   Future.delayed(Duration(seconds: 1), () {
      //     final bot = bots.firstWhere(
      //       (b) => b.id == players[nextPlayerIndex].id,
      //     );
      //     List<CardData> playedCards = [];
      //     for (var zone in dropZones) {
      //       if (zone.isPublic) {
      //         playedCards.addAll(zone.cards);
      //       }
      //     }
      //     bot.playCard([...playedCards], leadSuit, players);
      //   });
      // }
    } else {
      Future.delayed(Duration(seconds: 1), () {
        scorePlayedCards();
      });
      //Score the played cards
    }
  }

  void scorePlayedCards() {
    // Implement scoring logic here
    // For now, just print the played cards
    CardData? highCard;
    List<CardData> playedCards = [];
    for (var zone in dropZones) {
      if (zone.isPublic) {
        playedCards.addAll(zone.cards);
      }
    }
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

    final winningPlayer = players.firstWhere(
      (player) => player.id == highCard!.playedBy,
    );

    players
        .firstWhere((player) => player.id == highCard!.playedBy)
        .tricksTaken++;
    // End the current player's turn
    setState(() {
      // Clear played cards from drop zones
      for (var zone in dropZones) {
        if (zone.isPublic) {
          zone.cards.clear();
        }
      }
      // Reset lead suit to the suit of the highest card played
      leadSuit = null;
      // Set the next player to play
      final previousPlayerIndex = players.indexWhere((player) => player.myTurn);
      if (previousPlayerIndex == -1) {
        print("No previous player found, this should not happen");
      } else {
        players[previousPlayerIndex].myTurn = false;
      }
      final nextPlayerIndex = players.indexOf(winningPlayer);
      if (currentPlayer!.hand.isNotEmpty) {
        players[nextPlayerIndex].myTurn = true;
      }
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
      // Reset the current drag data
    });
    connectionService.broadcastMessage({
      'type': 'trick_ended',
      'winningPlayerId': winningPlayer.id,
    }, currentPlayer!.id);

    showDialog(
      context: context,

      builder: (BuildContext dialogContext) {
        Timer(Duration(seconds: 1), () {
          try {
            if (dialogContext.mounted)
              Navigator.of(dialogContext).pop();
            else
              print("Dialog context is not mounted, cannot pop dialog.");
          } catch (e) {
            print("Error popping dialog: $e");
          }
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
                    "${winningPlayer.name} won the trick",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (currentPlayer!.myTurn)
                    Text(
                      "It's your turn now!",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {});
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

  void scoreRound() {}

  void scoreGame() {}

  void onPlayedFromBlitzDeck() {}

  double _calculateHandScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 32.0; // 16px padding on each side
    final availableWidth = screenWidth - padding;

    // Hand width is 5 cards + 4 gaps (8px each)
    final handWidth = 100 + (round * 50); // 116 is card width + padding

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

    print("Available width: $availableWidth");
    print("Available height: $availableHeight");
    final ratio =
        785.0 / (150 * 0.8); // 120 is card width + padding, 0.8 is scale factor
    print("Ratio: $ratio");
    print("Ideal Scale: ${availableHeight / (ratio * 150)}");
    return availableHeight / (ratio * 150);
  }

  int numberOfPlayersOverflow(double calculatedScale) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 32.0; // 16px padding on each side
    final availableWidth = screenWidth - padding;
    double playersWidth = (82 * calculatedScale) * players.length;
    int overflow = -1;
    while (playersWidth > availableWidth) {
      playersWidth -= (82 * calculatedScale);
      overflow++;
    }
    return overflow;
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
    List<OhHellPlayer> sortedPlayers = List.from(players);
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
    final numberOverflow = numberOfPlayersOverflow(calculatedScale);
    print("Calculated scale: $calculatedScale");
    print("Hand scale: $handScale");
    print("Drop zone scale: $dropZoneScale");
    print("Will be overflow: $numberOverflow");

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
              title: "Oh Hell",
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
                                  children: euchreRules,
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
                gameState == OhHellGameState.playing
                    ? buildPlayingScreen(
                      calculatedScale,
                      context,
                      handScale,
                      numberOverflow,
                    )
                    : gameState == OhHellGameState.gameOver
                    ? buildGameOverScreen()
                    : Container(),
          ),
        ),
      ),
    );
  }

  List<Widget> buildCenter3Players() {
    return [
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[2].scale) / 2 -
            (190 * dropZones[2].scale),
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (60 * dropZones[2].scale) / 2,
        child: Transform.rotate(
          angle: math.pi / 3,
          child: DropZoneWidget(
            zone: dropZones[2],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[1].scale) / 2 -
            (190 * dropZones[1].scale),
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[1].scale) / 2 -
            (90 * dropZones[1].scale),
        child: Transform.rotate(
          angle: -math.pi / 3,
          child: DropZoneWidget(
            zone: dropZones[1],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
          ),
        ),
      ),
      if ((gamePhase == OhHellGamePhase.playing && currentPlayer!.myTurn) ||
          dropZones[0].cards.isNotEmpty)
        Positioned(
          top:
              (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      32) /
                  2 -
              (175 * dropZones[0].scale) / 2,
          left:
              (MediaQuery.of(context).size.width - 32) / 2 -
              (120 * dropZones[0].scale) / 2,
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
    ];
  }

  List<Widget> buildCenter4Players() {
    return [
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (175 * dropZones[2].scale) / 2 -
            (200 * dropZones[2].scale),
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[2].scale) / 2,
        child: DropZoneWidget(
          zone: dropZones[2],
          currentDragData: currentDragData,
          onMoveCards: _moveCards,
          getCardsFromIndex: _getCardsFromIndex,
          onDragStarted: _onDragStarted,
          onDragEnd: _onDragEnd,
        ),
      ),
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[3].scale) / 2 -
            (120 * dropZones[3].scale),
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[3].scale) / 2 +
            (100 * dropZones[3].scale),
        child: Transform.rotate(
          angle: math.pi / 2,
          child: DropZoneWidget(
            zone: dropZones[3],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[1].scale) / 2 -
            (120 * dropZones[1].scale),
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[1].scale) / 2 -
            (100 * dropZones[1].scale),
        child: Transform.rotate(
          angle: math.pi / 2,
          child: DropZoneWidget(
            zone: dropZones[1],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
          ),
        ),
      ),
      if ((gamePhase == OhHellGamePhase.playing && currentPlayer!.myTurn) ||
          dropZones[0].cards.isNotEmpty)
        Positioned(
          top:
              (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      32) /
                  2 -
              (175 * dropZones[0].scale) / 2,
          left:
              (MediaQuery.of(context).size.width - 32) / 2 -
              (120 * dropZones[0].scale) / 2,
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
    ];
  }

  List<Widget> buildCenter5Players() {
    return [
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[4].scale) / 2 -
            (310 * dropZones[4].scale) +
            150 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (310 * dropZones[4].scale) / 2,
        child: Transform.rotate(
          angle: (-math.pi / 180 * 108) * 2,
          child: DropZoneWidget(
            zone: dropZones[2],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[3].scale) / 2 -
            (310 * dropZones[3].scale) +
            150 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (50 * dropZones[3].scale) / 2,
        child: Transform.rotate(
          angle: (math.pi / 180 * 108) * 2,
          child: DropZoneWidget(
            zone: dropZones[3],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[2].scale) / 2 -
            (140 * dropZones[2].scale) +
            150 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (140 * dropZones[2].scale) / 2,
        child: Transform.rotate(
          angle: math.pi / 180 * 108,
          child: DropZoneWidget(
            zone: dropZones[4],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[1].scale) / 2 -
            (140 * dropZones[1].scale) +
            150 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[1].scale) / 2 -
            (140 * dropZones[1].scale),
        child: Transform.rotate(
          angle: -math.pi / 180 * 108,
          child: DropZoneWidget(
            zone: dropZones[1],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
          ),
        ),
      ),
      if ((gamePhase == OhHellGamePhase.playing && currentPlayer!.myTurn) ||
          dropZones[0].cards.isNotEmpty)
        Positioned(
          top:
              (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      32) /
                  2 -
              (175 * dropZones[0].scale) / 2 +
              150 * dropZones[4].scale,
          left:
              (MediaQuery.of(context).size.width - 32) / 2 -
              (120 * dropZones[0].scale) / 2,
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
    ];
  }

  List<Widget> buildCenter6Players() {
    return [
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[4].scale) / 2 -
            (290 * dropZones[4].scale) +
            180 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (420 * dropZones[4].scale) / 2,
        child: Transform.rotate(
          angle: (-math.pi / 180 * 120) * 2,
          child: DropZoneWidget(
            zone: dropZones[2],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (800 * dropZones[0].scale) / 2 +
            150 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[0].scale) / 2,
        child: DropZoneWidget(
          zone: dropZones[3],
          currentDragData: currentDragData,
          onMoveCards: _moveCards,
          getCardsFromIndex: _getCardsFromIndex,
          onDragStarted: _onDragStarted,
          onDragEnd: _onDragEnd,
        ),
      ),
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[3].scale) / 2 -
            (290 * dropZones[3].scale) +
            180 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (160 * dropZones[3].scale) / 2,
        child: Transform.rotate(
          angle: (math.pi / 180 * 120) * 2,
          child: DropZoneWidget(
            zone: dropZones[4],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[2].scale) / 2 -
            (120 * dropZones[2].scale) +
            180 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (140 * dropZones[2].scale) / 2,
        child: Transform.rotate(
          angle: math.pi / 180 * 120,
          child: DropZoneWidget(
            zone: dropZones[5],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[1].scale) / 2 -
            (120 * dropZones[1].scale) +
            180 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[1].scale) / 2 -
            (140 * dropZones[1].scale),
        child: Transform.rotate(
          angle: -math.pi / 180 * 120,
          child: DropZoneWidget(
            zone: dropZones[1],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
          ),
        ),
      ),
      if ((gamePhase == OhHellGamePhase.playing && currentPlayer!.myTurn) ||
          dropZones[0].cards.isNotEmpty)
        Positioned(
          top:
              (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      32) /
                  2 -
              (175 * dropZones[0].scale) / 2 +
              180 * dropZones[4].scale,
          left:
              (MediaQuery.of(context).size.width - 32) / 2 -
              (120 * dropZones[0].scale) / 2,
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
    ];
  }

  List<Widget> buildCenter7Players() {
    return [
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[4].scale) / 2 -
            (260 * dropZones[4].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (480 * dropZones[4].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (-math.pi / 180 * 128.57) * 2,
          child: DropZoneWidget(
            zone: dropZones[2],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (830 * dropZones[0].scale) / 2 +
            170 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (40 * dropZones[0].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (math.pi / 180 * 128.57) * 3,
          child: DropZoneWidget(
            zone: dropZones[4],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (830 * dropZones[0].scale) / 2 +
            170 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (260 * dropZones[0].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (-math.pi / 180 * 128.57) * 3,
          child: DropZoneWidget(
            zone: dropZones[3],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[3].scale) / 2 -
            (260 * dropZones[3].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (240 * dropZones[3].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (math.pi / 180 * 128.57) * 2,
          child: DropZoneWidget(
            zone: dropZones[5],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[2].scale) / 2 -
            (100 * dropZones[2].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (140 * dropZones[2].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: math.pi / 180 * 128.57,
          child: DropZoneWidget(
            zone: dropZones[6],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[1].scale) / 2 -
            (100 * dropZones[1].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[1].scale) / 2 -
            (140 * dropZones[1].scale) +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: -math.pi / 180 * 128.57,
          child: DropZoneWidget(
            zone: dropZones[1],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
          ),
        ),
      ),
      if ((gamePhase == OhHellGamePhase.playing && currentPlayer!.myTurn) ||
          dropZones[0].cards.isNotEmpty)
        Positioned(
          top:
              (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      32) /
                  2 -
              (175 * dropZones[0].scale) / 2 +
              200 * dropZones[4].scale,
          left:
              (MediaQuery.of(context).size.width - 32) / 2 -
              (120 * dropZones[0].scale) / 2 +
              (15 * dropZones[3].scale),
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
    ];
  }

  List<Widget> buildCenter8Players() {
    return [
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (120 * dropZones[4].scale) / 2 -
            (240 * dropZones[4].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (480 * dropZones[4].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (-math.pi / 180 * 135) * 2,
          child: DropZoneWidget(
            zone: dropZones[2],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (175 * dropZones[0].scale) / 2 -
            (830 * dropZones[0].scale) / 2 +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[0].scale) / 2 +
            (15 * dropZones[3].scale),
        child: DropZoneWidget(
          zone: dropZones[4],
          currentDragData: currentDragData,
          onMoveCards: _moveCards,
          getCardsFromIndex: _getCardsFromIndex,
          onDragStarted: _onDragStarted,
          onDragEnd: _onDragEnd,
          customWillAccept:
              () => customDropZoneValidator(currentDragData.cards.first),
        ),
      ),
      Positioned(
        top:
            (MediaQuery.of(context).size.height -
                    kToolbarHeight -
                    MediaQuery.of(context).padding.top -
                    32) /
                2 -
            (830 * dropZones[0].scale) / 2 +
            170 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (150 * dropZones[0].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (math.pi / 180 * 135) * 3,
          child: DropZoneWidget(
            zone: dropZones[5],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (830 * dropZones[0].scale) / 2 +
            170 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (400 * dropZones[0].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (-math.pi / 180 * 135) * 3,
          child: DropZoneWidget(
            zone: dropZones[3],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[3].scale) / 2 -
            (240 * dropZones[3].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (240 * dropZones[3].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: (math.pi / 180 * 135) * 2,
          child: DropZoneWidget(
            zone: dropZones[6],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[2].scale) / 2 -
            (90 * dropZones[2].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 +
            (140 * dropZones[2].scale) / 2 +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: math.pi / 180 * 135,
          child: DropZoneWidget(
            zone: dropZones[7],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
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
            (120 * dropZones[1].scale) / 2 -
            (90 * dropZones[1].scale) +
            200 * dropZones[4].scale,
        left:
            (MediaQuery.of(context).size.width - 32) / 2 -
            (120 * dropZones[1].scale) / 2 -
            (140 * dropZones[1].scale) +
            (15 * dropZones[3].scale),
        child: Transform.rotate(
          angle: -math.pi / 180 * 135,
          child: DropZoneWidget(
            zone: dropZones[1],
            currentDragData: currentDragData,
            onMoveCards: _moveCards,
            getCardsFromIndex: _getCardsFromIndex,
            onDragStarted: _onDragStarted,
            onDragEnd: _onDragEnd,
          ),
        ),
      ),
      if ((gamePhase == OhHellGamePhase.playing && currentPlayer!.myTurn) ||
          dropZones[0].cards.isNotEmpty)
        // Center Drop Zone for 8 players
        Positioned(
          top:
              (MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      32) /
                  2 -
              (175 * dropZones[0].scale) / 2 +
              200 * dropZones[4].scale,
          left:
              (MediaQuery.of(context).size.width - 32) / 2 -
              (120 * dropZones[0].scale) / 2 +
              (15 * dropZones[3].scale),
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
    ];
  }

  Widget buildPlayingScreen(
    double calculatedScale,
    BuildContext context,
    double handScale,
    int numberOverflow,
  ) {
    List<OhHellPlayer> otherPlayers =
        players.where((p) => p.id != currentPlayer!.id).toList();
    List<OhHellPlayer> overflowPlayers = [];
    for (var i = 0; i < numberOverflow; i++) {
      overflowPlayers.add(otherPlayers.removeLast());
    }
    overflowPlayers = overflowPlayers.reversed.toList();
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          if (players.length == 3) ...buildCenter3Players(),
          if (players.length == 4) ...buildCenter4Players(),
          if (players.length == 5) ...buildCenter5Players(),
          if (players.length == 6) ...buildCenter6Players(),
          if (players.length == 7) ...buildCenter7Players(),
          if (players.length == 8) ...buildCenter8Players(),
          Positioned(
            top: 0 * calculatedScale,
            left: 0 * calculatedScale,
            child: Container(
              height: 70.0,

              width: MediaQuery.of(context).size.width + 20,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4.0,
                  children: [
                    for (var player in otherPlayers)
                      FancyBorder(
                        borderWidth:
                            player.myTurn
                                ? 1.0
                                : player.isDealer &&
                                    gamePhase == OhHellGamePhase.bidding
                                ? 1.0
                                : 0.0,
                        borderColor:
                            player.myTurn
                                ? styling.primary
                                : player.isDealer &&
                                    gamePhase == OhHellGamePhase.bidding
                                ? styling.secondary
                                : Colors.transparent,
                        child: SizedBox(
                          width: 80 * calculatedScale,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16 * calculatedScale,
                                  ),
                                ),

                                Text(
                                  "Bid: ${player.bid}\nTricks: ${player.tricksTaken}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * calculatedScale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 90 * calculatedScale,
            left: 0 * calculatedScale,
            child: Container(
              height: 70.0,
              width: MediaQuery.of(context).size.width,

              child: SingleChildScrollView(
                child: Wrap(
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    for (var player in overflowPlayers)
                      FancyBorder(
                        borderWidth:
                            player.myTurn
                                ? 1.0
                                : player.isDealer &&
                                    gamePhase == OhHellGamePhase.bidding
                                ? 1.0
                                : 0.0,
                        borderColor:
                            player.myTurn
                                ? styling.primary
                                : player.isDealer &&
                                    gamePhase == OhHellGamePhase.bidding
                                ? styling.secondary
                                : Colors.transparent,
                        child: SizedBox(
                          width: 82 * calculatedScale,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  player.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16 * calculatedScale,
                                  ),
                                ),

                                Text(
                                  "Bid: ${player.bid}\nTricks: ${player.tricksTaken}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * calculatedScale,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Top Container (100px)
          Positioned(
            bottom: 0,

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
                draggableCards:
                    players[0].myTurn && gamePhase == OhHellGamePhase.playing,
                onTapCard: null,
                isCardPlayable:
                    players[0].myTurn && gamePhase == OhHellGamePhase.playing
                        ? customDropZoneValidator
                        : null,
              ),
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
    CardSuit upCardSuit = deckCards.last.suit;
    return [
      if (gamePhase == OhHellGamePhase.bidding && currentPlayer!.isDealer)
        Positioned(
          bottom: 150 * handScale + (40 * handScale) + 0.4 * 150,
          left: MediaQuery.of(context).size.width - 100 - (60 / 2),
          child: Text(
            "You are the dealer",
            style: TextStyle(fontSize: 12.0, color: Colors.white),
          ),
        ),
      Positioned(
        bottom: 150 * handScale + (24 * handScale),
        left: MediaQuery.of(context).size.width - 100,
        child: EuchreDeck(euchreDeck: deckCards, scale: 0.4, showTopCard: true),
      ),
      if (gamePhase == OhHellGamePhase.bidding && currentPlayer!.myTurn)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          left: 32,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionButton(
                width: 40,
                height: 40,
                text: Column(
                  children: [
                    Text(
                      "-",
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                  ],
                ),
                onTap: () {
                  if (currentPlayer!.bid > 0) {
                    currentPlayer!.bid--;
                    connectionService.broadcastMessage({
                      "type": "bid",
                      "bid": currentPlayer!.bid,
                    }, currentPlayer!.id);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(width: 8.0),
              FancyWidget(
                child: SizedBox(
                  width: 28,
                  child: Text(
                    "${currentPlayer!.bid}",
                    style: TextStyle(fontSize: 24.0, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              ActionButton(
                width: 40,
                height: 40,
                text: Column(
                  children: [
                    Text(
                      "+",
                      style: TextStyle(fontSize: 24.0, color: Colors.white),
                    ),
                  ],
                ),
                onTap: () {
                  if (currentPlayer!.bid < round) {
                    currentPlayer!.bid++;
                    connectionService.broadcastMessage({
                      "type": "bid",
                      "bid": currentPlayer!.bid,
                    }, currentPlayer!.id);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(width: 8.0),
              ActionButton(
                width: 80,
                height: 40,
                text: Text(
                  "Bid",
                  style: TextStyle(fontSize: 16.0, color: Colors.white),
                ),
                onTap: () async {},
              ),
            ],
          ),
        ),
    ];
  }

  Widget buildGameOverScreen() {
    // Sort players by score
    players.sort((a, b) => b.score.compareTo(a.score));
    final winner = players.first;

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
          "Winner: ${winner.name}",
          style: TextStyle(fontSize: 20.0, color: Colors.white),
        ),
        const SizedBox(height: 16.0),
        FancyBorder(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    "Final Scores",
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                ...players
                    .map(
                      (player) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          "${player.name}: ${player.score} points",
                          style: TextStyle(fontSize: 18.0, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        if (currentPlayer!.getIsHost())
          ActionButton(
            text: Text(
              'Play Again',
              style: TextStyle(fontSize: 18.0, color: Colors.white),
            ),
            onTap: () async {
              SharedPrefs.hapticButtonPress();
              await connectionService.broadcastMessage({
                "type": "play_again",
              }, currentPlayer!.id);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => OhHell(
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
