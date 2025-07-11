import 'dart:async';

import 'dart:io';

import 'package:deckly/api/connection_service.dart' as blue;
import 'package:deckly/api/connection_service.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/crazy_eights.dart';
import 'package:deckly/pages/dutch_blitz.dart';
import 'package:deckly/pages/euchre.dart';
import 'package:deckly/pages/kalamattack.dart';
import 'package:deckly/pages/nertz.dart';
import 'package:deckly/pages/oh_hell.dart';

import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/gradient_input_field.dart';
import 'package:deckly/widgets/orientation_checker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:deckly/api/connection_service.dart' as blue;
import 'package:permission_handler/permission_handler.dart'
    as permissionHandler;

class JoinRoomScreen extends StatefulWidget {
  final bool isOnline;
  const JoinRoomScreen({super.key, this.isOnline = false});
  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late StreamSubscription<List<GamePlayer>> _playersSubscription;
  late StreamSubscription<blue.ConnectionState> _stateSubscription;
  late StreamSubscription<Map<String, dynamic>> _gameDataSubscription;
  List<GamePlayer> _players = [];
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  blue.ConnectionState _connectionState = blue.ConnectionState.disconnected;

  bool _initialized = false;
  bool joinedRoom = false;
  bool loading = false;

  Game? game;

  void initConnection() async {
    _initSubscriptions();
    connectionService.onCantFindRoom = () {
      if (!mounted) return;
      showSnackBar(
        context,
        Colors.red,
        "The game was not found. Make sure you have the correct room code.",
      );
      setState(() {
        _connectionState = blue.ConnectionState.disconnected;
      });
    };
    connectionService.onRoomFull = () {
      if (!mounted) return;
      showSnackBar(
        context,
        Colors.red,
        "The room is full. You cannot join this game.",
      );
      setState(() {
        _connectionState = blue.ConnectionState.disconnected;
      });
    };
  }

  @override
  void initState() {
    // TODO: implement initState
    connectionService.isOnline = widget.isOnline;
    super.initState();
    initConnection();

    SharedPrefs.getLastUsedName().then((name) {
      if (name.isEmpty) {
        return;
      }
      _nameCtrl.text = name;
      if (!mounted) return;
      setState(() {});
    });
  }

  void _initSubscriptions() {
    _playersSubscription = connectionService.playersStream.listen((players) {
      setState(() {
        _players = players;
      });
    });

    _stateSubscription = connectionService.connectionStateStream.listen((
      state,
    ) {
      setState(() {
        _connectionState = state;
      });
    });

    _gameDataSubscription = connectionService.gameDataStream.listen((data) {
      if (data['type'] == 'startGame') {
        switch (game) {
          case Game.dash:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DutchBlitz(
                      players: _players,
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
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
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
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
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
                    ),
              ),
            );
          case Game.crazyEights:
            // Handle Crazy Eights game type if needed
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => CrazyEights(
                      players: _players,
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
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
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
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
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
                    ),
              ),
            );
            break;
          default:
            // Handle other game types if needed
            break;
        }
      } else if (data['type'] == 'game_type') {
        game = Game.fromString(data['game_type']);
        setState(() {});
      } else if (data['type'] == 'host_left') {
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
                        "The host has left!",
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
    });
  }

  @override
  void dispose() {
    _playersSubscription.cancel();
    _stateSubscription.cancel();
    _gameDataSubscription.cancel();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleJoinButton() async {
    if (_codeCtrl.text.length != 4) {
      showSnackBar(
        context,
        Colors.red,
        "Please enter a valid 4-digit room code.",
      );
      return;
    }
    if (_nameCtrl.text.isEmpty) {
      showSnackBar(context, Colors.red, "Please enter your name.");
      return;
    }
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
                            "After this dialog, you will be prompted to allow local network permissions. Please allow this permission to allow the app to find the host of the game you are trying to join, this is required for the app to work!",
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
                                    await connectionService
                                        .requestPermissions();
                                    await SharedPrefs.setFirstUse(false);
                                    Navigator.of(context).pop();

                                    _joinRoom();
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
        _joinRoom();
      }
    } else {
      _joinRoom();
    }
  }

  Future<void> _joinRoom() async {
    final roomCode = _codeCtrl.text;

    // Android permissions

    await connectionService.requestPermissions();
    bool allowedAllowed = await connectionService.allowedAllPermissions();
    if (!allowedAllowed) {
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

    SharedPrefs.setLastUsedName(_nameCtrl.text);
    await connectionService.initAsClient(_nameCtrl.text, roomCode);

    setState(() => _initialized = true);
  }

  bool get _isReadyToJoin =>
      !_initialized && _codeCtrl.text.length == 4 && _nameCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isConnected = _connectionState == blue.ConnectionState.connected;

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
              title:
                  game == null
                      ? "Join ${widget.isOnline ? "Online" : "Local"} Game"
                      : game!.toString(),
              showBackButton: true,
              onBackButtonPressed: (context) {
                Navigator.pop(context);
                connectionService.dispose();
              },
              actions: [
                if (game != null)
                  IconButton(
                    icon: SFIcon(
                      SFIcons.sf_pencil_and_list_clipboard, // 'heart.fill'
                      // fontSize instead of size
                      fontWeight:
                          FontWeight.bold, // fontWeight instead of weight
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
                                height:
                                    MediaQuery.of(context).size.height * 0.8,
                                width: double.infinity,
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        game == Game.nertz
                                            ? nertzRules
                                            : game == Game.dash
                                            ? dutchBlitzRules
                                            : game == Game.euchre
                                            ? euchreRules
                                            : game == Game.crazyEights
                                            ? crazy8Rules
                                            : game == Game.kalamattack
                                            ? kalamatackRules
                                            : game == Game.ohHell
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
            child:
                isConnected
                    ? Column(
                      children: [
                        Text(
                          'You have joined the game!',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Players:',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: FancyBorder(
                            child: ListView(
                              children:
                                  _players
                                      .map(
                                        (p) => ListTile(
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
                                          subtitle:
                                              p.isBot && p is BotPlayer
                                                  ? Text(
                                                    'Bot Difficulty: ${p.difficulty.toString()}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  )
                                                  : null,
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GradientInputField(
                          textField: TextField(
                            controller: _codeCtrl,
                            decoration: styling
                                .gradientInputDecoration()
                                .copyWith(hintText: 'Enter 4-digit code'),
                            keyboardType: TextInputType.number,
                            cursorColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            maxLength: 4,
                            onTap: () {
                              SharedPrefs.hapticInputSelect();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        GradientInputField(
                          textField: TextField(
                            controller: _nameCtrl,
                            decoration: styling
                                .gradientInputDecoration()
                                .copyWith(hintText: 'Enter your name'),
                            cursorColor: Colors.white,
                            style: const TextStyle(color: Colors.white),
                            onTap: () {
                              SharedPrefs.hapticInputSelect();
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child:
                              _connectionState ==
                                      blue.ConnectionState.disconnected
                                  ? ActionButton(
                                    onTap: _handleJoinButton,
                                    text: Text(
                                      _getButtonText(),
                                      style: TextStyle(
                                        color:
                                            Colors
                                                .white, // This will be masked by the gradient
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                  : FancyWidget(
                                    child: Text(
                                      _getButtonText(),
                                      style: const TextStyle(
                                        color: Colors.white,
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

  String _getButtonText() {
    switch (_connectionState) {
      case blue.ConnectionState.connecting:
        return 'Connecting...';
      case blue.ConnectionState.connected:
        return 'Connected';
      case blue.ConnectionState.searching:
        return 'Searching for game...';
      default:
        return 'Join Game';
    }
  }
}
