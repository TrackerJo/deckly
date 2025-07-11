import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:deckly/constants.dart';
import 'package:firebase_database/firebase_database.dart';

class Database {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<void> createRoom(GamePlayer player, String roomId, Game game) async {
    final roomRef = _database.ref('rooms/$roomId');
    await roomRef.set({
      'id': roomId,
      'messages': [],
      'players': [player.toMap()],
      'game': game.toString(),
    });
  }

  Future<GameJoinResult?> joinRoom(GamePlayer player, String roomId) async {
    final roomRef = _database.ref('rooms/$roomId');
    final snapshot = await roomRef.get();

    if (snapshot.exists) {
      final roomData = snapshot.value as Map<dynamic, dynamic>;
      final actions = roomData['messages'] as List<dynamic>? ?? [];
      final players = roomData['players'] ?? [];
      final game = Game.fromString(roomData['game']);
      List<dynamic> gamePlayers =
          players.map((p) => GamePlayer.fromMap(formatDatabaseMap(p))).toList();
      if (players.any((p) => p['id'] == player.id)) {
        return GameJoinResult(
          players: dynamicToGamePlayer(gamePlayers),
          game: game,
        ); // Player already in room
      }
      List<Map<String, dynamic>> newActions = [
        ...actions.map((a) => formatDatabaseMap(a)),
      ];
      // Add player to the room

      gamePlayers.add(player);
      String messageId = DateTime.now().millisecondsSinceEpoch.toString();
      //Add 10 random characters to the messageId in a random order
      for (int i = 0; i < 10; i++) {
        messageId += String.fromCharCode(97 + (Random().nextInt(26)));
      }
      newActions.add({
        'players': gamePlayers.map((p) => p.toMap()).toList(),
        'type': 'playerList',
        'id': messageId,
      });

      await roomRef.update({
        'players': gamePlayers.map((p) => p.toMap()).toList(),
        'messages': newActions,
      });
      return GameJoinResult(
        players: dynamicToGamePlayer(gamePlayers),
        game: game,
      );
    }
    return null;
  }

  Future<void> listenToRoom(
    String roomId,
    Function(Map<String, dynamic>) processGameData,
    String userId,
    StreamSubscription<dynamic>? _onlineSub,
    bool isHost,
  ) async {
    final roomRef = _database.ref('rooms/$roomId/messages');
    List<dynamic> oldMessages = [];
    final roomMessagesRef = _database.ref('rooms/$roomId/messages');
    final roomMessages = await roomMessagesRef.get();
    if (roomMessages.exists) {
      oldMessages.addAll(roomMessages.value as List);
    }
    _onlineSub = roomMessagesRef.onValue.listen((event) {
      print(event.snapshot.value);
      if (event.snapshot.value == null) {
        if (oldMessages.isNotEmpty && !isHost) {
          processGameData({"type": "host_left"});
        }
        return;
      }
      final data = event.snapshot.value as List;
      if (data.isNotEmpty) {
        final newMessages =
            data
                .where((msg) => !oldMessages.any((m) => m["id"] == msg["id"]))
                .toList();
        print("New messages length: ${newMessages.length}");
        print("New messages: $newMessages");
        print("Old messages length: ${oldMessages.length}");
        print("Old messages: $oldMessages");
        if (newMessages.isNotEmpty) {
          for (var message in newMessages) {
            oldMessages.add(message);

            if (message["sentBy"] == userId) continue;

            processGameData(formatDatabaseMap(message));
          }
        }
      }
    });
  }

  Future<void> sendMessage(
    Map<String, dynamic> message,
    String userId,
    String roomId,
  ) async {
    message["sentBy"] = userId;
    message["timestamp"] = DateTime.now().toIso8601String();
    // Generate a unique ID for the message
    String messageId = DateTime.now().millisecondsSinceEpoch.toString();
    //Add 10 random characters to the messageId in a random order
    for (int i = 0; i < 10; i++) {
      messageId += String.fromCharCode(97 + (Random().nextInt(26)));
    }
    message["id"] = messageId;
    final roomRef = _database.ref('rooms/$roomId');
    final roomMessagesRef = _database.ref('rooms/$roomId/messages');
    final roomMessages = await roomMessagesRef.get();
    final messages = roomMessages.value as List;
    List<dynamic> newMessages = [...messages];
    newMessages.add(message);
    await roomRef.update({"messages": newMessages});
  }

  Future<void> addBot(BotPlayer bot, String roomId) async {
    final roomRef = _database.ref('rooms/$roomId');
    final snapshot = await roomRef.get();
    final roomData = snapshot.value as Map<dynamic, dynamic>;
    final actions = roomData['messages'] as List<dynamic>? ?? [];
    final players = roomData['players'] ?? [];
    List<dynamic> gamePlayers =
        players.map((p) => GamePlayer.fromMap(formatDatabaseMap(p))).toList();
    gamePlayers.add(bot);
    List<Map<String, dynamic>> newActions = [
      ...actions.map((a) => formatDatabaseMap(a)),
    ];
    String messageId = DateTime.now().millisecondsSinceEpoch.toString();
    //Add 10 random characters to the messageId in a random order
    for (int i = 0; i < 10; i++) {
      messageId += String.fromCharCode(97 + (Random().nextInt(26)));
    }
    newActions.add({
      'players': gamePlayers.map((p) => p.toMap()).toList(),
      'type': 'playerList',
      'id': messageId,
    });
    await roomRef.update({
      'players': gamePlayers.map((p) => p.toMap()).toList(),
      'messages': newActions,
    });
  }

  Future<void> removeBot(String botId, String roomId) async {
    final roomRef = _database.ref('rooms/$roomId');
    final snapshot = await roomRef.get();
    final roomData = snapshot.value as Map<dynamic, dynamic>;
    final actions = roomData['messages'] as List<dynamic>? ?? [];
    final players = roomData['players'] ?? [];
    List<dynamic> gamePlayers =
        players.map((p) => GamePlayer.fromMap(formatDatabaseMap(p))).toList();
    gamePlayers.removeWhere((p) => p.id == botId);
    List<Map<String, dynamic>> newActions = [
      ...actions.map((a) => formatDatabaseMap(a)),
    ];
    String messageId = DateTime.now().millisecondsSinceEpoch.toString();
    //Add 10 random characters to the messageId in a random order
    for (int i = 0; i < 10; i++) {
      messageId += String.fromCharCode(97 + (Random().nextInt(26)));
    }
    newActions.add({
      'players': gamePlayers.map((p) => p.toMap()).toList(),
      'type': 'playerList',
      'id': messageId,
    });
    await roomRef.update({
      'players': gamePlayers.map((p) => p.toMap()).toList(),
      'messages': newActions,
    });
  }

  Future<void> updateBotDifficulty(
    String botId,
    BotDifficulty difficulty,
    String roomId,
  ) async {
    final roomRef = _database.ref('rooms/$roomId');
    final snapshot = await roomRef.get();
    final roomData = snapshot.value as Map<dynamic, dynamic>;
    final actions = roomData['messages'] as List<dynamic>? ?? [];
    final players = roomData['players'] ?? [];
    List<dynamic> gamePlayers =
        players.map((p) => GamePlayer.fromMap(formatDatabaseMap(p))).toList();
    gamePlayers.firstWhere((p) => p.id == botId).difficulty = difficulty;
    List<Map<String, dynamic>> newActions = [
      ...actions.map((a) => formatDatabaseMap(a)),
    ];
    String messageId = DateTime.now().millisecondsSinceEpoch.toString();
    //Add 10 random characters to the messageId in a random order
    for (int i = 0; i < 10; i++) {
      messageId += String.fromCharCode(97 + (Random().nextInt(26)));
    }
    newActions.add({
      'players': gamePlayers.map((p) => p.toMap()).toList(),
      'type': 'playerList',
      'id': messageId,
    });
    await roomRef.update({
      'players': gamePlayers.map((p) => p.toMap()).toList(),
      'messages': newActions,
    });
  }

  Map<String, dynamic> formatDatabaseMap(Map<Object?, Object?> map) {
    Map<String, dynamic> result = {};

    map.forEach((key, value) {
      // Convert key to String, handle null keys
      String stringKey = key?.toString() ?? '';

      // Convert value based on its type
      dynamic convertedValue;

      if (value == null) {
        convertedValue = null;
      } else if (value is Map<Object?, Object?>) {
        // Recursively convert nested maps
        convertedValue = formatDatabaseMap(value);
      } else if (value is List) {
        // Convert list elements
        convertedValue =
            value.map((item) {
              if (item is Map<Object?, Object?>) {
                return formatDatabaseMap(item);
              } else {
                return item;
              }
            }).toList();
      } else {
        // For primitive types (String, int, double, bool), keep as is
        convertedValue = value;
      }

      result[stringKey] = convertedValue;
    });

    return result;
  }

  Future<void> deleteRoom(String roomId) async {
    final roomRef = _database.ref("rooms/$roomId");
    await roomRef.remove();
  }

  List<GamePlayer> dynamicToGamePlayer(List<dynamic> list) {
    List<GamePlayer> newList = [];
    for (var i in list) {
      if (i is GamePlayer) {
        newList.add(i);
      } else {
        newList.add(GamePlayer.fromMap(i));
      }
    }
    return newList;
  }

  Future<void> submitSuggestion(String suggestion) async {
    final suggestionsRef = _database.ref('suggestions');
    final suggestionId = DateTime.now().millisecondsSinceEpoch.toString();
    await suggestionsRef.child(suggestionId).set({
      'id': suggestionId,
      'suggestion': suggestion,

      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
