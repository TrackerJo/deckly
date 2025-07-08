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

class Euchre extends StatefulWidget {
  final GamePlayer player;
  final List<GamePlayer> players;
  const Euchre({super.key, required this.player, required this.players});
  // const Euchre({super.key});
  @override
  _EuchreState createState() => _EuchreState();
}

class _EuchreState extends State<Euchre> {
  List<DropZoneData> dropZones = [];
  List<CardData> deckCards = [];
  List<EuchrePlayer> players = [];
  List<EuchreBot> bots = [];
  EuchrePlayer? currentPlayer;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  late StreamSubscription<dynamic> _playersSub;
  List<CardData> handCards = [];
  EuchreGameState gameState = EuchreGameState.teamSelection;
  DragData currentDragData = DragData(
    cards: [],
    sourceZoneId: '',
    sourceIndex: -1,
  );
  final HandController handController = HandController();
  EuchreTeam teamA = EuchreTeam(players: []);
  EuchreTeam teamB = EuchreTeam(players: []);
  List<String> playOrder = [];
  CardSuit? trumpSuit; // Default trump suit
  EuchreGamePhase gamePhase = EuchreGamePhase.decidingTrump;
  bool upCardTurnedDown = false;
  CardSuit? leadSuit;
  bool someonesGoneAlone = false;
  String playerToSkip = "";
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
      } else if (dataMap['type'] == 'team_selection') {
        final team = dataMap['team'] as String;
        final playerId = dataMap['playerId'] as String;
        final player = players.firstWhere((p) => p.id == playerId);
        setState(() {
          if (team == 'A') {
            player.onTeamA = true;
            teamA.players.add(player);
            teamB.players.removeWhere((p) => p.id == playerId);
          } else {
            player.onTeamA = false;
            teamB.players.add(player);
            teamA.players.removeWhere((p) => p.id == playerId);
          }
        });
      } else if (dataMap['type'] == 'game_started') {
        final teamAData = dataMap['teamA'] as Map<String, dynamic>;
        final teamBData = dataMap['teamB'] as Map<String, dynamic>;
        teamA = EuchreTeam.fromMap(teamAData);
        teamB = EuchreTeam.fromMap(teamBData);
        final deckData = dataMap['deckCards'] as List;
        deckCards =
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        final playersData = dataMap['players'] as List;
        players =
            playersData
                .map((p) => EuchrePlayer.fromMap(p as Map<String, dynamic>))
                .toList();

        final startingPlayerId = dataMap['startingPlayerId'] as String;
        final startingPlayerIndex = players.indexWhere(
          (p) => p.id == startingPlayerId,
        );
        final dealerPlayerId = dataMap['dealerId'] as String;
        final dealerPlayerIndex = players.indexWhere(
          (p) => p.id == dealerPlayerId,
        );
        players[dealerPlayerIndex].isDealer = true;
        players[startingPlayerIndex].myTurn = true;
        playOrder = (dataMap['playOrder'] as String).split(',');
        players.sort((a, b) {
          return playOrder.indexOf(a.id).compareTo(playOrder.indexOf(b.id));
        });

        //rotate the players so that the current player is first
        players = [
          ...players.skipWhile((p) => p.id != currentPlayer!.id),
          ...players.takeWhile((p) => p.id != currentPlayer!.id),
        ];
        //sort the drop zones based on the player order
        dropZones.sort((a, b) {
          final aIndex = players.indexWhere((p) => p.id == a.id);
          final bIndex = players.indexWhere((p) => p.id == b.id);
          return aIndex.compareTo(bIndex);
        });

        currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
        handCards = sortHand(currentPlayer!.hand, trumpSuit);

        setState(() {
          gameState = EuchreGameState.playing;
          gamePhase = EuchreGamePhase.decidingTrump;
        });
      } else if (dataMap['type'] == "player_passed") {
        SharedPrefs.hapticButtonPress();
        final playerId = dataMap['playerId'] as String;
        final player = players.firstWhere((p) => p.id == playerId);
        final playerIndex = players.indexOf(player);
        final nextPlayerIndex = (players.indexOf(player) + 1) % players.length;

        setState(() {
          if (player.isDealer) {
            upCardTurnedDown = true;
          }
          players[nextPlayerIndex].myTurn = true;
          players[playerIndex].myTurn = false;
          currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
        });
        bool currentPlayersTurn =
            players[nextPlayerIndex].id == currentPlayer!.id;
        // showDialog(
        //   context: context,

        //   builder: (BuildContext dialogContext) {
        //     Timer(Duration(seconds: 1), () {
        //       try {
        //         if (dialogContext.mounted)
        //           Navigator.of(dialogContext).pop();
        //         else
        //           print("Dialog context is not mounted, cannot pop dialog.");
        //       } catch (e) {
        //         print("Error popping dialog: $e");
        //       }
        //     });
        //     return Dialog(
        //       backgroundColor: Colors.transparent,

        //       child: Container(
        //         width: 400,
        //         height: 200,
        //         decoration: BoxDecoration(
        //           gradient: LinearGradient(
        //             begin: Alignment.topLeft,
        //             end: Alignment.bottomRight,
        //             colors: [styling.primary, styling.secondary],
        //           ),
        //           borderRadius: BorderRadius.circular(12),
        //         ),
        //         child: Container(
        //           margin: EdgeInsets.all(2), // Creates the border thickness
        //           decoration: BoxDecoration(
        //             color: styling.background,
        //             borderRadius: BorderRadius.circular(10),
        //           ),
        //           child: Column(
        //             mainAxisSize: MainAxisSize.min,
        //             mainAxisAlignment: MainAxisAlignment.center,
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             children: [
        //               Text(
        //                 player.name + " passed",
        //                 style: TextStyle(
        //                   color: Colors.white,
        //                   fontSize: 24,
        //                   fontWeight: FontWeight.bold,
        //                 ),
        //                 textAlign: TextAlign.center,
        //               ),
        //               if (currentPlayersTurn)
        //                 Text(
        //                   "It's your turn now!",
        //                   style: TextStyle(color: Colors.white, fontSize: 18),
        //                 ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     );
        //   },
        // );
        if (players[nextPlayerIndex].isBot && currentPlayer!.getIsHost()) {
          Future.delayed(Duration(seconds: 1), () {
            bots
                .firstWhere((b) => b.id == players[nextPlayerIndex].id)
                .decideTrump(
                  upCardTurnedDown
                      ? CardSuit.values
                          .where((s) => s != deckCards.last.suit)
                          .toList()
                      : [deckCards.last.suit],
                  upCardTurnedDown ? players[nextPlayerIndex].isDealer : false,
                  upCardTurnedDown ? null : deckCards.last,
                  players,
                );
          });
        }
      } else if (dataMap['type'] == 'up_card_picked') {
        SharedPrefs.hapticButtonPress();
        final playerCalledBy = players.firstWhere(
          (p) => p.id == dataMap['playerId'],
        );
        final goingAlone = dataMap['goingAlone'] as bool;
        final playerToSkipId = dataMap['playerToSkip'] as String;
        CardSuit upCardSuit = deckCards.last.suit;
        someonesGoneAlone = goingAlone;
        playerToSkip = playerToSkipId;
        upCardTurnedDown = true;
        trumpSuit = upCardSuit;
        if (currentPlayer!.getIsHost()) {
          for (var bot in bots) {
            bot.trumpSuit = upCardSuit;
          }
        }
        gamePhase = EuchreGamePhase.discardingCard;
        final playersTurn = players.firstWhere((p) => p.myTurn);
        final playersTurnIndex = players.indexOf(playersTurn);
        players[playersTurnIndex].myTurn = false;
        //set turn to be next player after dealer
        final dealerIndex = players.indexOf(
          players.firstWhere((p) => p.isDealer),
        );
        players[dealerIndex].hand.add(deckCards.last);
        int nextPlayerIndex = (dealerIndex + 1) % players.length;
        if (goingAlone) {
          int indexToSkip = players.indexWhere((p) => p.id == playerToSkip);
          if (nextPlayerIndex == indexToSkip) {
            nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
          }
          players[players.indexWhere((p) => p.id == playerToSkip)].hand.clear();
          if (playerToSkip == currentPlayer!.id) {
            handCards.clear();
            handController.updateHand(handCards);
          }
        }
        players[nextPlayerIndex].myTurn = true;

        currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
        if (playerCalledBy.onTeamA) {
          teamA.madeIt = true;
        } else {
          teamB.madeIt = true;
        }
        handCards = sortHand(currentPlayer!.hand, upCardSuit);
        setState(() {});

        // handCards.clear();
        // handCards.addAll(currentPlayer!.hand);
        // handController.updateHand(handCards);

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
                        playerCalledBy.name +
                            " picked the up card${goingAlone ? " and is going alone" : ""}. The trump suit is ${upCardSuit.toString()}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (currentPlayer!.isDealer)
                        Text(
                          "Tap on a card to discard it",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        if (players[dealerIndex].isBot && currentPlayer!.getIsHost()) {
          Future.delayed(Duration(seconds: 1), () {
            bots
                .firstWhere((b) => b.id == players[dealerIndex].id)
                .discardCard();
          });
        }
      } else if (dataMap['type'] == 'card_discarded') {
        final playerId = dataMap['playerId'] as String;
        final cardData = dataMap['card'] as Map<String, dynamic>;
        final card = CardData.fromMap(cardData);
        final player = players.firstWhere((p) => p.id == playerId);

        setState(() {
          player.hand.removeWhere((c) => c.id == card.id);
          deckCards.add(card);
          gamePhase = EuchreGamePhase.playing;
          currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
        });
        if (currentPlayer!.myTurn) {
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
                          "${player.name} discarded a card",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

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
          );
        }
        final playersTurnIndex = players.indexWhere((p) => p.myTurn);
        if (players[playersTurnIndex].isBot && currentPlayer!.getIsHost()) {
          Future.delayed(Duration(seconds: 1), () {
            bots
                .firstWhere((b) => b.id == players[playersTurnIndex].id)
                .playCard([], null, players);
          });
        }
      } else if (dataMap['type'] == 'chose_trump_suit') {
        SharedPrefs.hapticButtonPress();
        final playerId = dataMap['playerId'] as String;
        final suit = CardSuit.values.firstWhere(
          (s) => s.toString() == dataMap['suit'],
        );
        final goingAlone = dataMap['goingAlone'] as bool;
        final playerToSkipId = dataMap['playerToSkip'] as String;
        final player = players.firstWhere((p) => p.id == playerId);
        someonesGoneAlone = goingAlone;
        playerToSkip = playerToSkipId;

        trumpSuit = suit;
        if (currentPlayer!.getIsHost()) {
          for (var bot in bots) {
            bot.trumpSuit = suit;
          }
        }
        gamePhase = EuchreGamePhase.playing;
        upCardTurnedDown = true;
        //set turn to be next player after dealer
        final dealerIndex = players.indexOf(
          players.firstWhere((p) => p.isDealer),
        );
        final previousPlayerIndex = players.indexOf(player);
        players[previousPlayerIndex].myTurn = false;
        int nextPlayerIndex = (dealerIndex + 1) % players.length;
        if (goingAlone) {
          int indexToSkip = players.indexWhere((p) => p.id == playerToSkip);
          if (nextPlayerIndex == indexToSkip) {
            nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
          }
          players[players.indexWhere((p) => p.id == playerToSkip)].hand.clear();
          if (playerToSkip == currentPlayer!.id) {
            handCards.clear();
            handController.updateHand(handCards);
            upCardTurnedDown = false;
          }
        }
        players[nextPlayerIndex].myTurn = true;
        currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
        if (player.onTeamA) {
          teamA.madeIt = true;
        } else {
          teamB.madeIt = true;
        }
        handCards = sortHand(currentPlayer!.hand, suit);
        setState(() {});

        // handCards.clear();
        // handCards.addAll(currentPlayer!.hand);
        // handController.updateHand(handCards);
        setState(() {});
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
                        "${player.name} chose ${suit.toString()} as the trump suit${goingAlone ? " and is going alone" : ""}",
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
        );
        if (players[nextPlayerIndex].isBot && currentPlayer!.getIsHost()) {
          Future.delayed(Duration(seconds: 1), () {
            bots
                .firstWhere((b) => b.id == players[nextPlayerIndex].id)
                .playCard([], null, players);
          });
        }
      } else if (dataMap['type'] == 'player_played') {
        SharedPrefs.hapticButtonPress();
        final playerId = dataMap['playerId'] as String;
        final nextPlayerId = dataMap['nextPlayerId'] as String;
        final player = players.firstWhere((p) => p.id == playerId);
        final nextPlayer = players.firstWhere((p) => p.id == nextPlayerId);
        setState(() {
          players[players.indexOf(player)].myTurn = false;

          players[players.indexOf(nextPlayer)].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);

          player.myTurn = false;
          nextPlayer.myTurn = true;
        });
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
        if (nextPlayer.isBot && currentPlayer!.getIsHost()) {
          Future.delayed(Duration(seconds: 1), () {
            List<CardData> playedCards = [];
            for (var zone in dropZones) {
              if (zone.isPublic) {
                playedCards.addAll(zone.cards);
              }
            }
            bots
                .firstWhere((b) => b.id == nextPlayer.id)
                .playCard(playedCards, leadSuit, players);
          });
        }
      } else if (dataMap["type"] == "trick_ended") {
        // Handle trick ended logic
        final winningPlayerId = dataMap['winningPlayerId'] as String;
        final winningPlayerIndex = players.indexWhere(
          (p) => p.id == winningPlayerId,
        );
        final winningPlayer = players.firstWhere(
          (p) => p.id == winningPlayerId,
        );
        final previousPlayerIndex = players.indexWhere((p) => p.myTurn);
        setState(() {
          // Reset lead suit for the next trick
          leadSuit = null;
          // Set the winning player as current turn
          winningPlayer.myTurn = true;
          players[previousPlayerIndex].myTurn = false;
          players[winningPlayerIndex].myTurn = true;
          currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
          for (var dropZone in dropZones) {
            dropZone.cards.clear(); // Clear all drop zones for the next trick
          }
          if (winningPlayer.onTeamA) {
            teamA.tricksTaken++;
          } else {
            teamB.tricksTaken++;
          }
        });
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
        ).then((_) {
          // Check if the game should end after the trick
          if (teamA.tricksTaken + teamB.tricksTaken >= 5) {
            // If the current player has no cards left, end the round
            scoreRound();
          } else {
            final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
            if (players[nextPlayerIndex].isBot && currentPlayer!.getIsHost()) {
              Future.delayed(Duration(seconds: 1), () {
                bots
                    .firstWhere((b) => b.id == players[nextPlayerIndex].id)
                    .playCard([], null, players);
              });
            }
          }
        });
      } else if (dataMap["type"] == "new_round") {
        someonesGoneAlone = false;
        playerToSkip = "";
        final deckData = dataMap['deckCards'] as List;
        deckCards =
            deckData
                .map((c) => CardData.fromMap(c as Map<String, dynamic>))
                .toList();
        final playersData = dataMap['players'] as List;
        for (var player in playersData) {
          final playerMap = player as Map<String, dynamic>;
          final newPlayer = EuchrePlayer.fromMap(playerMap);

          final existingPlayerIndex = players.indexWhere(
            (p) => p.id == newPlayer.id,
          );
          if (existingPlayerIndex != -1) {
            // Update existing player
            players[existingPlayerIndex].hand.clear();
            players[existingPlayerIndex].hand.addAll(newPlayer.hand);
          } else {
            // Add new player
            players.add(newPlayer);
          }
        }
        // players =
        //     playersData
        //         .map((p) => EuchrePlayer.fromMap(p as Map<String, dynamic>))
        //         .toList();

        players.sort((a, b) {
          return playOrder.indexOf(a.id).compareTo(playOrder.indexOf(b.id));
        });

        //rotate the players so that the current player is first
        players = [
          ...players.skipWhile((p) => p.id != currentPlayer!.id),
          ...players.takeWhile((p) => p.id != currentPlayer!.id),
        ];
        //sort the drop zones based on the player order
        dropZones.sort((a, b) {
          final aIndex = players.indexWhere((p) => p.id == a.id);
          final bIndex = players.indexWhere((p) => p.id == b.id);
          return aIndex.compareTo(bIndex);
        });

        currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
        handCards = sortHand(currentPlayer!.hand, null);
        // handCards.clear();
        // handCards.addAll(currentPlayer!.hand);
        // handController.updateHand(handCards);
        upCardTurnedDown = false;
        setState(() {});
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
      } else if (dataMap["type"] == "play_again") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) =>
                    Euchre(player: widget.player, players: widget.players),
          ),
        );
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
    currentPlayer = EuchrePlayer(
      id: widget.player.id,
      name: widget.player.name,
      onTeamA: false,
      hand: [],
      isHost: widget.player.isHost,
    );
    for (var p in widget.players) {
      EuchrePlayer player = EuchrePlayer(
        id: p.id,
        name: p.name,
        onTeamA: false,
        hand: [],
        isHost: p.isHost,
        isBot: p is BotPlayer,
      );
      if (p is BotPlayer) {
        bots.add(
          EuchreBot(
            name: p.name,
            id: p.id,
            difficulty: p.difficulty,
            botPlayer: player,
            onDecideTrump: onDecideTrumpBot,
            onDiscard: onDiscardBot,
            onPlayCard: onPlayCardBot,
            playedCards: cardsPlayedInRound,
          ),
        );
      }
      print("Adding player: ${player.name} with id: ${player.id}");
      players.add(player);
    }

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
          playable: false,
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

    // Update currentPlayer to reference the actual object in the sorted list
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    // dealCards();
    setState(() {});
  }

  void dealCards() {
    List<CardData> shuffledDeck = [...fullEuchreDeck];
    print("Shuffled deck: ${shuffledDeck.length}");
    shuffledDeck.shuffle();

    handCards = shuffledDeck.sublist(0, 5);
    shuffledDeck.removeRange(0, 5);
    currentPlayer!.hand = [...handCards];
    players.forEach((player) {
      if (player.id != currentPlayer!.id) {
        player.hand = shuffledDeck.sublist(0, 5);
        shuffledDeck.removeRange(0, 5);
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

    EuchrePlayer nextPlayer = players[1];
    if (playerToSkip == nextPlayer.id) {
      nextPlayer = players[2];
    }
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
      if (nextPlayer.isBot) {
        final bot = bots.firstWhere((b) => b.id == nextPlayer.id);
        List<CardData> playedCards = [];
        for (var zone in dropZones) {
          if (zone.isPublic) {
            playedCards.addAll(zone.cards);
          }
        }
        Future.delayed(Duration(milliseconds: 1000), () {
          bot.playCard([...playedCards], leadSuit, players);
        });
      }
    } else {
      //Score the played cards
      scorePlayedCards();
    }
  }

  void onDecideTrumpBot(CardSuit? trump, String botId, bool alone) async {
    SharedPrefs.hapticButtonPress();
    final indexOfBot = players.indexWhere((p) => p.id == botId);

    if (trump == null) {
      final nextPlayerIndex = (indexOfBot + 1) % players.length;
      players[nextPlayerIndex].myTurn = true;

      players[indexOfBot].myTurn = false;
      if (players[indexOfBot].isDealer) {
        upCardTurnedDown = true;
      }
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
      setState(() {});

      connectionService.broadcastMessage({
        'type': 'player_passed',
        'playerId': botId,
      }, currentPlayer!.id);
      // await showDialog(
      //   context: context,

      //   builder: (BuildContext dialogContext) {
      //     Timer(Duration(seconds: 1), () {
      //       try {
      //         if (dialogContext.mounted)
      //           Navigator.of(dialogContext).pop();
      //         else
      //           print("Dialog context is not mounted, cannot pop dialog.");
      //       } catch (e) {
      //         print("Error popping dialog: $e");
      //       }
      //     });
      //     return Dialog(
      //       backgroundColor: Colors.transparent,

      //       child: Container(
      //         width: 400,
      //         height: 200,
      //         decoration: BoxDecoration(
      //           gradient: LinearGradient(
      //             begin: Alignment.topLeft,
      //             end: Alignment.bottomRight,
      //             colors: [styling.primary, styling.secondary],
      //           ),
      //           borderRadius: BorderRadius.circular(12),
      //         ),
      //         child: Container(
      //           margin: EdgeInsets.all(2), // Creates the border thickness
      //           decoration: BoxDecoration(
      //             color: styling.background,
      //             borderRadius: BorderRadius.circular(10),
      //           ),
      //           child: Column(
      //             mainAxisSize: MainAxisSize.min,
      //             mainAxisAlignment: MainAxisAlignment.center,
      //             crossAxisAlignment: CrossAxisAlignment.center,
      //             children: [
      //               Text(
      //                 players[indexOfBot].name + " passed",
      //                 style: TextStyle(
      //                   color: Colors.white,
      //                   fontSize: 24,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //                 textAlign: TextAlign.center,
      //               ),
      //               if (currentPlayer!.myTurn)
      //                 Text(
      //                   "It's your turn now!",
      //                   style: TextStyle(color: Colors.white, fontSize: 18),
      //                 ),
      //             ],
      //           ),
      //         ),
      //       ),
      //     );
      //   },
      // );

      if (players[nextPlayerIndex].isBot) {
        Future.delayed(Duration(seconds: 1), () {
          final bot = bots.firstWhere(
            (b) => b.id == players[nextPlayerIndex].id,
          );
          bot.decideTrump(
            upCardTurnedDown
                ? CardSuit.values
                    .where((s) => s != deckCards.last.suit)
                    .toList()
                : [deckCards.last.suit],
            upCardTurnedDown ? players[nextPlayerIndex].isDealer : false,
            upCardTurnedDown ? null : deckCards.last,
            players,
          );
        });
      }
    } else if (trump == deckCards.last.suit && !upCardTurnedDown) {
      trumpSuit = trump;
      for (var bot in bots) {
        bot.trumpSuit = trump;
      }
      //set turn to be next player after dealer
      players[indexOfBot].myTurn = false;

      final dealerIndex = players.indexOf(
        players.firstWhere((p) => p.isDealer),
      );
      players[dealerIndex].hand.add(deckCards.last);
      int nextPlayerIndex = (dealerIndex + 1) % players.length;
      if (alone) {
        someonesGoneAlone = true;
        playerToSkip = players[(indexOfBot + 2) % players.length].id;
        if ((indexOfBot + 2) % players.length == nextPlayerIndex) {
          nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
        }
      }

      players[nextPlayerIndex].myTurn = true;
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
      upCardTurnedDown = true;
      gamePhase = EuchreGamePhase.discardingCard;
      if (players[indexOfBot].onTeamA) {
        teamA.madeIt = true;
      } else {
        teamB.madeIt = true;
      }
      handCards = sortHand(currentPlayer!.hand, trump);
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
                      players[indexOfBot].name +
                          " picked the up card${alone ? " and is going alone" : ""}. The trump suit is ${trump.toString()}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (currentPlayer!.isDealer)
                      Text(
                        "Tap on a card to discard it",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      setState(() {});

      // handCards.clear();
      // handCards.addAll(currentPlayer!.hand);
      // handController.updateHand(handCards);

      connectionService.broadcastMessage({
        'type': 'up_card_picked',
        'goingAlone': alone,
        'playerToSkip':
            alone ? players[(indexOfBot + 2) % players.length].id : "",
        'playerId': botId,
      }, currentPlayer!.id);
      if (players[dealerIndex].isBot) {
        Future.delayed(Duration(seconds: 1), () {
          final bot = bots.firstWhere((b) => b.id == players[dealerIndex].id);
          bot.discardCard();
        });
      }
    } else {
      trumpSuit = trump;
      for (var bot in bots) {
        bot.trumpSuit = trump;
      }
      gamePhase = EuchreGamePhase.playing;
      upCardTurnedDown = true;
      //set turn to be next player after dealer
      final dealerIndex = players.indexOf(
        players.firstWhere((p) => p.isDealer),
      );

      players[indexOfBot].myTurn = false;
      int nextPlayerIndex = (dealerIndex + 1) % players.length;
      if (alone) {
        someonesGoneAlone = true;
        playerToSkip = players[(indexOfBot + 2) % players.length].id;
        if ((indexOfBot + 2) % players.length == nextPlayerIndex) {
          nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
        }
      }

      players[nextPlayerIndex].myTurn = true;
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
      if (players[indexOfBot].onTeamA) {
        teamA.madeIt = true;
      } else {
        teamB.madeIt = true;
      }
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
                      "${players[indexOfBot].name} chose ${trump.toString()} as the trump suit${alone ? " and is going alone" : ""}",
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
      );

      setState(() {});
      handCards = sortHand(currentPlayer!.hand, trump);

      // handCards.clear();
      // handCards.addAll(currentPlayer!.hand);
      // handController.updateHand(handCards);
      setState(() {});
      connectionService.broadcastMessage({
        'type': 'chose_trump_suit',
        'suit': trump.toString(),
        'goingAlone': alone,
        'playerToSkip':
            alone ? players[(indexOfBot + 2) % players.length].id : "",
        'playerId': botId,
      }, currentPlayer!.id);
      if (players[nextPlayerIndex].isBot) {
        Future.delayed(Duration(seconds: 1), () {
          final bot = bots.firstWhere(
            (b) => b.id == players[nextPlayerIndex].id,
          );
          bot.playCard([], null, players);
        });
      }
    }
  }

  void onDiscardBot(CardData card, String botId) {
    final indexOfBot = players.indexWhere((p) => p.id == botId);

    players[indexOfBot].hand.removeWhere((c) => c.id == card.id);
    final dealerIndex = players.indexOf(players.firstWhere((p) => p.isDealer));

    final nextPlayerIndex = (dealerIndex + 1) % players.length;

    setState(() {});

    // handCards.clear();
    // handCards.addAll(currentPlayer!.hand);
    // handController.updateHand(handCards);
    players[indexOfBot].myTurn = false;

    players[nextPlayerIndex].myTurn = true;
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    if (currentPlayer!.myTurn) {
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
                      "${players[indexOfBot].name} discarded a card",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

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
      );
    }
    setState(() {
      gamePhase = EuchreGamePhase.playing;
      deckCards.add(card);
    });
    connectionService.broadcastMessage({
      'type': 'card_discarded',
      'playerId': botId,
      'card': card.toMap(),
    }, currentPlayer!.id);
    if (players[nextPlayerIndex].isBot) {
      Future.delayed(Duration(seconds: 1), () {
        final bot = bots.firstWhere((b) => b.id == players[nextPlayerIndex].id);
        bot.playCard([], null, players);
      });
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

    EuchrePlayer nextPlayer = players[nextPlayerIndex];
    if (playerToSkip == nextPlayer.id) {
      nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
      nextPlayer = players[nextPlayerIndex];
    }
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
      if (players[players.indexWhere((p) => p.id == nextPlayer.id)].isBot) {
        Future.delayed(Duration(seconds: 1), () {
          final bot = bots.firstWhere(
            (b) => b.id == players[nextPlayerIndex].id,
          );
          List<CardData> playedCards = [];
          for (var zone in dropZones) {
            if (zone.isPublic) {
              playedCards.addAll(zone.cards);
            }
          }
          bot.playCard([...playedCards], leadSuit, players);
        });
      }
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
    if (winningPlayer.onTeamA) {
      teamA.tricksTaken += 1;
    } else {
      teamB.tricksTaken += 1;
    }
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
    ).then((_) {
      // Check if the game should end after the trick
      if (teamA.tricksTaken + teamB.tricksTaken >= 5) {
        // If the current player has no cards left, end the round
        scoreRound();
      } else {
        final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
        if (players[nextPlayerIndex].isBot && currentPlayer!.getIsHost()) {
          Future.delayed(Duration(seconds: 1), () {
            bots
                .firstWhere((b) => b.id == players[nextPlayerIndex].id)
                .playCard([], null, players);
          });
        }
      }
    });
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

  void scoreRound() {
    print("TEAM A TRICKS: ${teamA.tricksTaken}");
    print("TEAM B TRICKS: ${teamB.tricksTaken}");
    int teamAScoreBefore = teamA.tricksTaken;
    int teamBScoreBefore = teamB.tricksTaken;
    if (teamA.tricksTaken == 5 && teamA.madeIt) {
      // Team A wins the round + 2
      bool teamAAlone = players.any((p) => p.onTeamA && p.id == playerToSkip);
      teamA.score += teamAAlone ? 4 : 2;
      showDialog(
        context: context,

        builder: (BuildContext dialogContext) {
          Timer(Duration(seconds: 3), () {
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
                      "Team A took all 5 tricks${teamAAlone ? " and went alone" : ""}!\n+ ${teamAAlone ? "4" : "2"} points for Team A",
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
      ).then((_) {
        if (teamA.score >= 10 || teamB.score >= 10) {
          scoreGame();
        } else if (currentPlayer!.getIsHost()) {
          final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
          if (players[nextPlayerIndex].isBot) {
            Future.delayed(Duration(seconds: 1), () {
              final bot = bots.firstWhere(
                (b) => b.id == players[nextPlayerIndex].id,
              );
              bot.decideTrump(
                [deckCards.last.suit],
                false,
                deckCards.last,
                players,
              );
            });
          }
        }
      });
    } else if (teamA.tricksTaken >= 3 && teamA.madeIt) {
      // Team A wins the round + 1
      teamA.score += 1;
      print("TEAM A TRICKS: ${teamA.tricksTaken}");
      showDialog(
        context: context,

        builder: (BuildContext dialogContext) {
          Timer(Duration(seconds: 3), () {
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
                      "Team A took $teamAScoreBefore tricks!\n+ 1 point for Team A",
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
      ).then((_) {
        if (teamA.score >= 10 || teamB.score >= 10) {
          scoreGame();
        } else if (currentPlayer!.getIsHost()) {
          final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
          if (players[nextPlayerIndex].isBot) {
            Future.delayed(Duration(seconds: 1), () {
              final bot = bots.firstWhere(
                (b) => b.id == players[nextPlayerIndex].id,
              );
              bot.decideTrump(
                [deckCards.last.suit],
                false,
                deckCards.last,
                players,
              );
            });
          }
        }
      });
    } else if (teamB.tricksTaken >= 3 && teamA.madeIt) {
      // Team B set team A, so team B wins the round + 2
      teamB.score += 2;
      showDialog(
        context: context,

        builder: (BuildContext dialogContext) {
          Timer(Duration(seconds: 3), () {
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
                      "Team B euchred Team A!\n+ 2 points for Team B",
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
      ).then((_) {
        if (teamA.score >= 10 || teamB.score >= 10) {
          scoreGame();
        } else if (currentPlayer!.getIsHost()) {
          final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
          if (players[nextPlayerIndex].isBot) {
            Future.delayed(Duration(seconds: 1), () {
              final bot = bots.firstWhere(
                (b) => b.id == players[nextPlayerIndex].id,
              );
              bot.decideTrump(
                [deckCards.last.suit],
                false,
                deckCards.last,
                players,
              );
            });
          }
        }
      });
    } else if (teamB.tricksTaken == 5 && teamB.madeIt) {
      // Team B wins the round + 2
      bool teamBAlone = players.any((p) => !p.onTeamA && p.id == playerToSkip);
      teamB.score += teamBAlone ? 4 : 2;
      showDialog(
        context: context,

        builder: (BuildContext dialogContext) {
          Timer(Duration(seconds: 3), () {
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
                      'Team B took all 5 tricks${teamBAlone ? " and went alone" : ""}!\n+ ${teamBAlone ? "4" : "2"} points for Team B',
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
      ).then((_) {
        if (teamA.score >= 10 || teamB.score >= 10) {
          scoreGame();
        } else if (currentPlayer!.getIsHost()) {
          final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
          if (players[nextPlayerIndex].isBot) {
            Future.delayed(Duration(seconds: 1), () {
              final bot = bots.firstWhere(
                (b) => b.id == players[nextPlayerIndex].id,
              );
              bot.decideTrump(
                [deckCards.last.suit],
                false,
                deckCards.last,
                players,
              );
            });
          }
        }
      });
    } else if (teamB.tricksTaken >= 3 && teamB.madeIt) {
      // Team B wins the round + 1
      teamB.score += 1;
      showDialog(
        context: context,

        builder: (BuildContext dialogContext) {
          Timer(Duration(seconds: 3), () {
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
                      "Team B took ${teamBScoreBefore} tricks!\n+ 1 point for Team B",
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
      ).then((_) {
        if (teamA.score >= 10 || teamB.score >= 10) {
          scoreGame();
        } else if (currentPlayer!.getIsHost()) {
          final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
          if (players[nextPlayerIndex].isBot) {
            Future.delayed(Duration(seconds: 1), () {
              final bot = bots.firstWhere(
                (b) => b.id == players[nextPlayerIndex].id,
              );
              bot.decideTrump(
                [deckCards.last.suit],
                false,
                deckCards.last,
                players,
              );
            });
          }
        }
      });
    } else if (teamA.tricksTaken >= 3 && teamB.madeIt) {
      // Team A set team B, so team A wins the round + 2
      teamA.score += 2;
      showDialog(
        context: context,

        builder: (BuildContext dialogContext) {
          Timer(Duration(seconds: 3), () {
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
                      "Team A euchred Team B!\n+ 2 points for Team A",
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
      ).then((_) {
        if (teamA.score >= 10 || teamB.score >= 10) {
          scoreGame();
        } else if (currentPlayer!.getIsHost()) {
          final nextPlayerIndex = players.indexWhere((p) => p.myTurn);
          if (players[nextPlayerIndex].isBot) {
            Future.delayed(Duration(seconds: 1), () {
              final bot = bots.firstWhere(
                (b) => b.id == players[nextPlayerIndex].id,
              );
              bot.decideTrump(
                [deckCards.last.suit],
                false,
                deckCards.last,
                players,
              );
            });
          }
        }
      });
    }
    if (teamA.score < 10 && teamB.score < 10) {
      someonesGoneAlone = false;
      playerToSkip = "";
      //Move dealer to next player
      //previous persons turn should be false
      final previousPlayerIndex = players.indexWhere((p) => p.myTurn);
      if (previousPlayerIndex != -1) {
        players[previousPlayerIndex].myTurn = false;
      }
      final dealerIndex = players.indexWhere((p) => p.isDealer);
      final nextDealerIndex = (dealerIndex + 1) % players.length;
      final playerNextToDealer = (nextDealerIndex + 1) % players.length;
      players[dealerIndex].isDealer = false;
      players[nextDealerIndex].isDealer = true;
      players[playerNextToDealer].myTurn = true;
      currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
      teamA.tricksTaken = 0;
      teamB.tricksTaken = 0;
      teamA.madeIt = false;
      teamB.madeIt = false;
      leadSuit = null;
      trumpSuit = null;
      upCardTurnedDown = false;
      gamePhase = EuchreGamePhase.decidingTrump;
      if (currentPlayer!.isHost) {
        List<CardData> shuffledDeck = [...fullEuchreDeck];
        print("Shuffled deck: ${shuffledDeck.length}");
        shuffledDeck.shuffle();

        handCards = shuffledDeck.sublist(0, 5);
        shuffledDeck.removeRange(0, 5);
        currentPlayer!.hand = [...handCards];
        players.forEach((player) {
          if (player.id != currentPlayer!.id) {
            player.hand.clear();
            player.hand.addAll(shuffledDeck.sublist(0, 5));
            shuffledDeck.removeRange(0, 5);
          } else {
            player.hand = [...handCards];
          }
        });
        // Initialize deck cards
        deckCards = [...shuffledDeck];
        print("Deck cards: ${deckCards.length}");
        handCards = sortHand(currentPlayer!.hand, null);
        cardsPlayedInRound.clear();
        // handCards = [...currentPlayer!.hand];
        // handCards.clear();
        // handCards.addAll(currentPlayer!.hand);
        // handController.updateHand(handCards);
        for (var bot in bots) {
          bot.trumpSuit = null;
        }
        setState(() {});
        connectionService.broadcastMessage({
          'type': 'new_round',
          'players': players.map((p) => p.toMap()).toList(),

          'deckCards': deckCards.map((c) => c.toMap()).toList(),
        }, currentPlayer!.id);
      }
      setState(() {
        upCardTurnedDown = false;
      });
    }
  }

  void scoreGame() {
    //Check who won the game
    bool teamAWon = teamA.score >= 10;
    bool teamBWon = teamB.score >= 10;
    if (teamAWon) {
      //Check if current player is on team A
      if (players.any((p) => p.id == currentPlayer!.id && p.onTeamA)) {
        //Current player is on team A
        SharedPrefs.addEuchreGamesWon(1);
      }
    } else if (teamBWon) {
      //Check if current player is on team B
      if (players.any((p) => p.id == currentPlayer!.id && !p.onTeamA)) {
        //Current player is on team B
        SharedPrefs.addEuchreGamesWon(1);
      }
    }
    SharedPrefs.addEuchreGamesPlayed(1);
    setState(() {
      gameState = EuchreGameState.gameOver;
    });
  }

  void onPlayedFromBlitzDeck() {}

  double _calculateHandScale(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 32.0; // 16px padding on each side
    final availableWidth = screenWidth - padding;

    // Hand width is 5 cards + 4 gaps (8px each)
    final handWidth = 100 + (5 * 50); // 116 is card width + padding

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
    //genrate random integer from 0 to 1
    int randomInt = math.Random().nextInt(2);
    teamA.players.shuffle();
    teamB.players.shuffle();
    if (randomInt == 0) {
      order.add(teamA.players[0].id);
      order.add(teamB.players[0].id);
      order.add(teamA.players[1].id);
      order.add(teamB.players[1].id);
    } else {
      order.add(teamB.players[0].id);
      order.add(teamA.players[0].id);
      order.add(teamB.players[1].id);
      order.add(teamA.players[1].id);
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
              title: "Euchre",
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
                gameState == EuchreGameState.playing
                    ? buildPlayingScreen(calculatedScale, context, handScale)
                    : gameState == EuchreGameState.teamSelection
                    ? buildTeamSelectionScreen(calculatedScale, context)
                    : gameState == EuchreGameState.gameOver
                    ? buildGameOverScreen()
                    : Container(),
          ),
        ),
      ),
    );
  }

  void selectCardToDiscard(CardData card) {
    print("Selected card to discard: ${card.toString()}");
    print("Can discard card: ${handCards.any((c) => c.id == card.id)}");
    print("Current player hand: ${handCards.map((c) => c.id).join(', ')}");
    handCards.removeWhere((c) => c.id == card.id);

    players[0].hand.removeWhere((c) => c.id == card.id);
    currentPlayer!.hand.removeWhere((c) => c.id == card.id);
    handController.removeCardFromPile(card.id);
    handCards = sortHand(currentPlayer!.hand, trumpSuit);
    setState(() {
      deckCards.add(card);
      gamePhase = EuchreGamePhase.playing;
    });
    connectionService.broadcastMessage({
      'type': 'card_discarded',
      'playerId': currentPlayer!.id,
      'card': card.toMap(),
    }, currentPlayer!.id);
    final playersTurn = players.firstWhere((p) => p.myTurn);
    if (playersTurn.isBot) {
      final bot = bots.firstWhere((b) => b.id == playersTurn.id);
      Future.delayed(Duration(seconds: 1), () {
        bot.playCard([], null, players);
      });
    }
  }

  void chooseTrumpSuit(CardSuit suit) async {
    bool goingAlone = await askIfGoingAlone();
    if (goingAlone) {
      someonesGoneAlone = true;
      playerToSkip =
          players
              .firstWhere(
                (p) =>
                    p.onTeamA == currentPlayer!.onTeamA &&
                    p.id != currentPlayer!.id,
              )
              .id;
    }
    trumpSuit = suit;
    for (var bot in bots) {
      bot.trumpSuit = suit;
    }
    gamePhase = EuchreGamePhase.playing;
    upCardTurnedDown = true;
    //set turn to be next player after dealer
    final dealerIndex = players.indexOf(players.firstWhere((p) => p.isDealer));

    final previousPlayerIndex = players.indexOf(currentPlayer!);
    players[previousPlayerIndex].myTurn = false;
    int nextPlayerIndex = (dealerIndex + 1) % players.length;
    if (goingAlone) {
      int indexToSkip = players.indexWhere((p) => p.id == playerToSkip);
      if (nextPlayerIndex == indexToSkip) {
        nextPlayerIndex = (nextPlayerIndex + 1) % players.length;
      }
    }
    players[nextPlayerIndex].myTurn = true;
    currentPlayer = players.firstWhere((p) => p.id == currentPlayer!.id);
    if (currentPlayer!.onTeamA) {
      teamA.madeIt = true;
    } else {
      teamB.madeIt = true;
    }
    setState(() {});
    handCards = sortHand(currentPlayer!.hand, suit);

    // handCards.clear();
    // handCards.addAll(currentPlayer!.hand);
    // handController.updateHand(handCards);
    setState(() {});
    connectionService.broadcastMessage({
      'type': 'chose_trump_suit',
      'suit': suit.toString(),
      'goingAlone': goingAlone,
      'playerToSkip': playerToSkip,
      'playerId': currentPlayer!.id,
    }, currentPlayer!.id);
    if (players[nextPlayerIndex].isBot) {
      final bot = bots.firstWhere((b) => b.id == players[nextPlayerIndex].id);
      Future.delayed(Duration(seconds: 1), () {
        bot.playCard([], null, players);
      });
    }
  }

  Future<bool> askIfGoingAlone() async {
    bool? result = await showDialog<bool>(
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
                    "Do you want to go alone?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ActionButton(
                        height: 40,
                        width: 100,
                        onTap: () {
                          Navigator.of(context).pop(false);
                        },
                        text: Text(
                          "No",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      ActionButton(
                        height: 40,
                        width: 100,
                        onTap: () {
                          Navigator.of(context).pop(true);
                        },
                        text: Text(
                          "Yes",
                          style: TextStyle(color: Colors.white, fontSize: 16),
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
    return result ?? false;
  }

  Widget buildPlayingScreen(
    double calculatedScale,
    BuildContext context,
    double handScale,
  ) {
    print("Up Card: ${deckCards.last.value} of ${deckCards.last.suit}");
    CardSuit upCardSuit = deckCards.last.suit;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Positioned(
            top: 0 * calculatedScale,
            left: 0 * calculatedScale,
            child: SizedBox(
              width: 130 * calculatedScale,
              child: FancyBorder(
                borderWidth: players[1].myTurn ? 2 : 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      players[1].name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * calculatedScale,
                      ),
                    ),
                    if (!someonesGoneAlone || players[1].id != playerToSkip)
                      Hand(
                        handCards: players[1].hand,
                        currentDragData: currentDragData,
                        onDragCompleted: () {},
                        onDragStarted: (d) {},
                        onDragEnd: () {},
                        scale: 0.2,
                        onTapBlitz: () {},
                        myHand: false,
                      ),
                    if (players[1].isDealer &&
                        gamePhase != EuchreGamePhase.playing)
                      EuchreDeck(
                        euchreDeck: deckCards,
                        scale: 0.35,
                        showTopCard: !upCardTurnedDown,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0 * calculatedScale,
            left:
                (MediaQuery.of(context).size.width - 16) / 2 -
                (120 * calculatedScale) / 2,
            child: SizedBox(
              width: 120 * calculatedScale,
              child: FancyBorder(
                borderWidth: players[2].myTurn ? 2 : 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      players[2].name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * calculatedScale,
                      ),
                    ),
                    if (!someonesGoneAlone || players[2].id != playerToSkip)
                      Hand(
                        handCards: players[2].hand,
                        currentDragData: currentDragData,
                        onDragCompleted: () {},
                        onDragStarted: (d) {},
                        onDragEnd: () {},
                        scale: 0.2,
                        onTapBlitz: () {},
                        myHand: false,
                      ),
                    if (players[2].isDealer &&
                        gamePhase != EuchreGamePhase.playing)
                      EuchreDeck(
                        euchreDeck: deckCards,
                        scale: 0.35,
                        showTopCard: !upCardTurnedDown,
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0 * calculatedScale,
            right: 0 * calculatedScale,
            child: SizedBox(
              width: 120 * calculatedScale,
              child: FancyBorder(
                borderWidth: players[3].myTurn ? 2 : 0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: double.infinity),
                    Text(
                      players[3].name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16 * calculatedScale,
                      ),
                    ),
                    if (!someonesGoneAlone || players[3].id != playerToSkip)
                      Hand(
                        handCards: players[3].hand,
                        currentDragData: currentDragData,
                        onDragCompleted: () {},
                        onDragStarted: (d) {},
                        onDragEnd: () {},
                        scale: 0.2,
                        onTapBlitz: () {},
                        myHand: false,
                      ),
                    if (players[3].isDealer &&
                        gamePhase != EuchreGamePhase.playing)
                      EuchreDeck(
                        euchreDeck: deckCards,
                        scale: 0.35,
                        showTopCard: !upCardTurnedDown,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Top Container (100px)
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
          if ((currentPlayer!.myTurn && gamePhase == EuchreGamePhase.playing) ||
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
                    players[0].myTurn && gamePhase == EuchreGamePhase.playing,
                onTapCard:
                    gamePhase == EuchreGamePhase.discardingCard &&
                            currentPlayer!.isDealer
                        ? selectCardToDiscard
                        : null,
                isCardPlayable:
                    players[0].myTurn && gamePhase == EuchreGamePhase.playing
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
      if (gamePhase != EuchreGamePhase.playing)
        Positioned(
          bottom:
              150 * handScale +
              (currentPlayer!.myTurn ||
                      gamePhase == EuchreGamePhase.discardingCard
                  ? (50 * handScale) + (32 * handScale)
                  : (24 * handScale)),
          left: 32,
          child: FancyBorder(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Score",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                    ),
                  ),
                  Container(
                    height: 1,
                    width: 100 * calculatedScale,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [styling.primary, styling.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * handScale),
                  Text(
                    "Team A: ${teamA.score}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                      fontWeight:
                          currentPlayer!.onTeamA
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4 * handScale),
                  Text(
                    "Team B: ${teamB.score}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                      fontWeight:
                          !currentPlayer!.onTeamA
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (gamePhase == EuchreGamePhase.playing)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          left: 32,
          child: FancyBorder(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Tricks",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                    ),
                  ),
                  Container(
                    height: 1,
                    width: 100 * calculatedScale,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [styling.primary, styling.secondary],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                  SizedBox(height: 2 * handScale),
                  Text(
                    "Team A: ${teamA.tricksTaken}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                      fontWeight:
                          currentPlayer!.onTeamA
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4 * handScale),
                  Text(
                    "Team B: ${teamB.tricksTaken}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                      fontWeight:
                          !currentPlayer!.onTeamA
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      if (gamePhase == EuchreGamePhase.playing)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          right: 40,
          child: FancyBorder(
            isFilled: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Trump",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                    ),
                  ),
                  Text(
                    trumpSuit != null ? trumpSuit!.toIcon() : "",
                    style: TextStyle(
                      color:
                          trumpSuit == CardSuit.hearts ||
                                  trumpSuit == CardSuit.diamonds
                              ? Colors.red
                              : Colors.black,
                      fontSize: 24 * calculatedScale,
                    ),
                  ),
                  Text(
                    "Made by:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 * calculatedScale,
                    ),
                  ),
                  Text(
                    teamA.madeIt ? "Team A" : "Team B",
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
      if (currentPlayer!.isDealer && gamePhase != EuchreGamePhase.playing)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          left: MediaQuery.of(context).size.width - 120,
          child: EuchreDeck(
            euchreDeck: deckCards,
            scale: 0.6,
            showTopCard: !upCardTurnedDown,
          ),
        ),
      if (currentPlayer!.myTurn && gamePhase == EuchreGamePhase.decidingTrump)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          left: 32,

          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!upCardTurnedDown)
                SizedBox(
                  width: 100 * handScale,
                  height: 50 * handScale,
                  child: ActionButton(
                    text: Text(
                      currentPlayer!.isDealer ? "Pick Up" : "Order Up",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () async {
                      bool goingAlone = await askIfGoingAlone();
                      if (goingAlone) {
                        someonesGoneAlone = true;
                        playerToSkip =
                            players
                                .firstWhere(
                                  (p) =>
                                      p.id != currentPlayer!.id &&
                                      p.onTeamA == currentPlayer!.onTeamA,
                                )
                                .id;
                      }
                      trumpSuit = upCardSuit;
                      for (var bot in bots) {
                        bot.trumpSuit = upCardSuit;
                      }
                      //set turn to be next player after dealer
                      currentPlayer!.myTurn = false;
                      players[0].myTurn = false;
                      final dealerIndex = players.indexOf(
                        players.firstWhere((p) => p.isDealer),
                      );
                      players[dealerIndex].hand.add(deckCards.last);
                      int nextPlayerIndex = (dealerIndex + 1) % players.length;
                      if (goingAlone) {
                        int indexToSkip = players.indexWhere(
                          (p) => p.id == playerToSkip,
                        );
                        if (nextPlayerIndex == indexToSkip) {
                          nextPlayerIndex =
                              (nextPlayerIndex + 1) % players.length;
                        }
                      }
                      players[nextPlayerIndex].myTurn = true;
                      currentPlayer = players.firstWhere(
                        (p) => p.id == currentPlayer!.id,
                      );
                      upCardTurnedDown = true;
                      gamePhase = EuchreGamePhase.discardingCard;
                      if (currentPlayer!.onTeamA) {
                        teamA.madeIt = true;
                      } else {
                        teamB.madeIt = true;
                      }
                      handCards = sortHand(currentPlayer!.hand, upCardSuit);
                      setState(() {});

                      // handCards.clear();
                      // handCards.addAll(currentPlayer!.hand);
                      // handController.updateHand(handCards);

                      connectionService.broadcastMessage({
                        'type': 'up_card_picked',
                        'goingAlone': goingAlone,
                        'playerToSkip': playerToSkip,
                        'playerId': currentPlayer!.id,
                      }, currentPlayer!.id);
                      if (players[dealerIndex].isBot) {
                        final bot = bots.firstWhere(
                          (b) => b.id == players[dealerIndex].id,
                        );
                        Future.delayed(Duration(seconds: 1), () {
                          bot.discardCard();
                        });
                      }
                    },
                  ),
                ),

              if (upCardTurnedDown && upCardSuit != CardSuit.hearts)
                ActionButton(
                  width: 50 * handScale,
                  height: 50 * handScale,
                  useFancyText: false,
                  text: Text(
                    "♥",
                    style: TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.left,
                  ),
                  onTap: () {
                    chooseTrumpSuit(CardSuit.hearts);
                  },
                ),
              if (upCardTurnedDown && upCardSuit != CardSuit.diamonds)
                SizedBox(width: 8 * handScale),
              if (upCardTurnedDown && upCardSuit != CardSuit.diamonds)
                ActionButton(
                  width: 50 * handScale,
                  height: 50 * handScale,
                  useFancyText: false,
                  text: Text(
                    "♦",
                    style: TextStyle(fontSize: 14, color: Colors.red),
                    textAlign: TextAlign.left,
                  ),
                  onTap: () {
                    chooseTrumpSuit(CardSuit.diamonds);
                  },
                ),
              if (upCardTurnedDown && upCardSuit != CardSuit.clubs)
                SizedBox(width: 8 * handScale),
              if (upCardTurnedDown && upCardSuit != CardSuit.clubs)
                ActionButton(
                  width: 50 * handScale,
                  height: 50 * handScale,
                  useFancyText: false,
                  text: Text(
                    "♣",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.left,
                  ),
                  onTap: () {
                    chooseTrumpSuit(CardSuit.clubs);
                  },
                ),
              if (upCardTurnedDown && upCardSuit != CardSuit.spades)
                SizedBox(width: 8 * handScale),
              if (upCardTurnedDown && upCardSuit != CardSuit.spades)
                ActionButton(
                  width: 50 * handScale,
                  height: 50 * handScale,
                  useFancyText: false,
                  text: Text(
                    "♠",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.left,
                  ),
                  onTap: () {
                    chooseTrumpSuit(CardSuit.spades);
                  },
                ),
              if (!upCardTurnedDown ||
                  (upCardTurnedDown && !players[0].isDealer))
                SizedBox(width: 8 * handScale),
              if (!upCardTurnedDown ||
                  (upCardTurnedDown && !players[0].isDealer))
                SizedBox(
                  width: 100 * handScale,
                  height: 50 * handScale,
                  child: ActionButton(
                    text: Text(
                      "Pass",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      if (currentPlayer!.isDealer) {
                        setState(() {
                          upCardTurnedDown = true;
                          players[1].myTurn = true;
                          players[0].myTurn = false;
                          currentPlayer!.myTurn = false;
                        });
                      } else {
                        // Handle pass for non-dealers
                        print("Non-dealer player passed");
                        setState(() {
                          players[1].myTurn = true;
                          players[0].myTurn = false;
                          currentPlayer!.myTurn = false;
                        });
                      }
                      connectionService.broadcastMessage({
                        'type': 'player_passed',
                        'playerId': currentPlayer!.id,
                      }, currentPlayer!.id);
                      if (players[1].isBot) {
                        final bot = bots.firstWhere(
                          (b) => b.id == players[1].id,
                        );
                        Future.delayed(Duration(seconds: 1), () {
                          bot.decideTrump(
                            upCardTurnedDown
                                ? CardSuit.values
                                    .where((s) => s != upCardSuit)
                                    .toList()
                                : [upCardSuit],
                            upCardTurnedDown ? players[1].isDealer : false,
                            upCardTurnedDown ? null : deckCards.last,
                            players,
                          );
                        });
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      if (!currentPlayer!.isDealer &&
          gamePhase == EuchreGamePhase.discardingCard)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          left: 32,

          child: FancyWidget(
            child: Text(
              "Waiting for dealer to discard a card...",
              style: TextStyle(color: Colors.white, fontSize: 16 * handScale),
            ),
          ),
        ),
      if (currentPlayer!.isDealer &&
          gamePhase == EuchreGamePhase.discardingCard)
        Positioned(
          bottom: 150 * handScale + (24 * handScale),
          left: 32,

          child: FancyWidget(
            child: Text(
              "Tap on a card to discard it",
              style: TextStyle(color: Colors.white, fontSize: 16 * handScale),
            ),
          ),
        ),
    ];
  }

  Widget buildTeamSelectionScreen(
    double calculatedScale,
    BuildContext context,
  ) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children:
            currentPlayer == null
                ? [
                  SizedBox(height: 32),
                  FancyBorder(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Loading...",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                ]
                : [
                  SizedBox(height: 32),
                  FancyBorder(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Select Your Team",
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FancyBorder(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 140),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Team A",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              width: 140,
                              height: 3,

                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [styling.primary, styling.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 8),
                            ...teamA.players.map(
                              (player) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  player.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (teamA.players.length < 2 &&
                                teamA.players.every(
                                  (p) => p.id != currentPlayer!.id,
                                ))
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ActionButton(
                                  width: 120,

                                  text: Text(
                                    teamB.players.any(
                                          (p) => p.id == currentPlayer!.id,
                                        )
                                        ? "Switch to Team A"
                                        : "Join Team A",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      currentPlayer!.onTeamA = true;
                                      teamA.players.add(currentPlayer!);
                                      teamB.players.removeWhere(
                                        (p) => p.id == currentPlayer!.id,
                                      );
                                      connectionService.broadcastMessage({
                                        'type': 'team_selection',
                                        'team':
                                            currentPlayer!.onTeamA ? 'A' : 'B',
                                        'playerId': currentPlayer!.id,
                                      }, currentPlayer!.id);
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 32),
                      FancyBorder(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 140),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "Team B",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              width: 140,
                              height: 3,

                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [styling.primary, styling.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 8),
                            ...teamB.players.map(
                              (player) => Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  player.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            if (teamB.players.length < 2 &&
                                teamB.players.every(
                                  (p) => p.id != currentPlayer!.id,
                                ))
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ActionButton(
                                  width: 120,

                                  text: Text(
                                    teamA.players.any(
                                          (p) => p.id == currentPlayer!.id,
                                        )
                                        ? "Switch to Team B"
                                        : "Join Team B",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      currentPlayer!.onTeamA = false;
                                      teamB.players.add(currentPlayer!);
                                      teamA.players.removeWhere(
                                        (p) => p.id == currentPlayer!.id,
                                      );
                                      connectionService.broadcastMessage({
                                        'type': 'team_selection',
                                        'team':
                                            currentPlayer!.onTeamA ? 'A' : 'B',
                                        'playerId': currentPlayer!.id,
                                      }, currentPlayer!.id);
                                    });
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  if (bots.isNotEmpty && currentPlayer!.getIsHost())
                    FancyBorder(
                      child: SizedBox(
                        width: 200,

                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Text(
                                "Choose Bot Teams",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            Container(
                              height: 2.0,

                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [styling.primary, styling.secondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                            ),
                            for (var bot in bots)
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        "${bot.name}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    if (currentPlayer!.getIsHost())
                                      SizedBox(
                                        width: 110,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (teamA.players.every(
                                                  (p) => p.id != bot.id,
                                                ) &&
                                                teamA.players.length < 2 &&
                                                teamB.players.any(
                                                  (p) => p.id == bot.id,
                                                ))
                                              ActionButton(
                                                width: 60,
                                                height: 40,
                                                text: Text(
                                                  "Switch to Team A",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    bot.onTeamA = true;
                                                    teamA.players.add(
                                                      players.firstWhere(
                                                        (p) => p.id == bot.id,
                                                      ),
                                                    );
                                                    teamB.players.removeWhere(
                                                      (p) => p.id == bot.id,
                                                    );
                                                    players[players.indexWhere(
                                                          (p) => p.id == bot.id,
                                                        )]
                                                        .onTeamA = true;
                                                    bots
                                                        .firstWhere(
                                                          (p) => p.id == bot.id,
                                                        )
                                                        .onTeamA = true;

                                                    connectionService
                                                        .broadcastMessage({
                                                          'type':
                                                              'team_selection',
                                                          'team': 'A',
                                                          'playerId': bot.id,
                                                        }, currentPlayer!.id);
                                                  });
                                                },
                                              ),
                                            if (teamB.players.every(
                                                  (p) => p.id != bot.id,
                                                ) &&
                                                teamB.players.length < 2 &&
                                                teamA.players.any(
                                                  (p) => p.id == bot.id,
                                                ))
                                              ActionButton(
                                                width: 60,
                                                height: 40,
                                                text: Text(
                                                  "Switch to Team B",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    bot.onTeamA = false;
                                                    teamB.players.add(
                                                      players.firstWhere(
                                                        (p) => p.id == bot.id,
                                                      ),
                                                    );
                                                    teamA.players.removeWhere(
                                                      (p) => p.id == bot.id,
                                                    );
                                                    players[players.indexWhere(
                                                          (p) => p.id == bot.id,
                                                        )]
                                                        .onTeamA = false;
                                                    bots
                                                        .firstWhere(
                                                          (p) => p.id == bot.id,
                                                        )
                                                        .onTeamA = false;

                                                    connectionService
                                                        .broadcastMessage({
                                                          'type':
                                                              'team_selection',
                                                          'team': 'B',
                                                          'playerId': bot.id,
                                                        }, currentPlayer!.id);
                                                  });
                                                },
                                              ),
                                            if (teamA.players.length < 2 &&
                                                teamA.players.every(
                                                  (p) => p.id != bot.id,
                                                ) &&
                                                teamB.players.every(
                                                  (p) => p.id != bot.id,
                                                ))
                                              ActionButton(
                                                width: 50,
                                                height: 30,
                                                text: Text(
                                                  "Team A",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    bot.onTeamA = true;
                                                    teamA.players.add(
                                                      players.firstWhere(
                                                        (p) => p.id == bot.id,
                                                      ),
                                                    );
                                                    players[players.indexWhere(
                                                          (p) => p.id == bot.id,
                                                        )]
                                                        .onTeamA = true;
                                                    bots
                                                        .firstWhere(
                                                          (p) => p.id == bot.id,
                                                        )
                                                        .onTeamA = true;

                                                    connectionService
                                                        .broadcastMessage({
                                                          'type':
                                                              'team_selection',
                                                          'team': 'A',
                                                          'playerId': bot.id,
                                                        }, currentPlayer!.id);
                                                  });
                                                },
                                              ),
                                            SizedBox(width: 8),
                                            if (teamB.players.length < 2 &&
                                                teamB.players.every(
                                                  (p) => p.id != bot.id,
                                                ) &&
                                                teamA.players.every(
                                                  (p) => p.id != bot.id,
                                                ))
                                              ActionButton(
                                                width: 50,
                                                height: 30,
                                                text: Text(
                                                  "Team B",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    bot.onTeamA = false;
                                                    teamB.players.add(
                                                      players.firstWhere(
                                                        (p) => p.id == bot.id,
                                                      ),
                                                    );
                                                    players[players.indexWhere(
                                                          (p) => p.id == bot.id,
                                                        )]
                                                        .onTeamA = false;
                                                    bots
                                                        .firstWhere(
                                                          (p) => p.id == bot.id,
                                                        )
                                                        .onTeamA = false;

                                                    connectionService
                                                        .broadcastMessage({
                                                          'type':
                                                              'team_selection',
                                                          'team': 'B',
                                                          'playerId': bot.id,
                                                        }, currentPlayer!.id);
                                                  });
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (currentPlayer!.getIsHost()) SizedBox(height: 32),
                  if (currentPlayer!.getIsHost() &&
                      teamA.players.length >= 2 &&
                      teamB.players.length >= 2)
                    ActionButton(
                      text: Text(
                        "Start Game",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onTap: () {
                        //random int from 0 to 3
                        int dealerPlayerIndex = math.Random().nextInt(
                          players.length,
                        );
                        int startingPlayerIndex = dealerPlayerIndex + 1;
                        if (startingPlayerIndex >= players.length) {
                          startingPlayerIndex = 0;
                        }
                        playOrder = generatePlayOrder();
                        print("Play order: $playOrder");
                        //sort players based on play order but keep the current player at the start
                        players.sort((a, b) {
                          return playOrder
                              .indexOf(a.id)
                              .compareTo(playOrder.indexOf(b.id));
                        });
                        //rotate the players so that the current player is first
                        players = [
                          ...players.skipWhile(
                            (p) => p.id != currentPlayer!.id,
                          ),
                          ...players.takeWhile(
                            (p) => p.id != currentPlayer!.id,
                          ),
                        ];
                        dropZones.sort((a, b) {
                          final aIndex = players.indexWhere(
                            (p) => p.id == a.id,
                          );
                          final bIndex = players.indexWhere(
                            (p) => p.id == b.id,
                          );
                          return aIndex.compareTo(bIndex);
                        });
                        players[dealerPlayerIndex].isDealer = true;

                        players[startingPlayerIndex].myTurn = true;
                        print(
                          "Players after sorting: ${players.map((p) => p.name)}",
                        );

                        gameState = EuchreGameState.playing;
                        setState(() {});
                        List<CardData> shuffledDeck = [...fullEuchreDeck];
                        print("Shuffled deck: ${shuffledDeck.length}");
                        shuffledDeck.shuffle();

                        handCards = shuffledDeck.sublist(0, 5);
                        shuffledDeck.removeRange(0, 5);
                        currentPlayer!.hand = [...handCards];
                        players.forEach((player) {
                          if (player.id != currentPlayer!.id) {
                            player.hand = shuffledDeck.sublist(0, 5);
                            shuffledDeck.removeRange(0, 5);
                          } else {
                            player.hand = [...handCards];
                          }
                        });

                        // Initialize deck cards
                        deckCards = [...shuffledDeck];
                        handCards = sortHand(currentPlayer!.hand, null);
                        setState(() {});

                        connectionService.broadcastMessage({
                          'type': 'game_started',
                          'teamA': teamA.toMap(),
                          'teamB': teamB.toMap(),
                          'deckCards': deckCards.map((c) => c.toMap()).toList(),
                          'players': players.map((p) => p.toMap()).toList(),
                          'playOrder': playOrder.join(','),
                          'dealerId': players[dealerPlayerIndex].id,
                          'startingPlayerId': players[startingPlayerIndex].id,
                        }, currentPlayer!.id);

                        if (players[startingPlayerIndex].isBot) {
                          Future.delayed(const Duration(seconds: 1), () {
                            bots
                                .firstWhere(
                                  (b) =>
                                      b.id == players[startingPlayerIndex].id,
                                )
                                .decideTrump(
                                  [deckCards.last.suit],
                                  false,
                                  deckCards.last,
                                  players,
                                );
                          });
                        }
                        // Notify all players that the game has started
                      },
                    )
                  else if (currentPlayer!.getIsHost())
                    FancyWidget(
                      child: Text(
                        "Waiting for teams to be selected...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  else
                    FancyWidget(
                      child: Text(
                        "Waiting for host to start the game...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                ],
      ),
    );
  }

  Widget buildGameOverScreen() {
    // Sort players by score
    List<EuchrePlayer> winners =
        teamA.score >= 10 ? teamA.players : teamB.players;
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
          "Winners: ${winners[0].name} and ${winners[1].name}",
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
                Text(
                  "Team A: ${teamA.score}",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  "Team B: ${teamB.score}",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
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
                      (context) => Euchre(
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
