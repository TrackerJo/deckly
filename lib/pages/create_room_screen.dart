import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:deckly/api/connection_service.dart' as blue;
import 'package:deckly/pages/dutch_blitz.dart';
import 'package:deckly/pages/euchre.dart';
import 'package:deckly/pages/nertz.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';

import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/fancy_border.dart';

import 'package:flutter/material.dart';

import 'package:deckly/api/connection_service.dart' as blue;
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateRoomScreen extends StatefulWidget {
  final Game game;
  final int? maxPlayers;
  final int? minPlayers;
  final int? requiredPlayers;
  const CreateRoomScreen({
    super.key,
    required this.userName,
    required this.game,
    this.maxPlayers,
    this.minPlayers,
    this.requiredPlayers,
  });
  final String userName;
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  late StreamSubscription<List<GamePlayer>> _playersSubscription;
  late StreamSubscription<blue.ConnectionState> _stateSubscription;

  List<GamePlayer> _players = [];
  final String _roomCode = (1000 + Random().nextInt(9000)).toString();
  blue.ConnectionState _connectionState = blue.ConnectionState.disconnected;

  String _hostDeviceId = '';

  @override
  void initState() {
    super.initState();

    _initSubscriptions();

    _initService();
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
    await connectionService.startGame();
    switch (widget.game) {
      case Game.blitz:
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
      default:
        // Handle other game types if needed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: widget.game.toString(),
          showBackButton: true,
          onBackButtonPressed: (context) {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: styling.backgroundColor,
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

            const SizedBox(height: 24),
            Text(
              'Players${widget.requiredPlayers != null ? " (${_players.length}/${widget.requiredPlayers})" : ""}:',
              style: const TextStyle(fontSize: 24, color: Colors.white),
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
                                p.isHost ? Icons.star : Icons.person,
                                color: p.isHost ? Colors.yellow : Colors.white,
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_players.length < 2 &&
                (widget.requiredPlayers != null
                    ? _players.length < widget.requiredPlayers!
                    : true))
              FancyWidget(
                child: const Text(
                  'Waiting for more players to join...',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  onTap: _players.length >= 2 ? _startGame : null,
                  text: Text(
                    _players.length >= 2 ? 'Start Game' : 'Waiting for players',
                    style: TextStyle(
                      color:
                          Colors.white, // This will be masked by the gradient
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
}
