// main.dart

import 'package:deckly/constants.dart';
import 'package:deckly/pages/create_room_screen.dart';
import 'package:deckly/pages/join_room_screen.dart';

import 'package:flutter/material.dart';

void main() => runApp(MyApp());

/// Simple model for a player

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deckly',
      theme: ThemeData(primarySwatch: Colors.purple),
      home: HomeScreen(),
    );
  }
}

/// Home chooses Create vs Join
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deckly Lobby')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Spacer(),
            ActionButton(
              color: Colors.green,
              label: 'Create Room',
              onTap:
                  () => showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      final myController = TextEditingController();
                      return AlertDialog(
                        title: Text("Enter Your Name"),
                        content: TextField(
                          controller: myController,

                          decoration: InputDecoration(hintText: "Your Name"),
                        ),
                        actions: [
                          TextButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text("Create Room"),
                            onPressed: () {
                              // Navigate to the browser screen with the room code
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => CreateRoomScreen(
                                        userName: myController.text,
                                      ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
            ),
            const SizedBox(height: 16),
            ActionButton(
              color: Colors.blue,
              label: 'Join Room',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JoinRoomScreen()),
                  ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
