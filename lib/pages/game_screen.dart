import 'package:deckly/constants.dart';
import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  final bool isHost;
  final String roomCode;
  final List<GamePlayer> players;

  const GameScreen({
    required this.isHost,
    required this.roomCode,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${isHost ? "Host" : "Player"} – Room $roomCode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Game started!', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text('Players in this room:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            ...players.map(
              (p) => ListTile(
                leading: Icon(p.isHost ? Icons.star : Icons.person),
                title: Text(p.name),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
