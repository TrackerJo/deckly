// main.dart

import 'package:deckly/constants.dart';

import 'package:deckly/pages/dutch_blitz.dart';

import 'package:deckly/pages/create_room_screen.dart';
import 'package:deckly/pages/home_screen.dart';
import 'package:deckly/pages/join_room_screen.dart';
import 'package:deckly/styling.dart';

import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';

final NearbyService nearbyService = NearbyService();
final Styling styling = Styling();

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
    try {
      nearbyService.stopAdvertisingPeer();
      nearbyService.stopBrowsingForPeers();
    } catch (e) {
      // ignore: avoid_print
      print('Error disposing NearbyService: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deckly',
      theme: ThemeData(primarySwatch: Colors.purple),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

/// Home chooses Create vs Join
