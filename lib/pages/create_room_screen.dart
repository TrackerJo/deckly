import 'dart:async';
import 'dart:io';

import 'dart:math';

import 'package:deckly/api/connection_service.dart' as blue;
import 'package:deckly/api/connection_service.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/pages/crazy_eights.dart';
import 'package:deckly/pages/dutch_blitz.dart';
import 'package:deckly/pages/euchre.dart';
import 'package:deckly/pages/kalamattack.dart';
import 'package:deckly/pages/nertz.dart';
import 'package:deckly/pages/nertz.dart';
import 'package:deckly/pages/oh_hell.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';

import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/orientation_checker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';
import 'package:permission_handler/permission_handler.dart'
    as permissionHandler;

class CreateRoomScreen extends StatefulWidget {
  final Game game;
  final int? maxPlayers;
  final int? minPlayers;
  final int? requiredPlayers;
  final bool isOnline;
  const CreateRoomScreen({
    super.key,
    required this.userName,
    required this.game,
    this.maxPlayers,
    this.minPlayers,
    this.requiredPlayers,
    this.isOnline = false,
  });
  final String userName;
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  late StreamSubscription<List<GamePlayer>> _playersSubscription;
  late StreamSubscription<blue.ConnectionState> _stateSubscription;

  List<GamePlayer> _players = [];
  bool loading = false;

  void initConnection() async {
    connectionService.maxPlayerCount =
        widget.maxPlayers ?? widget.requiredPlayers;
    print("TEST");
    print(
      "Has allowed permissions: ${await connectionService.allowedAllPermissions()}",
    );

    bool firstUse = await SharedPrefs.getFirstUse();
    if (firstUse) {
      if (Platform.isIOS) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: Colors.transparent,

                  child: Container(
                    width: 400,

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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Important! Permission Required!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "After this dialog, you will be prompted to allow local network permissions. Please allow this permission to allow other players to join your game, this is required for the app to work!",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (loading)
                                CircularProgressIndicator(color: Colors.white)
                              else
                                ActionButton(
                                  height: 50,
                                  width: 200,
                                  onTap: () async {
                                    setState(() {
                                      loading = true;
                                    });
                                    await SharedPrefs.setFirstUse(false);
                                    await connectionService
                                        .requestPermissions();
                                    Navigator.of(context).pop();

                                    _initSubscriptions();

                                    _initService();
                                  },
                                  text: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "Okay",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
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
        );
      } else {
        await SharedPrefs.setFirstUse(false);
        await connectionService.requestPermissions();

        _initSubscriptions();

        _initService();
      }
    } else {
      await connectionService.requestPermissions();
      _initSubscriptions();

      _initService();
    }
  }

  @override
  void initState() {
    connectionService.isOnline = widget.isOnline;
    super.initState();
    initConnection();
  }

  void _initSubscriptions() {
    _playersSubscription = connectionService.playersStream.listen((players) {
      setState(() {
        _players = players;
      });
    });
    _stateSubscription = connectionService.connectionStateStream.listen(
      (state) {},
    );
  }

  Future<void> _initService() async {
    await connectionService.initAsHost(widget.userName, widget.game);
  }

  @override
  void dispose() {
    _playersSubscription.cancel();
    _stateSubscription.cancel();

    super.dispose();
  }

  void _startGame() async {
    for (var bot in _players.where((p) => p.isBot)) {
      analytics.logPlayWithBotEvent(
        widget.game.toString(),
        (bot as BotPlayer).difficulty.toString(),
      );
    }
    await connectionService.startGame();
    switch (widget.game) {
      case Game.dash:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => DutchBlitz(
                  players: _players,
                  player: _players.firstWhere((p) => p.isHost),
                ),
          ),
        );
        break;
      case Game.nertz:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => Nertz(
                  players: _players,
                  player: _players.firstWhere((p) => p.isHost),
                ),
          ),
        );
        break;
      case Game.euchre:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => Euchre(
                  players: _players,
                  player: _players.firstWhere((p) => p.isHost),
                ),
          ),
        );
        break;
      case Game.crazyEights:
        // Handle Crazy Eights game type if needed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => CrazyEights(
                  players: _players,
                  player: _players.firstWhere((p) => p.isHost),
                ),
          ),
        );

        break;
      case Game.kalamattack:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => Kalamattack(
                  players: _players,
                  player: _players.firstWhere((p) => p.isHost),
                ),
          ),
        );
        break;
      case Game.ohHell:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => OhHell(
                  players: _players,
                  player: _players.firstWhere((p) => p.isHost),
                ),
          ),
        );
        break;
      default:
        // Handle other game types if needed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    print("PLAYERS: $_players");
    print("REQUIRED: ${widget.requiredPlayers}");
    print(
      "CAN START: ${(widget.requiredPlayers != null ? (_players.length < widget.requiredPlayers!) : false)}",
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool allowedAllowed = await connectionService.allowedAllPermissions();
      bool firstUse = await SharedPrefs.getFirstUse();
      if (!allowedAllowed && !firstUse) {
        await connectionService.requestPermissions();
        if (Platform.isIOS) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Dialog(
                backgroundColor: Colors.transparent,

                child: Container(
                  width: 400,

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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Important! Permissions Required!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Please enable local network and bluetooth permissions in settings to allow other players to join your game.",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ActionButton(
                              height: 50,
                              width: 200,
                              onTap: () async {
                                Navigator.of(context).pop();
                                await permissionHandler.openAppSettings();
                              },
                              text: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Open Settings",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
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
        }
      }
    });
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && result == true) {
          connectionService.dispose();
        }
      },
      child: OrientationChecker(
        allowedOrientations: [
          Orientation.portrait,
          if (isTablet(context)) Orientation.landscape,
        ],
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: CustomAppBar(
              title: widget.game.toString(),
              showBackButton: true,
              onBackButtonPressed: (context) {
                Navigator.pop(context);
                connectionService.dispose();
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
                                  children:
                                      widget.game == Game.nertz
                                          ? nertzRules
                                          : widget.game == Game.dash
                                          ? dutchBlitzRules
                                          : widget.game == Game.euchre
                                          ? euchreRules
                                          : widget.game == Game.crazyEights
                                          ? crazy8Rules
                                          : widget.game == Game.kalamattack
                                          ? kalamatackRules
                                          : widget.game == Game.ohHell
                                          ? ohHellRules
                                          : [
                                            Text(
                                              'No rules available for this game.',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
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
            ),
          ),
          backgroundColor: styling.background,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                FancyBorder(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Game Code: ${connectionService.roomCode}',
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Text(
                  'Players${widget.minPlayers != null && widget.maxPlayers == null ? " (Min: ${widget.minPlayers})" : ""}${widget.requiredPlayers != null
                      ? " (${_players.length}/${widget.requiredPlayers})"
                      : widget.maxPlayers != null
                      ? " (${widget.minPlayers != null ? "Min: ${widget.minPlayers}, " : ""}Max: ${widget.maxPlayers})"
                      : ""}:',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: FancyBorder(
                    child: ListView(
                      children:
                          _players
                              .map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: Icon(
                                      p.isHost
                                          ? Icons.star
                                          : p.isBot
                                          ? Icons.computer
                                          : Icons.person,
                                      color:
                                          p.isHost
                                              ? Colors.yellow
                                              : Colors.white,
                                    ),
                                    title: Text(
                                      p.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    trailing:
                                        p is BotPlayer
                                            ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                SizedBox(
                                                  width: 110,
                                                  child: DropdownButtonFormField(
                                                    value:
                                                        p.difficulty.toString(),
                                                    decoration: styling
                                                        .textInputDecoration()
                                                        .copyWith(
                                                          fillColor:
                                                              styling.primary,
                                                        ),
                                                    dropdownColor:
                                                        styling.background,
                                                    iconEnabledColor:
                                                        styling.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    items:
                                                        [
                                                          "Easy",
                                                          "Medium",
                                                          "Hard",
                                                        ].map((String value) {
                                                          return DropdownMenuItem<
                                                            String
                                                          >(
                                                            value: value,
                                                            child: Text(
                                                              value,
                                                              style: const TextStyle(
                                                                color:
                                                                    Colors
                                                                        .white,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                    onTap: () async {
                                                      await SharedPrefs.hapticInputSelect();
                                                    },
                                                    onChanged: (
                                                      String? value,
                                                    ) async {
                                                      if (value == null) return;
                                                      await SharedPrefs.hapticButtonPress();
                                                      BotDifficulty difficulty =
                                                          BotDifficulty.fromString(
                                                            value,
                                                          );
                                                      connectionService
                                                          .updateBotDifficulty(
                                                            p.id,
                                                            difficulty,
                                                          );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () {
                                                    SharedPrefs.hapticButtonPress();
                                                    connectionService.removeBot(
                                                      p.id,
                                                    );
                                                  },
                                                  icon: Icon(
                                                    Icons.remove_circle,
                                                  ),
                                                  color: Colors.redAccent,
                                                ),
                                              ],
                                            )
                                            : null,
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.game != Game.kalamattack &&
                    (widget.maxPlayers == null ||
                        _players.length < widget.maxPlayers!) &&
                    (widget.requiredPlayers != null
                        ? _players.length < widget.requiredPlayers!
                        : true))
                  ActionButton(
                    text: Text(
                      "Add Bot",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      final botName =
                          'Bot ${(_players.where((p) => p.isBot)).length + 1}';
                      final botPlayer = BotPlayer(
                        id: 'bot-${Random().nextInt(10000)}',
                        name: botName,
                        difficulty: BotDifficulty.hard,
                      );
                      connectionService.addBot(botPlayer);
                    },
                  ),
                const SizedBox(height: 16),
                if (_players.length < 2 ||
                    (widget.requiredPlayers != null
                        ? (_players.length < widget.requiredPlayers!)
                        : false) ||
                    (widget.minPlayers != null &&
                        _players.length < widget.minPlayers!))
                  FancyWidget(
                    child: const Text(
                      'Waiting for more players to join...',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ActionButton(
                      onTap: _players.length >= 2 ? _startGame : null,
                      text: Text(
                        _players.length >= 2
                            ? 'Start Game'
                            : 'Waiting for players',
                        style: TextStyle(
                          color:
                              Colors
                                  .white, // This will be masked by the gradient
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
