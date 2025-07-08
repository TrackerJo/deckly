import 'dart:async';

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

class Kalamattack extends StatefulWidget {
  final GamePlayer player;
  final List<GamePlayer> players;
  const Kalamattack({super.key, required this.player, required this.players});

  @override
  _KalamattackState createState() => _KalamattackState();
}

class _KalamattackState extends State<Kalamattack> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<KalamattackPlayer> players = [];
  List<CrazyEightsBot> bots = [];
  List<CardData> discard = [];
  KalamattackPlayer? currentPlayer;
  KalamattackPlayer? winningPlayer;
  KalamattackPlayer? playerAttacking;
  KalamattackPlayer? playerThatIsAttacking;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  late StreamSubscription<dynamic> _playersSub;
  List<CardData> handCards = [];
  KalamattackGameState gameState = KalamattackGameState.playing;
  KalamattackGamePhase gamePhase = KalamattackGamePhase.selectingMove;
  DragData currentDragData = DragData(
    cards: [],
    sourceZoneId: '',
    sourceIndex: -1,
  );
  final HandController handController = HandController();
  final CrazyEightsDeckController deckController = CrazyEightsDeckController();

  List<String> playOrder = [];
  int attackDamage = 0; // Damage dealt by the attacking player
  bool waitingForDefense =
      false; // Whether the game is waiting for a defense action
  bool waitingForAttack =
      false; // Whether the game is waiting for an attack action
  int damageAsDefense = 0; // Damage dealt by the defending player

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
      } else if (dataMap['type'] == 'game_over') {
        final winnerId = dataMap['winnerId'] as String;
        final winner = players.firstWhere((p) => p.id == winnerId);
        SharedPrefs.addCrazyEightsGamesPlayed(1);
        setState(() {
          gameState = KalamattackGameState.gameOver;
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
                    Kalamattack(player: widget.player, players: widget.players),
          ),
        );
      } else if (dataMap['type'] == 'deal_cards') {
        final playersData = dataMap['players'] as List;
        final deckData = dataMap['deck'] as List;
        final pile1CardData = dataMap['pile1Card'] as Map<String, dynamic>;
        final pile2CardData = dataMap['pile2Card'] as Map<String, dynamic>;
        final pile3CardData = dataMap['pile3Card'] as Map<String, dynamic>;
        final playOrderString = dataMap['playOrder'] as String;

        // Update players
        players =
            playersData
                .map(
                  (p) => KalamattackPlayer.fromMap(p as Map<String, dynamic>),
                )
                .toList();

        // Update deck cards
        deckCards.addAll(
          deckData
              .map((c) => CardData.fromMap(c as Map<String, dynamic>))
              .toList(),
        );

        // Update drop zones
        dropZones
            .firstWhere((zone) => zone.id == "pile1")
            .cards
            .add(CardData.fromMap(pile1CardData));
        dropZones
            .firstWhere((zone) => zone.id == "pile2")
            .cards
            .add(CardData.fromMap(pile2CardData));
        dropZones
            .firstWhere((zone) => zone.id == "pile3")
            .cards
            .add(CardData.fromMap(pile3CardData));

        // Update play order
        playOrder = playOrderString.split(',');
        // Sort players based on play order
        players.sort((a, b) {
          return playOrder.indexOf(a.id).compareTo(playOrder.indexOf(b.id));
        });

        players = [
          ...players.skipWhile((p) => p.id != currentPlayer!.id),
          ...players.takeWhile((p) => p.id != currentPlayer!.id),
        ];

        // Find the current player and update their hand
        currentPlayer = players.firstWhere((p) => p.id == widget.player.id);

        currentPlayer!.hand =
            players.firstWhere((p) => p.id == widget.player.id).hand;
        handCards = sortHand(currentPlayer!.hand);
        setState(() {});
      } else if (dataMap['type'] == 'card_discarded') {
        final playerId = dataMap['playerId'] as String;
        final nextPlayerId = dataMap['nextPlayerId'] as String;
        final cardData = dataMap['card'] as Map<String, dynamic>;
        final discardCardsData = dataMap['discardCards'] as List<dynamic>;
        // Convert discard cards to CardData objects
        final discardCards =
            discardCardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        // Add the discard cards to the discard pile
        discard.clear();
        discard.addAll(discardCards);
        final card = CardData.fromMap(cardData);
        final indexOfPlayer = players.indexWhere((p) => p.id == playerId);
        final indexOfNextPlayer = players.indexWhere(
          (p) => p.id == nextPlayerId,
        );
        setState(() {
          // Remove the card from the player's hand
          players[indexOfPlayer].hand.removeWhere((c) => c.id == card.id);

          // Add the card to the discard pile
          discard.add(card);
          // Update the current player and their turn
          players[indexOfPlayer].myTurn = false;

          players[indexOfNextPlayer].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == widget.player.id);
        });
      } else if (dataMap['type'] == "card_picked_from_pile") {
        final playerId = dataMap['playerId'] as String;
        final deckData = dataMap['deck'] as List;
        final cardPickedData = dataMap['cardPicked'] as Map<String, dynamic>;
        final newCardData = dataMap['newCard'] as Map<String, dynamic>;
        final pileIndex = dataMap['pileIndex'] as int;
        final cardPicked = CardData.fromMap(cardPickedData);
        final newCard = CardData.fromMap(newCardData);
        final indexOfPlayer = players.indexWhere((p) => p.id == playerId);
        setState(() {
          // Add the picked card to the player's hand
          players[indexOfPlayer].hand.add(cardPicked);

          // Update the deck cards
          deckCards.clear();
          deckCards.addAll(
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList(),
          );
          dropZones[pileIndex].cards.clear();
          // Update the drop zone with the new card
          dropZones[pileIndex].cards.add(newCard);
        });
      } else if (dataMap['type'] == "card_picked_from_pile_end_turn") {
        final playerId = dataMap['playerId'] as String;
        final nextPlayerId = dataMap['nextPlayerId'] as String;
        final deckData = dataMap['deck'] as List;
        final cardPickedData = dataMap['cardPicked'] as Map<String, dynamic>;
        final newCardData = dataMap['newCard'] as Map<String, dynamic>;
        final pileIndex = dataMap['pileIndex'] as int;
        final discardCardsData =
            dataMap['discardCards'] != null
                ? dataMap['discardCards'] as List
                : [];
        // Convert discard cards to CardData objects
        final discardCards =
            discardCardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        // Add the discard cards to the discard pile
        discard.clear();
        discard.addAll(discardCards);
        final cardPicked = CardData.fromMap(cardPickedData);
        final newCard = CardData.fromMap(newCardData);
        final indexOfPlayer = players.indexWhere((p) => p.id == playerId);
        final indexOfNextPlayer = players.indexWhere(
          (p) => p.id == nextPlayerId,
        );
        setState(() {
          // Add the picked card to the player's hand
          players[indexOfPlayer].hand.add(cardPicked);

          // Update the deck cards
          deckCards.clear();
          deckCards.addAll(
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList(),
          );
          dropZones[pileIndex].cards.clear();
          // Update the drop zone with the new card
          dropZones[pileIndex].cards.add(newCard);
          // Update the current player and their turn
          players[indexOfPlayer].myTurn = false;
          players[indexOfNextPlayer].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == widget.player.id);
        });
      } else if (dataMap['type'] == "deck_empty") {
        final deckData = dataMap['deck'] as List;
        // Update the deck cards
        discard.clear();
        deckCards.clear();
        deckCards.addAll(
          deckData
              .map((c) => CardData.fromMap(c as Map<String, dynamic>))
              .toList(),
        );
        setState(() {});
      } else if (dataMap['type'] == "drew_card") {
        final playerId = dataMap['playerId'] as String;
        final deckData = dataMap['deck'] as List;
        final cardPickedData = dataMap['cardPicked'] as Map<String, dynamic>;

        final cardPicked = CardData.fromMap(cardPickedData);

        final indexOfPlayer = players.indexWhere((p) => p.id == playerId);
        setState(() {
          // Add the picked card to the player's hand
          players[indexOfPlayer].hand.add(cardPicked);

          // Update the deck cards
          deckCards.clear();
          deckCards.addAll(
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList(),
          );

          // Update the drop zone with the new card
        });
      } else if (dataMap['type'] == "drew_card_end_turn") {
        final playerId = dataMap['playerId'] as String;
        final nextPlayerId = dataMap['nextPlayerId'] as String;
        final deckData = dataMap['deck'] as List;
        final cardPickedData = dataMap['cardPicked'] as Map<String, dynamic>;

        final cardPicked = CardData.fromMap(cardPickedData);

        final indexOfPlayer = players.indexWhere((p) => p.id == playerId);
        final indexOfNextPlayer = players.indexWhere(
          (p) => p.id == nextPlayerId,
        );
        setState(() {
          // Add the picked card to the player's hand
          players[indexOfPlayer].hand.add(cardPicked);

          // Update the deck cards
          deckCards.clear();
          deckCards.addAll(
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList(),
          );

          // Update the current player and their turn
          players[indexOfPlayer].myTurn = false;
          players[indexOfNextPlayer].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == widget.player.id);
        });
      } else if (dataMap['type'] == "update_attack_cards") {
        print(dataMap);

        final cardsData =
            dataMap['cards'] != null ? dataMap['cards'] as List : [];
        final cards =
            cardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        final targetZone = dropZones.firstWhere((zone) => zone.id == "attack");
        setState(() {
          targetZone.cards.clear();
          // Add the attack cards to the attack zone
          targetZone.cards.addAll(cards);
        });
      } else if (dataMap['type'] == "select_player_to_attack") {
        final playerAttackingId = dataMap['attackingPlayerId'] as String;

        final playerId = dataMap['playerId'] as String;
        final player = players.firstWhere((p) => p.id == playerId);
        setState(() {
          playerThatIsAttacking = player;
          playerAttacking = currentPlayer!;
          if (playerAttackingId == currentPlayer!.id) {
            // If the player attacking is not the current player, ignore this message
            gamePhase = KalamattackGamePhase.defending;
            waitingForAttack = true;
            waitingForDefense = false;
          } else {
            gamePhase = KalamattackGamePhase.othersAttacking;
          }
        });
        if (playerAttackingId == currentPlayer!.id) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              Timer(Duration(seconds: 2), () {
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
                          "${player.name} is attacking you!",
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
        }
      } else if (dataMap['type'] == "attack_player") {
        final playerAttackingId = dataMap['attackingPlayerId'] as String;
        if (playerAttackingId != currentPlayer!.id) {
          // If the player attacking is not the current player, ignore this message
          return;
        }

        final attackDamage = dataMap['attackDamage'] as int;

        setState(() {
          waitingForAttack = false;
          this.attackDamage = attackDamage;
        });
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            Timer(Duration(seconds: 2), () {
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
                        "${playerThatIsAttacking!.name} has attacked you with $attackDamage damage!\nNow you must defend yourself!",
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
      } else if (dataMap['type'] == "update_defense_cards") {
        final playerThatIsAttackingId =
            dataMap['playerThatIsAttackingId'] as String;
        print("Player that is attacking: $playerThatIsAttackingId");

        final cardsData =
            dataMap['cards'] != null ? dataMap['cards'] as List : [];
        final cards =
            cardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        final targetZone = dropZones.firstWhere((zone) => zone.id == "defense");
        setState(() {
          targetZone.cards.clear();
          // Add the attack cards to the attack zone
          targetZone.cards.addAll(cards);
        });
      } else if (dataMap['type'] == "defend_player") {
        final playerDefendingId = dataMap['defendingPlayerId'] as String;
        final playerDefending = players.firstWhere(
          (p) => p.id == playerDefendingId,
        );
        final playerAttackingId = dataMap['attackingPlayerId'] as String;
        final playerAttacking = players.firstWhere(
          (p) => p.id == playerAttackingId,
        );
        final damageAsDefense = dataMap['damageAsDefense'] as int;
        final totalDamage = dataMap['totalDamage'] as int;
        final discardCardsData = dataMap['discard'] as List;
        final playersListData = dataMap['players'] as List;
        final playersList =
            playersListData
                .map(
                  (p) => KalamattackPlayer.fromMap(p as Map<String, dynamic>),
                )
                .toList();
        for (var player in playersList) {
          final index = players.indexWhere((p) => p.id == player.id);
          if (index != -1) {
            players[index] = player;
          }
        }
        currentPlayer = players.firstWhere((p) => p.id == widget.player.id);
        final discardCards =
            discardCardsData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        discard.clear();
        discard.addAll(discardCards);
        gamePhase = KalamattackGamePhase.selectingMove;
        this.playerAttacking = null;
        waitingForDefense = false;
        playerThatIsAttacking = null;
        waitingForAttack = false;
        attackDamage = 0;
        this.damageAsDefense = 0;

        dropZones[3].cards.clear();
        dropZones[4].cards.clear();
        setState(() {});
        if (playerAttacking.id == currentPlayer!.id) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              Timer(Duration(seconds: 2), () {
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
                          "You did $totalDamage damage to ${playerDefending.name}!${damageAsDefense > 0 ? "\n${playerDefending.name} reflected $damageAsDefense damage to you!" : ""}",
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
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              Timer(Duration(seconds: 2), () {
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
                          "${playerAttacking.name} did $totalDamage damage to ${playerDefending.name}!${damageAsDefense > 0 ? "\n${playerDefending.name} reflected $damageAsDefense damage to ${playerAttacking.name}!" : ""}",
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
        }
      } else if (dataMap['type'] == "back_from_attack") {
        final playerId = dataMap['playerId'] as String;
        final indexOfPlayer = players.indexWhere((p) => p.id == playerId);
        final player = players[indexOfPlayer];
        gamePhase = KalamattackGamePhase.selectingMove;
        if (playerAttacking != null &&
            playerAttacking!.id == currentPlayer!.id) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              Timer(Duration(seconds: 2), () {
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
                          "${player.name} is no longer attacking you!",
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
        }
        playerAttacking = null;
        playerThatIsAttacking = null;

        setState(() {
          waitingForAttack = false;
          waitingForDefense = false;
          attackDamage = 0;
          dropZones[3].cards.clear();
        });
      }
    });

    _stateSub = connectionService.connectionStateStream.listen((state) {});

    _playersSub = connectionService.playersStream.listen((playersData) {});
  }

  List<CardData> sortHand(List<CardData> hand) {
    List<CardData> sortedHand = [...hand];
    //sort hand by value
    sortedHand.sort((a, b) {
      return b.toSortingValue().compareTo(a.toSortingValue());
    });
    return sortedHand;
  }

  bool canSubmitAttack() {
    final attackZone = dropZones.firstWhere((zone) => zone.id == "attack");
    if (attackZone.cards.isEmpty) {
      // If the attack zone is empty, any card can be played
      return false;
    }
    if (attackZone.cards.length == 1) {
      return true;
    }
    if (attackZone.cards.length == 2) {
      // If there are two cards in the attack zone, check if they are a pair
      final firstCard = attackZone.cards.first;
      final secondCard = attackZone.cards.last;
      return firstCard.value == secondCard.value;
    }
    if (attackZone.cards.length == 3) {
      // If there are three cards in the attack zone, check if they are a three of a kind
      final firstCard = attackZone.cards.first;
      final secondCard = attackZone.cards[1];
      final thirdCard = attackZone.cards.last;
      if (firstCard.value == secondCard.value &&
          secondCard.value == thirdCard.value) {
        return true;
      } else {
        // If they are not a three of a kind, check if they are a run
        attackZone.cards.sort(
          (a, b) => b.toSortingValue().compareTo(a.toSortingValue()),
        );
        final firstCardValue = attackZone.cards.first.value;
        final lastCardValue = attackZone.cards.last.value;
        if (firstCardValue == lastCardValue + 2 ||
            firstCardValue == lastCardValue - 2) {
          // If the first card is two values higher or lower than the last card, it is a run
          return true;
        } else {
          // If they are not a run, return false
          return false;
        }
      }
    }
    if (attackZone.cards.length == 4) {
      return true; // If there are four cards, they can always be played
    }
    return false;
  }

  bool canSubmitDefense() {
    final defenseZone = dropZones.firstWhere((zone) => zone.id == "defense");
    if (defenseZone.cards.isEmpty) {
      // If the attack zone is empty, any card can be played
      return false;
    }
    if (defenseZone.cards.length == 1) {
      return true;
    }
    if (defenseZone.cards.length == 2) {
      // If there are two cards in the attack zone, check if they are a pair
      final firstCard = defenseZone.cards.first;
      final secondCard = defenseZone.cards.last;
      return firstCard.value == secondCard.value;
    }
    if (defenseZone.cards.length == 3) {
      // If there are three cards in the attack zone, check if they are a three of a kind
      final firstCard = defenseZone.cards.first;
      final secondCard = defenseZone.cards[1];
      final thirdCard = defenseZone.cards.last;
      if (firstCard.value == secondCard.value &&
          secondCard.value == thirdCard.value) {
        return true;
      } else {
        // If they are not a three of a kind, check if they are a run
        defenseZone.cards.sort(
          (a, b) => b.toSortingValue().compareTo(a.toSortingValue()),
        );
        final firstCardValue = defenseZone.cards.first.value;
        final lastCardValue = defenseZone.cards.last.value;
        if (firstCardValue == lastCardValue + 2 ||
            firstCardValue == lastCardValue - 2) {
          // If the first card is two values higher or lower than the last card, it is a run
          return true;
        } else {
          // If they are not a run, return false
          return false;
        }
      }
    }
    if (defenseZone.cards.length == 4) {
      return true; // If there are four cards, they can always be played
    }
    return false;
  }

  int calculateDamage(List<CardData> cards) {
    int damage = 0;
    if (cards.isEmpty) return damage;

    // Calculate damage based on the type of cards played
    if (cards.length == 1) {
      // Single card damage
      damage = cards.first.value;
    } else if (cards.length == 2 && cards[0].value == cards[1].value) {
      // Pair damage
      damage = cards[0].value * 2 + 2;
    } else if (cards.length == 3 &&
        cards[0].value == cards[1].value &&
        cards[1].value == cards[2].value) {
      // Three of a kind damage
      damage = cards[0].value * 3 + 3;
    } else if (cards.length >= 2) {
      // Run damage
      int sum = cards.fold(0, (prev, card) => prev + card.value);
      damage = sum;
    }
    return damage;
  }

  int calculateDefense(List<CardData> cards) {
    int damage = 0;
    damageAsDefense = 0;
    setState(() {});
    if (cards.isEmpty) return damage;

    // Calculate damage based on the type of cards played
    if (cards.length == 1) {
      if (cards.first.value == 1) {
        // If the card is an Ace, it cannot be used for defense
        return (attackDamage / 2).round();
      }
      if (cards.first.value == 0) {
        // If the card is a special card, it cannot be used for defense
        damageAsDefense = attackDamage - (attackDamage / 2).round();
        setState(() {});
        return (attackDamage / 2).round();
      }
      damageAsDefense = 0;
      setState(() {});
      // Single card damage
      damage = cards.first.value;
    } else if (cards.length == 2 && cards[0].value == cards[1].value) {
      if (cards[0].value == 1) {
        // If the pair is Aces, it cannot be used for defense
        damageAsDefense = 0;
        setState(() {});
        return attackDamage;
      }
      if (cards[0].value == 0) {
        // If the pair is special cards, it cannot be used for defense
        damageAsDefense = attackDamage;
        setState(() {});
        return attackDamage;
      }
      // Pair damage
      damage = cards[0].value * 2 + 2;
    } else if (cards.length == 3 &&
        cards[0].value == cards[1].value &&
        cards[1].value == cards[2].value) {
      // Three of a kind damage
      damage = cards[0].value * 3 + 3;
    } else if (cards.length >= 2) {
      // Run damage
      int sum = cards.fold(0, (prev, card) => prev + card.value);
      damage = sum;
    }
    damageAsDefense = 0;
    setState(() {});
    return damage;
  }

  bool customDropZoneValidator(CardData card) {
    if (gamePhase == KalamattackGamePhase.attacking &&
        playerAttacking != null) {
      final attackTargetZone = dropZones.firstWhere(
        (zone) => zone.id == "attack",
      );
      if (card.value > 10 || card.value <= 1) {
        // If the card is a special card, it can be played
        return false;
      }
      if (attackTargetZone.cards.isEmpty) {
        // If the attack zone is empty, any card can be played

        return true;
      }

      if (attackTargetZone.cards.length >= 4) {
        // If there are multiple cards in the attack zone, only the top card is considered
        return false;
      }

      // Check if the card can be played based on the card in the attack zone
      if (attackTargetZone.cards.length == 1) {
        final topCard = attackTargetZone.cards.last;
        if (card.value == topCard.value ||
            card.value == topCard.value - 1 ||
            card.value == topCard.value + 1) {
          // If the card has the same suit or value as the top card, it can be played
          return true;
        } else {
          // If the card does not match the suit or value, it cannot be played
          return false;
        }
      }
      if (attackTargetZone.cards.length == 2) {
        // If there are multiple cards in the attack zone, only the top card is considered
        attackTargetZone.cards.sort(
          (a, b) => b.toSortingValue().compareTo(a.toSortingValue()),
        );
        final firstCardValue = attackTargetZone.cards.first.value;
        final lastCardValue = attackTargetZone.cards.last.value;
        if (firstCardValue == lastCardValue) {
          if (card.value == firstCardValue) {
            // If the card has the same value as the first or last card, it can be played
            return true;
          } else {
            // If the card does not match the suit or value, it cannot be played
            return false;
          }
        } else {
          // If the card is one value higher or lower than the first or last card, it can be played
          if (card.value == firstCardValue + 1 ||
              card.value == lastCardValue - 1) {
            return true;
          } else {
            return false;
          }
        }
      }
      if (attackTargetZone.cards.length == 3) {
        // If there are multiple cards in the attack zone, only the top card is considered
        attackTargetZone.cards.sort(
          (a, b) => b.toSortingValue().compareTo(a.toSortingValue()),
        );
        final firstCardValue = attackTargetZone.cards.first.value;
        final lastCardValue = attackTargetZone.cards.last.value;
        if (card.value == firstCardValue + 1 ||
            card.value == lastCardValue - 1) {
          // If the card is one value higher or lower than the first or last card, it can be played
          return true;
        } else {
          // If the card does not match the suit or value, it cannot be played
          return false;
        }
      }
    } else if (gamePhase == KalamattackGamePhase.defending &&
        playerAttacking != null &&
        playerAttacking!.id == currentPlayer!.id &&
        !waitingForAttack) {
      final defenseTargetZone = dropZones.firstWhere(
        (zone) => zone.id == "defense",
      );

      if (defenseTargetZone.cards.isEmpty) {
        // If the attack zone is empty, any card can be played

        return true;
      }

      if (card.value == 1) {
        if (defenseTargetZone.cards.isEmpty) {
          // If the card is an Ace, it can only be played if the defense zone is empty
          return true;
        }
        if (defenseTargetZone.cards.length == 1) {
          final topCard = defenseTargetZone.cards.last;
          if (topCard.value == 1) {
            // If the top card is also an Ace, it can be played
            return true;
          } else {
            // If the top card is not an Ace, it cannot be played
            return false;
          }
        }
      }

      if (defenseTargetZone.cards.length >= 4) {
        // If there are multiple cards in the attack zone, only the top card is considered
        return false;
      }

      // Check if the card can be played based on the card in the attack zone
      if (defenseTargetZone.cards.length == 1) {
        final topCard = defenseTargetZone.cards.last;
        if (topCard.value == 1) {
          // If the top card is an Ace, it can be played
          return false;
        }
        if (card.value == topCard.value ||
            card.value == topCard.value - 1 ||
            card.value == topCard.value + 1) {
          // If the card has the same suit or value as the top card, it can be played
          return true;
        } else {
          // If the card does not match the suit or value, it cannot be played
          return false;
        }
      }
      if (defenseTargetZone.cards.length == 2) {
        // If there are multiple cards in the attack zone, only the top card is considered
        defenseTargetZone.cards.sort(
          (a, b) => b.toSortingValue().compareTo(a.toSortingValue()),
        );
        final firstCardValue = defenseTargetZone.cards.first.value;
        final lastCardValue = defenseTargetZone.cards.last.value;
        if (lastCardValue == 1) {
          // If the last card is an Ace, it can be played
          return false;
        }
        if (firstCardValue == lastCardValue) {
          if (card.value == firstCardValue) {
            // If the card has the same value as the first or last card, it can be played
            return true;
          } else {
            // If the card does not match the suit or value, it cannot be played
            return false;
          }
        } else {
          // If the card is one value higher or lower than the first or last card, it can be played
          if (card.value == firstCardValue + 1 ||
              card.value == lastCardValue - 1) {
            return true;
          } else {
            return false;
          }
        }
      }
      if (defenseTargetZone.cards.length == 3) {
        // If there are multiple cards in the attack zone, only the top card is considered
        defenseTargetZone.cards.sort(
          (a, b) => b.toSortingValue().compareTo(a.toSortingValue()),
        );
        final firstCardValue = defenseTargetZone.cards.first.value;
        final lastCardValue = defenseTargetZone.cards.last.value;
        if (card.value == firstCardValue + 1 ||
            card.value == lastCardValue - 1) {
          // If the card is one value higher or lower than the first or last card, it can be played
          return true;
        } else {
          // If the card does not match the suit or value, it cannot be played
          return false;
        }
      }
    }
    return true;
  }

  void _initializeData() async {
    print("Initializing Crazy Eights data");
    print("Current player: ${widget.player.id}");
    currentPlayer = KalamattackPlayer(
      id: widget.player.id,
      name: widget.player.name,

      hand: [],
      isHost: widget.player.isHost,
    );
    for (var p in widget.players) {
      KalamattackPlayer player = KalamattackPlayer(
        id: p.id,
        name: p.name,

        hand: [],
        isHost: p.isHost,
        isBot: p is BotPlayer,
      );
      if (p is BotPlayer) {
        // bots.add(
        //   CrazyEightsBot(
        //     id: player.id,
        //     name: player.name,
        //     botPlayer: player,
        //     deckCards: deckCards,
        //     difficulty: p.difficulty,
        //     onPlayCard: onPlayCardBot,
        //     setState: setState,
        //   ),
        // );
      } else {
        player.isBot = false; // Ensure isBot is set correctly
      }

      players.add(player);
    }

    dropZones.add(
      DropZoneData(
        id: "pile1",
        canDragCardOut: false,
        isPublic: true,
        stackMode: StackMode.overlay,
        rules: DropZoneRules(
          startingCards: [],
          bannedCards: [],
          allowedCards: AllowedCards.none,
          cardOrder: CardOrder.none,
          allowedSuits: [],
        ),
      ),
    );

    dropZones.add(
      DropZoneData(
        id: "pile2",
        canDragCardOut: false,
        isPublic: true,
        stackMode: StackMode.overlay,
        rules: DropZoneRules(
          startingCards: [],
          bannedCards: [],
          allowedCards: AllowedCards.none,
          cardOrder: CardOrder.none,
          allowedSuits: [],
        ),
      ),
    );
    dropZones.add(
      DropZoneData(
        id: "pile3",
        canDragCardOut: false,
        isPublic: true,
        stackMode: StackMode.overlay,
        rules: DropZoneRules(
          startingCards: [],
          bannedCards: [],
          allowedCards: AllowedCards.none,
          cardOrder: CardOrder.none,
          allowedSuits: [],
        ),
      ),
    );
    dropZones.add(
      DropZoneData(
        id: "attack",
        canDragCardOut: false,
        isPublic: false,
        isDropArea: true,
        stackMode: StackMode.spacedHorizontal,
        rules: DropZoneRules(
          startingCards: [],
          bannedCards: [],
          allowedCards: AllowedCards.all,
          cardOrder: CardOrder.none,
          allowedSuits: [],
        ),
        onCardTapped: (card) {
          SharedPrefs.hapticButtonPress();
          //remove card from zone and add it to the player's hand
          final targetZone = dropZones.firstWhere(
            (zone) => zone.id == "attack",
          );
          targetZone.cards.removeWhere((c) => c.id == card.id);
          currentPlayer!.hand.add(card);
          handCards.add(card);
          handCards = sortHand(handCards);
          handController.updateHand(currentPlayer!.hand);
          players[0].hand.add(card);
          connectionService.broadcastMessage({
            'type': 'update_attack_cards',
            'playerAttackingId': playerAttacking!.id,
            'cards': targetZone.cards.map((c) => c.toMap()).toList(),
          }, currentPlayer!.id);
          setState(() {});
        },
      ),
    );
    dropZones.add(
      DropZoneData(
        id: "defense",
        canDragCardOut: false,
        isPublic: false,
        isDropArea: true,
        stackMode: StackMode.spacedHorizontal,
        rules: DropZoneRules(
          startingCards: [],
          bannedCards: [],
          allowedCards: AllowedCards.all,
          cardOrder: CardOrder.none,
          allowedSuits: [],
        ),
        onCardTapped: (card) {
          SharedPrefs.hapticButtonPress();
          //remove card from zone and add it to the player's hand
          final targetZone = dropZones.firstWhere(
            (zone) => zone.id == "defense",
          );
          targetZone.cards.removeWhere((c) => c.id == card.id);
          currentPlayer!.hand.add(card);
          handCards.add(card);
          handCards = sortHand(handCards);
          handController.updateHand(currentPlayer!.hand);
          players[0].hand.add(card);
          setState(() {});
          connectionService.broadcastMessage({
            'type': 'update_defense_cards',
            'playerThatIsAttackingId': playerThatIsAttacking!.id,
            'cards': targetZone.cards.map((c) => c.toMap()).toList(),
          }, currentPlayer!.id);
        },
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
      // If the current player is the host, deal cards
      List<CardData> shuffledDeck = [...fullKalamattackDeck];
      print("Shuffled deck: ${shuffledDeck.length}");
      final numberOfCardsToDeal = 4;
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
      final pile1Card = deckCards.removeLast();
      final pile2Card = deckCards.removeLast();
      final pile3Card = deckCards.removeLast();
      dropZones.firstWhere((zone) => zone.id == "pile1").cards.add(pile1Card);
      dropZones.firstWhere((zone) => zone.id == "pile2").cards.add(pile2Card);
      dropZones.firstWhere((zone) => zone.id == "pile3").cards.add(pile3Card);
      print("Deck cards: ${deckCards.length}");
      await connectionService.broadcastMessage({
        'type': 'deal_cards',

        'players': players.map((p) => p.toMap()).toList(),
        'deck': deckCards.map((c) => c.toMap()).toList(),
        'pile1Card': pile1Card.toMap(),
        'pile2Card': pile2Card.toMap(),
        'pile3Card': pile3Card.toMap(),

        'playOrder': playOrder.join(','),
      }, currentPlayer!.id);
      handCards = sortHand(currentPlayer!.hand);

      setState(() {});
    }

    // Update currentPlayer to reference the actual object in the sorted list
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    // dealCards();

    int indexOfPlayersTurn = players.indexWhere((p) => p.myTurn);
    // if (players[indexOfPlayersTurn].isBot) {
    //   final bot = bots.firstWhere(
    //     (b) => b.id == players[indexOfPlayersTurn].id,
    //   );
    //   Future.delayed(Duration(milliseconds: 500), () {
    //     bot.playCard(dropZones.first.cards);
    //   });
    // }
    setState(() {});
  }

  void dealCards() async {}

  void addAttackCards(DragData dragData, String targetZoneId) async {
    final targetZone = dropZones.firstWhere((zone) => zone.id == targetZoneId);
    final draggedCard = dragData.cards.first;
    currentPlayer!.hand.removeWhere(
      (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
    );
    players[0].hand.removeWhere(
      (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
    );
    handCards.removeWhere((c) => c.id == draggedCard.id);
    targetZone.cards.addAll(dragData.cards);

    connectionService.broadcastMessage({
      'type': 'update_attack_cards',
      'playerAttackingId': playerAttacking!.id,
      'cards': targetZone.cards.map((c) => c.toMap()).toList(),
    }, currentPlayer!.id);
    setState(() {});
  }

  void addDefenseCards(DragData dragData, String targetZoneId) async {
    final targetZone = dropZones.firstWhere((zone) => zone.id == targetZoneId);
    final draggedCard = dragData.cards.first;
    currentPlayer!.hand.removeWhere(
      (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
    );
    players[0].hand.removeWhere(
      (card) => dragData.cards.any((dragCard) => dragCard.id == card.id),
    );
    handCards.removeWhere((c) => c.id == draggedCard.id);
    targetZone.cards.addAll(dragData.cards);

    connectionService.broadcastMessage({
      'type': 'update_defense_cards',
      'playerThatIsAttackingId': playerThatIsAttacking!.id,
      'cards': targetZone.cards.map((c) => c.toMap()).toList(),
    }, currentPlayer!.id);
    setState(() {});
  }

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
      gameState = KalamattackGameState.gameOver;
      SharedPrefs.addCrazyEightsGamesPlayed(1);
      setState(() {});
      connectionService.broadcastMessage({
        'type': 'game_over',
        'winnerId': botId,
      }, currentPlayer!.id);
      return;
    }

    int nextPlayerIndex = (indexOfBot + 1) % players.length;

    KalamattackPlayer nextPlayer = players[nextPlayerIndex];

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
    }, currentPlayer!.id);
    if (players[players.indexWhere((p) => p.id == nextPlayer.id)].isBot) {
      Future.delayed(Duration(seconds: 1), () {
        final bot = bots.firstWhere((b) => b.id == players[nextPlayerIndex].id);

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
      7,
    ); // Limit to 12 cards for scaling
    final handWidth = 100 + (7 * 50); // 116 is card width + padding

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
    List<KalamattackPlayer> sortedPlayers = List.from(players);
    sortedPlayers.shuffle();
    for (var player in sortedPlayers) {
      order.add(player.id);
    }

    return order;
  }

  void pickFromPile(int pileIndex) {
    DropZoneData targetZone = dropZones[pileIndex];
    CardData cardPicked = targetZone.cards.removeLast();
    currentPlayer!.hand.add(cardPicked);
    handCards.add(cardPicked);
    players[0].hand.add(cardPicked);
    handCards = sortHand(handCards);
    handController.updateHand(currentPlayer!.hand);
    if (deckCards.isEmpty) {
      // If the deck is empty, we cannot pick a card
      deckCards.addAll(discard);
      discard.clear();
      deckCards.shuffle();
    }
    CardData newCard = deckCards.removeLast();
    targetZone.cards.add(newCard);
    if (handCards.length > 6) {
      gamePhase = KalamattackGamePhase.discardingCard;
      connectionService.broadcastMessage({
        'type': 'card_picked_from_pile',
        'playerId': currentPlayer!.id,

        'deck': deckCards.map((c) => c.toMap()).toList(),
        'cardPicked': cardPicked.toMap(),
        'newCard': newCard.toMap(),
        'pileIndex': pileIndex,
      }, currentPlayer!.id);
    } else {
      players[0].myTurn = false;
      currentPlayer!.myTurn = false;
      players[1].myTurn = true;
      gamePhase = KalamattackGamePhase.selectingMove;
      connectionService.broadcastMessage({
        'type': 'card_picked_from_pile_end_turn',
        'playerId': currentPlayer!.id,
        'nextPlayerId': players[1].id,
        'deck': deckCards.map((c) => c.toMap()).toList(),
        'cardPicked': cardPicked.toMap(),
        'newCard': newCard.toMap(),
        'pileIndex': pileIndex,
        'discardCards': discard.map((c) => c.toMap()).toList(),
      }, currentPlayer!.id);
    }
    setState(() {});
  }

  void selectCardToDiscard(CardData card) {
    print("Selected card to discard: ${card.toString()}");
    print("Can discard card: ${handCards.any((c) => c.id == card.id)}");
    print("Current player hand: ${handCards.map((c) => c.id).join(', ')}");
    handCards.removeWhere((c) => c.id == card.id);
    discard.add(card);
    players[0].hand.removeWhere((c) => c.id == card.id);
    currentPlayer!.hand.removeWhere((c) => c.id == card.id);
    handController.removeCardFromPile(card.id);
    // handCards = sortHand(currentPlayer!.hand);
    players[0].myTurn = false;
    currentPlayer!.myTurn = false;
    players[1].myTurn = true;
    setState(() {
      deckCards.add(card);
      gamePhase = KalamattackGamePhase.selectingMove;
    });
    connectionService.broadcastMessage({
      'type': 'card_discarded',
      'playerId': currentPlayer!.id,
      'nextPlayerId': players[1].id,
      'card': card.toMap(),
      'discardCards': discard.map((c) => c.toMap()).toList(),
    }, currentPlayer!.id);
    // final playersTurn = players.firstWhere((p) => p.myTurn);
    // if (playersTurn.isBot) {
    //   final bot = bots.firstWhere((b) => b.id == playersTurn.id);
    //   Future.delayed(Duration(seconds: 1), () {
    //     bot.playCard([], null, players);
    //   });
    // }
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
              title: "Kalamattack",
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
                                  children: kalamatackRules,
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
                gameState == KalamattackGameState.playing
                    ? buildPlayingScreen(calculatedScale, context, handScale)
                    : gameState == KalamattackGameState.gameOver
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
                              '${player.health} HP',
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
                draggableCards:
                    (players[0].myTurn &&
                        gamePhase == KalamattackGamePhase.attacking) ||
                    (gamePhase == KalamattackGamePhase.defending &&
                        playerAttacking!.id == currentPlayer!.id &&
                        !waitingForAttack),
                onTapCard:
                    players[0].myTurn &&
                            gamePhase == KalamattackGamePhase.discardingCard
                        ? selectCardToDiscard
                        : null,
                isCardPlayable:
                    players[0].myTurn ||
                            gamePhase == KalamattackGamePhase.defending
                        ? customDropZoneValidator
                        : null,
              ),
            ),
          ),
          if (gamePhase == KalamattackGamePhase.discardingCard ||
              gamePhase == KalamattackGamePhase.selectingMove) ...[
            Positioned(
              top:
                  (MediaQuery.of(context).size.height -
                          kToolbarHeight -
                          MediaQuery.of(context).padding.top -
                          32) /
                      2 -
                  (400 * dropZones[0].scale) / 2 -
                  (300 * dropZones[0].scale) / 2,
              left:
                  (MediaQuery.of(context).size.width - 32) / 2 -
                  (120 * dropZones[0].scale) / 2,
              child: CrazyEightsDeck(
                cards: deckCards,
                deckId: 'deck',
                scale: dropZones[0].scale + 0.1,
                handScale: handScale,
                onReachEndOfDeck: () {
                  //TODO: Implement logic for when the deck is empty
                  deckCards.addAll(discard);
                  discard.clear();
                  deckCards.shuffle();
                  connectionService.broadcastMessage({
                    'type': 'deck_empty',
                    'deck': deckCards.map((c) => c.toMap()).toList(),
                  }, currentPlayer!.id);
                  setState(() {});
                },
                interactable:
                    currentPlayer!.myTurn &&
                    gamePhase == KalamattackGamePhase.selectingMove,
                controller: deckController,
                onCardDrawn: (card) async {
                  handCards.add(card);
                  currentPlayer!.hand.add(card);
                  handCards = sortHand(handCards);
                  currentPlayer!.hand = sortHand(currentPlayer!.hand);
                  handController.updateHand(currentPlayer!.hand);
                  if (handCards.length > 6) {
                    gamePhase = KalamattackGamePhase.discardingCard;
                    connectionService.broadcastMessage({
                      'type': 'drew_card',
                      'playerId': currentPlayer!.id,

                      'deck': deckCards.map((c) => c.toMap()).toList(),
                      'cardPicked': card.toMap(),
                    }, currentPlayer!.id);
                  } else {
                    gamePhase = KalamattackGamePhase.selectingMove;
                    players[0].myTurn = false;
                    currentPlayer!.myTurn = false;
                    players[1].myTurn = true;
                    connectionService.broadcastMessage({
                      'type': 'drew_card_end_turn',
                      'playerId': currentPlayer!.id,
                      'nextPlayerId': players[1].id,
                      'deck': deckCards.map((c) => c.toMap()).toList(),
                      'cardPicked': card.toMap(),
                    }, currentPlayer!.id);
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
                  (400 * dropZones[0].scale) / 2 +
                  (100 * dropZones[0].scale) / 2,
              left:
                  (MediaQuery.of(context).size.width - 32) / 2 -
                  (120 * dropZones[0].scale) / 2 -
                  (250 * dropZones[0].scale) / 2,
              child: DropZoneWidget(
                zone: dropZones[0],
                currentDragData: currentDragData,
                onMoveCards: _moveCards,
                getCardsFromIndex: _getCardsFromIndex,
                onDragStarted: _onDragStarted,
                onDragEnd: _onDragEnd,

                canTap:
                    currentPlayer!.myTurn &&
                    gamePhase == KalamattackGamePhase.selectingMove,
                onTap: () {
                  pickFromPile(0);
                },
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
                  (400 * dropZones[0].scale) / 2 +
                  (100 * dropZones[0].scale) / 2,
              left:
                  (MediaQuery.of(context).size.width - 32) / 2 -
                  (120 * dropZones[0].scale) / 2,
              child: DropZoneWidget(
                zone: dropZones[1],
                currentDragData: currentDragData,
                onMoveCards: _moveCards,
                getCardsFromIndex: _getCardsFromIndex,
                onDragStarted: _onDragStarted,
                onDragEnd: _onDragEnd,
                canTap:
                    currentPlayer!.myTurn &&
                    gamePhase == KalamattackGamePhase.selectingMove,
                onTap: () {
                  pickFromPile(1);
                },
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
                  (400 * dropZones[0].scale) / 2 +
                  (100 * dropZones[0].scale) / 2,
              left:
                  (MediaQuery.of(context).size.width - 32) / 2 -
                  (120 * dropZones[0].scale) / 2 +
                  (250 * dropZones[0].scale) / 2,
              child: DropZoneWidget(
                zone: dropZones[2],
                currentDragData: currentDragData,
                onMoveCards: _moveCards,
                getCardsFromIndex: _getCardsFromIndex,
                onDragStarted: _onDragStarted,
                onDragEnd: _onDragEnd,
                canTap:
                    currentPlayer!.myTurn &&
                    gamePhase == KalamattackGamePhase.selectingMove,
                onTap: () {
                  pickFromPile(2);
                },
                customWillAccept:
                    () => customDropZoneValidator(currentDragData.cards.first),
              ),
            ),
          ] else if (gamePhase == KalamattackGamePhase.attacking) ...[
            if (playerAttacking == null)
              //Position in the center of the screen
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    FancyWidget(
                      child: Text(
                        "Select a player to attack",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    Wrap(
                      children: [
                        for (var player in players.where(
                          (p) => p.id != currentPlayer!.id,
                        ))
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ActionButton(
                              text: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  player.name,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              onTap: () {
                                SharedPrefs.hapticButtonPress();
                                setState(() {
                                  playerAttacking = player;
                                });
                                connectionService.broadcastMessage({
                                  'type': 'select_player_to_attack',
                                  'playerId': currentPlayer!.id,
                                  'attackingPlayerId': player.id,
                                }, currentPlayer!.id);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    if (!waitingForDefense) const SizedBox(height: 250),
                    if (waitingForDefense) const SizedBox(height: 65),
                    if (waitingForDefense)
                      FancyWidget(
                        child: Text(
                          "${playerAttacking!.name}'s Defense",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                    if (waitingForDefense) const SizedBox(height: 8),
                    if (waitingForDefense)
                      Text(
                        "Defense: ${calculateDefense(dropZones[4].cards)}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * handScale,
                        ),
                      ),
                    if (waitingForDefense && damageAsDefense == 0)
                      const SizedBox(height: 8),
                    if (waitingForDefense && damageAsDefense > 0)
                      const SizedBox(height: 4),
                    if (damageAsDefense > 0)
                      Text(
                        "Damage to Attacker: $damageAsDefense",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18 * handScale,
                        ),
                      ),
                    if (waitingForDefense && damageAsDefense > 0)
                      const SizedBox(height: 4),
                    if (waitingForDefense)
                      DropZoneWidget(
                        zone: dropZones[4],
                        currentDragData: currentDragData,
                        onMoveCards: _moveCards,
                        getCardsFromIndex: _getCardsFromIndex,
                        onDragStarted: _onDragStarted,
                        onDragEnd: _onDragEnd,
                        canTap: false,
                        showDecorations: false,
                        onTap: () {},
                        customWillAccept:
                            () => customDropZoneValidator(
                              currentDragData.cards.first,
                            ),
                      ),
                    if (waitingForDefense) const SizedBox(height: 50),

                    FancyWidget(
                      child: Text(
                        "Attacking ${playerAttacking!.name}",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      "Damage: ${calculateDamage(dropZones[3].cards)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * handScale,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropZoneWidget(
                      zone: dropZones[3],
                      currentDragData: currentDragData,
                      onMoveCards: addAttackCards,
                      getCardsFromIndex: _getCardsFromIndex,
                      onDragStarted: _onDragStarted,
                      onDragEnd: _onDragEnd,
                      showDecorations: !waitingForDefense,
                      canTap:
                          currentPlayer!.myTurn &&
                          gamePhase == KalamattackGamePhase.selectingMove,
                      onTap: () {},
                      customWillAccept:
                          () => customDropZoneValidator(
                            currentDragData.cards.first,
                          ),
                    ),
                    if (!waitingForDefense) const SizedBox(height: 4),
                    if (!waitingForDefense)
                      if (dropZones[3].cards.isNotEmpty)
                        Text(
                          "Tap on a card in the zone to remove it",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16 * handScale,
                          ),
                        ),
                    if (!waitingForDefense) const SizedBox(height: 16),
                    if (canSubmitAttack() && !waitingForDefense)
                      ActionButton(
                        width: 100,
                        text: Text(
                          "Attack",
                          style: TextStyle(color: Colors.white),
                        ),
                        onTap: () {
                          attackDamage = calculateDamage(dropZones[3].cards);
                          waitingForDefense = true;
                          setState(() {});
                          connectionService.broadcastMessage({
                            'type': 'attack_player',

                            'attackingPlayerId': playerAttacking!.id,
                            'attackDamage': attackDamage,
                          }, currentPlayer!.id);
                        },
                      ),
                  ],
                ),
              ),
          ] else if (gamePhase == KalamattackGamePhase.defending) ...[
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const SizedBox(height: 75),

                  FancyWidget(
                    child: Text(
                      "${playerThatIsAttacking!.name}'s Attack",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Damage: ${calculateDamage(dropZones[3].cards)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * handScale,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropZoneWidget(
                    zone: dropZones[3],
                    currentDragData: currentDragData,
                    onMoveCards: _moveCards,
                    getCardsFromIndex: _getCardsFromIndex,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                    canTap: false,
                    showDecorations: false,
                    onTap: () {},
                    customWillAccept:
                        () => customDropZoneValidator(
                          currentDragData.cards.first,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (!waitingForAttack)
                    FancyWidget(
                      child: Text(
                        "Defending from ${playerThatIsAttacking!.name}",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  if (!waitingForAttack) const SizedBox(height: 8),
                  if (!waitingForAttack)
                    Text(
                      "Defense: ${calculateDefense(dropZones[4].cards)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * handScale,
                      ),
                    ),
                  if (!waitingForAttack && damageAsDefense == 0)
                    const SizedBox(height: 8),
                  if (!waitingForAttack && damageAsDefense > 0)
                    const SizedBox(height: 4),
                  if (damageAsDefense > 0)
                    Text(
                      "Damage to Attacker: $damageAsDefense",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * handScale,
                      ),
                    ),
                  if (!waitingForAttack && damageAsDefense > 0)
                    const SizedBox(height: 4),
                  if (!waitingForAttack)
                    DropZoneWidget(
                      zone: dropZones[4],
                      currentDragData: currentDragData,
                      onMoveCards: addDefenseCards,
                      getCardsFromIndex: _getCardsFromIndex,
                      onDragStarted: _onDragStarted,
                      onDragEnd: _onDragEnd,
                      showDecorations: !waitingForDefense,
                      canTap:
                          currentPlayer!.myTurn &&
                          gamePhase == KalamattackGamePhase.selectingMove,
                      onTap: () {},
                      customWillAccept:
                          () => customDropZoneValidator(
                            currentDragData.cards.first,
                          ),
                    ),
                  if (!waitingForAttack) const SizedBox(height: 4),
                  if (!waitingForAttack)
                    if (dropZones[4].cards.isNotEmpty)
                      Text(
                        "Tap on a card in the zone to remove it",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * handScale,
                        ),
                      ),
                  if (!waitingForAttack && damageAsDefense == 0)
                    const SizedBox(height: 16),
                  if (!waitingForAttack && damageAsDefense > 0)
                    const SizedBox(height: 4),
                  if (canSubmitDefense() && !waitingForAttack)
                    ActionButton(
                      width: 100,
                      text: Text(
                        "Defend",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        // attackDamage = calculateDamage(dropZones[4].cards);
                        // waitingForDefense = true;
                        int defense = calculateDefense(dropZones[4].cards);
                        int totalDamage = attackDamage - defense;
                        if (totalDamage <= 0) {
                          totalDamage = 0;
                        }
                        players[0].health -= totalDamage;
                        if (damageAsDefense > 0) {
                          players[players.indexWhere(
                                (p) => p.id == playerThatIsAttacking!.id,
                              )]
                              .health -= damageAsDefense;
                        }

                        //next player's turn
                        int indexOfPlayersTurn = players.indexWhere(
                          (p) => p.myTurn,
                        );
                        players[indexOfPlayersTurn].myTurn = false;
                        int nextPlayerIndex =
                            (indexOfPlayersTurn + 1) % players.length;
                        players[nextPlayerIndex].myTurn = true;
                        currentPlayer = players.firstWhere(
                          (p) => p.id == currentPlayer!.id,
                        );
                        gamePhase = KalamattackGamePhase.selectingMove;
                        setState(() {});

                        final attackingPlayer = playerThatIsAttacking!;
                        final defenseDamage = damageAsDefense;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            Timer(Duration(seconds: 2), () {
                              Navigator.of(
                                context,
                              ).pop(); // Close the game screen
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
                                    colors: [
                                      styling.primary,
                                      styling.secondary,
                                    ],
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${attackingPlayer.name} did ${totalDamage} damage to you!${defenseDamage > 0 ? "\nYou did $defenseDamage damage to ${attackingPlayer.name}!" : ""}",
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
                        waitingForDefense = false;
                        waitingForAttack = false;
                        attackDamage = 0;

                        discard.addAll(dropZones[3].cards);
                        discard.addAll(dropZones[4].cards);
                        dropZones[3].cards.clear();
                        dropZones[4].cards.clear();

                        connectionService.broadcastMessage({
                          'type': 'defend_player',
                          'attackingPlayerId': playerThatIsAttacking!.id,
                          'defendingPlayerId': currentPlayer!.id,
                          'defense': defense,
                          'totalDamage': totalDamage,
                          'damageAsDefense': defenseDamage,
                          'discard':
                              discard
                                  .map((c) => c.toMap())
                                  .toList(), // Send discarded cards
                          'players': players.map((p) => p.toMap()).toList(),
                          // Send updated player states
                        }, currentPlayer!.id);
                        playerAttacking = null;
                        playerThatIsAttacking = null;
                        damageAsDefense = 0;
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ] else if (gamePhase == KalamattackGamePhase.othersAttacking) ...[
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const SizedBox(height: 75),

                  FancyWidget(
                    child: Text(
                      "${playerThatIsAttacking!.name}'s Attack",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Damage: ${calculateDamage(dropZones[3].cards)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * handScale,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropZoneWidget(
                    zone: dropZones[3],
                    currentDragData: currentDragData,
                    onMoveCards: _moveCards,
                    getCardsFromIndex: _getCardsFromIndex,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                    canTap: false,
                    showDecorations: false,
                    onTap: () {},
                    customWillAccept:
                        () => customDropZoneValidator(
                          currentDragData.cards.first,
                        ),
                  ),
                  const SizedBox(height: 10),

                  FancyWidget(
                    child: Text(
                      "${playerAttacking!.name}'s Defense",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Defense: ${calculateDefense(dropZones[4].cards)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18 * handScale,
                    ),
                  ),
                  if (damageAsDefense == 0) const SizedBox(height: 8),
                  if (damageAsDefense > 0) const SizedBox(height: 4),
                  if (damageAsDefense > 0)
                    Text(
                      "Damage to Attacker: $damageAsDefense",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18 * handScale,
                      ),
                    ),
                  if (damageAsDefense > 0) const SizedBox(height: 4),

                  DropZoneWidget(
                    zone: dropZones[4],
                    currentDragData: currentDragData,
                    onMoveCards: addDefenseCards,
                    getCardsFromIndex: _getCardsFromIndex,
                    onDragStarted: _onDragStarted,
                    onDragEnd: _onDragEnd,
                    showDecorations: false,
                    canTap: false,
                    onTap: () {},
                    customWillAccept:
                        () => customDropZoneValidator(
                          currentDragData.cards.first,
                        ),
                  ),
                ],
              ),
            ),
          ],
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
      Positioned(
        bottom: 150 * handScale + (32 * handScale),
        right: 10,
        child: FancyBorder(
          isFilled: true,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Health",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * calculatedScale,
                  ),
                ),
                Text(
                  currentPlayer?.health.toString() ?? "0",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * calculatedScale,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (currentPlayer!.myTurn &&
          gamePhase == KalamattackGamePhase.selectingMove)
        Positioned(
          bottom: 150 * handScale + (40 * handScale),
          left: 24,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionButton(
                text: Text(
                  'Attack',
                  style: TextStyle(fontSize: 18.0, color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    gamePhase = KalamattackGamePhase.attacking;
                  });
                },
                width: 100.0,
                height: 50.0,
              ),
              Text(" or Draw", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      if (currentPlayer!.myTurn &&
          gamePhase == KalamattackGamePhase.discardingCard)
        Positioned(
          bottom: 150 * handScale + (40 * handScale),
          left: 32,

          child: FancyWidget(
            child: Text(
              "Tap on a card to discard it",
              style: TextStyle(color: Colors.white, fontSize: 16 * handScale),
            ),
          ),
        ),
      // if (currentPlayer!.myTurn &&
      //     gamePhase == KalamattackGamePhase.attacking &&
      //     playerAttacking != null)
      //   Positioned(
      //     bottom: 150 * handScale + (40 * handScale) + 50,
      //     left: 24,

      //     child:
      //   ),
      if (currentPlayer!.myTurn && gamePhase == KalamattackGamePhase.attacking)
        Positioned(
          bottom: 150 * handScale + (40 * handScale),
          left: 24,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!waitingForDefense)
                ActionButton(
                  text: Text(
                    'Back',
                    style: TextStyle(fontSize: 14.0, color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      gamePhase = KalamattackGamePhase.selectingMove;
                      playerAttacking = null;
                      waitingForDefense = false;
                      //add cards back to the hand

                      for (var card in dropZones[3].cards) {
                        currentPlayer!.hand.add(card);
                        handCards.add(card);
                        players[0].hand.add(card);
                      }
                      handCards = sortHand(handCards);
                      currentPlayer!.hand = sortHand(currentPlayer!.hand);
                      handController.updateHand(currentPlayer!.hand);
                      dropZones[3].cards.clear();
                      dropZones[4].cards.clear();
                      attackDamage = 0;
                    });
                    connectionService.broadcastMessage({
                      'type': 'back_from_attack',
                      'playerId': currentPlayer!.id,
                    }, currentPlayer!.id);
                  },
                  width: 60.0,
                  height: 40.0,
                ),
              if (playerAttacking != null && !waitingForDefense)
                const SizedBox(width: 8.0),
              if (playerAttacking != null && !waitingForDefense)
                SizedBox(
                  width: MediaQuery.of(context).size.width - 24 - 60 - 120,
                  child: Text(
                    "Drag cards to the zone to add to your attack",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * handScale,
                    ),
                  ),
                ),
              if (waitingForDefense)
                Text(
                  "Waiting for ${playerAttacking!.name} to defend",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * handScale,
                  ),
                ),
            ],
          ),
        ),
      if (playerAttacking != null &&
          playerAttacking!.id == currentPlayer!.id &&
          gamePhase == KalamattackGamePhase.defending &&
          !waitingForAttack)
        Positioned(
          bottom: 150 * handScale + (40 * handScale),
          left: 24,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 10 - 120,
                child: Text(
                  "Drag cards to the zone to add to your defense",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * handScale,
                  ),
                ),
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
              SharedPrefs.hapticButtonPress();
              await connectionService.broadcastMessage({
                "type": "play_again",
              }, currentPlayer!.id);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (context) => Kalamattack(
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
