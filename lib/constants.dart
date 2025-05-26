import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback onTap;
  const ActionButton({
    required this.color,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label, style: const TextStyle(fontSize: 18)),
        onPressed: onTap,
      ),
    );
  }
}

class GamePlayer {
  final String id;
  final String name;
  final bool isHost;

  GamePlayer({required this.id, required this.name, this.isHost = false});

  factory GamePlayer.fromMap(Map<String, dynamic> m) =>
      GamePlayer(id: m['id'], name: m['name'], isHost: m['isHost'] ?? false);

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'isHost': isHost};
}
