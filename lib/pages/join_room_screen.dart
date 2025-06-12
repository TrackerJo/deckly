import 'dart:async';

import 'dart:io';

import 'package:deckly/api/connection_service.dart' as blue;
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/dutch_blitz.dart';
import 'package:deckly/pages/euchre.dart';
import 'package:deckly/pages/nertz.dart';

import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/gradient_input_field.dart';

import 'package:flutter/material.dart';
import 'package:flutter_sficon/flutter_sficon.dart';

import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:deckly/api/connection_service.dart' as blue;

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});
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

  Game? game;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _initSubscriptions();
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
          case Game.blitz:
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
          default:
            // Handle other game types if needed
            break;
        }
      } else if (data['type'] == 'game_type') {
        game = Game.fromString(data['game_type']);
        setState(() {});
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

  Future<void> requestAndroidPermissions() async {
    bool locationIsGranted = await Permission.location.isGranted;
    // Check Permission
    if (!locationIsGranted) {
      await Permission.location.request();
    } // Ask

    // Check Location Status
    bool locationSeriveEnabled =
        await Permission.location.serviceStatus.isEnabled;
    if (!locationSeriveEnabled) {
      // If location service is not enabled, request it
      await Location().requestService();
    }

    bool stoargeIsGranted = await Permission.storage.isGranted;
    if (!stoargeIsGranted) {
      // Check Permission
      await Permission.storage.request(); // Ask
    }
    // Bluetooth permissions
    bool granted =
        !(await Future.wait([
          // Check Permissions
          Permission.bluetooth.isGranted,
          Permission.bluetoothAdvertise.isGranted,
          Permission.bluetoothConnect.isGranted,
          Permission.bluetoothScan.isGranted,
        ])).any((element) => false);
    [
      // Ask Permissions
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    // Check Bluetooth Status
    bool nearbyWifiDevicesIsGranted =
        await Permission.nearbyWifiDevices.isGranted;
    if (!nearbyWifiDevicesIsGranted) {
      // Android 12+
      await Permission.nearbyWifiDevices.request();
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.length != 4 || _nameCtrl.text.isEmpty) return;

    final roomCode = _codeCtrl.text;

    // Android permissions
    if (Platform.isAndroid) {
      await [Permission.locationWhenInUse].request();
      await requestAndroidPermissions();
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

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: game == null ? "Join Game" : game!.toString(),
          showBackButton: true,
          onBackButtonPressed: (context) {
            Navigator.pop(context);
          },
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
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Players:',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
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
                        decoration: styling.gradientInputDecoration().copyWith(
                          hintText: 'Enter 4-digit code',
                        ),
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
                        decoration: styling.gradientInputDecoration().copyWith(
                          hintText: 'Enter your name',
                        ),
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
                      child: ActionButton(
                        onTap:
                            !_initialized &&
                                    _connectionState ==
                                        blue.ConnectionState.disconnected
                                ? _joinRoom
                                : () {},
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
                      ),
                    ),
                  ],
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
        return _initialized ? 'Scanning...' : 'Join Game';
    }
  }
}
