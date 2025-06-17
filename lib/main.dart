// main.dart

import 'dart:async';

import 'package:deckly/api/connection_service.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/pages/euchre.dart';
import 'package:deckly/pages/flip_page.dart';

import 'package:deckly/pages/home_screen.dart';
import 'package:deckly/pages/nertz.dart';
import 'package:deckly/pages/nertz.dart';

import 'package:deckly/styling.dart';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:nearby_connections/nearby_connections.dart';

final NearbyService nearbyService = NearbyService();
final Nearby androidNearby = Nearby();
final Styling styling = Styling();
final ConnectionService connectionService = ConnectionService();

final bluetoothDataStream = StreamController<Payload>.broadcast();
final bluetoothStateStream = StreamController.broadcast();

void main() => runApp(MyApp());

/// Simple model for a player

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    connectionService.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: MaterialApp(
        title: 'Deckly',
        theme: ThemeData(primarySwatch: Colors.purple),
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
        // home: NertzWithBot(
        //   player: GamePlayer(
        //     id: "Deckly-test-1704-host",
        //     name: "test",
        //     isHost: true,
        //   ),
        //   players: [
        //     GamePlayer(id: "Deckly-test-1704-host", name: "test", isHost: true),
        //     BotPlayer(
        //       id: "Deckly-test3-1704",
        //       name: "Test Bot",
        //       difficulty: BotDifficulty.hard,
        //     ),
        //     BotPlayer(
        //       id: "Deckly-test4-1704",
        //       name: "Test Bot 2",
        //       difficulty: BotDifficulty.hard,
        //     ),
        //   ],
        // ),
      ),
    );
  }
}

/// Home chooses Create vs Join
