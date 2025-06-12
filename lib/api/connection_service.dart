import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:nearby_connections/nearby_connections.dart' as nearby;

enum ConnectionRole { host, client }

class ConnectionService {
  static final ConnectionService _instance = ConnectionService._internal();
  factory ConnectionService() => _instance;
  ConnectionService._internal();

  // Private properties
  ConnectionRole? _role;
  String? _roomCode;
  String? _userName;
  String? _connectedEndpointId;
  bool _isInitialized = false;
  Timer? _connectionTimeout;

  // Stream controllers
  final StreamController<List<GamePlayer>> playersController =
      StreamController<List<GamePlayer>>.broadcast();
  final StreamController<Map<String, dynamic>> gameDataController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<ConnectionState> connectionStateController =
      StreamController<ConnectionState>.broadcast();

  // Public streams (keep these for convenience)
  Stream<List<GamePlayer>> get playersStream => playersController.stream;
  Stream<Map<String, dynamic>> get gameDataStream => gameDataController.stream;
  Stream<ConnectionState> get connectionStateStream =>
      connectionStateController.stream;

  // Subscriptions for cleanup
  StreamSubscription<dynamic>? _stateSub;
  StreamSubscription<dynamic>? _dataSub;

  // Current state
  List<GamePlayer> _players = [];
  List<BotPlayer> _bots = [];
  ConnectionState _connectionState = ConnectionState.disconnected;

  // Getters
  List<GamePlayer> get players => List.from(_players);
  ConnectionState get connectionState => _connectionState;
  String? get roomCode => _roomCode;
  bool get isHost => _role == ConnectionRole.host;
  bool get isInitialized => _isInitialized;

  Game? _game;

  // Initialize as host
  Future<void> initAsHost(String userName, Game game) async {
    if (_isInitialized) await dispose();

    _role = ConnectionRole.host;
    _userName = userName;
    _roomCode = (1000 + DateTime.now().millisecond).toString();
    _game = game;

    _players = [
      BlitzPlayer(
        id: 'Deckly-$userName-$_roomCode-host',
        name: userName,
        isHost: true,
        score: 0,
        blitzDeckSize: 13, // Set to 0 or appropriate default
      ),
    ];

    _updateConnectionState(ConnectionState.hosting);
    playersController.add(_players);

    if (Platform.isIOS) {
      await _initIOSHost();
    } else {
      await _initAndroidHost();
    }

    _isInitialized = true;
  }

  // Initialize as client
  Future<void> initAsClient(String userName, String roomCode) async {
    if (_isInitialized) await dispose();

    _role = ConnectionRole.client;
    _userName = userName;
    _roomCode = roomCode;
    _players = [];

    _updateConnectionState(ConnectionState.searching);

    if (Platform.isIOS) {
      await _initIOSClient();
    } else {
      await _initAndroidClient();
    }

    _isInitialized = true;
  }

  // iOS Host Implementation
  Future<void> _initIOSHost() async {
    final deviceName = "Deckly-$_userName-$_roomCode-host";

    await nearbyService.init(
      serviceType: 'deckly',
      deviceName: deviceName,
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          // await nearbyService.stopAdvertisingPeer();
          // await nearbyService.stopBrowsingForPeers();
          // await Future.delayed(Duration(milliseconds: 200));
          await nearbyService.startAdvertisingPeer();
          await nearbyService.startBrowsingForPeers();
        }
      },
    );

    _stateSub = nearbyService.stateChangedSubscription(
      callback: (devicesList) {
        _handleIOSStateChange(devicesList);
      },
    );

    _dataSub = nearbyService.dataReceivedSubscription(
      callback: (data) {
        _handleIOSDataReceived(data);
      },
    );
  }

  // iOS Client Implementation
  Future<void> _initIOSClient() async {
    final deviceName = "Deckly-$_userName-$_roomCode";

    await nearbyService.init(
      serviceType: 'deckly',
      deviceName: deviceName,
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          // await nearbyService.stopBrowsingForPeers();
          // await Future.delayed(Duration(milliseconds: 200));
          await nearbyService.startBrowsingForPeers();
          _connectionTimeout?.cancel();
          _connectionTimeout = Timer(Duration(seconds: 30), () {
            if (_connectionState == ConnectionState.connecting) {
              print("Connection timeout, retrying...");
              _retryConnection();
            }
          });
        }
      },
    );

    _stateSub = nearbyService.stateChangedSubscription(
      callback: (devicesList) {
        _handleIOSStateChange(devicesList);
      },
    );

    _dataSub = nearbyService.dataReceivedSubscription(
      callback: (data) {
        _handleIOSDataReceived(data);
      },
    );
  }

  Future<void> _retryConnection() async {
    print("Retrying connection...");
    _updateConnectionState(ConnectionState.searching);

    try {
      await nearbyService.stopBrowsingForPeers();
      await Future.delayed(Duration(seconds: 1));
      await nearbyService.startBrowsingForPeers();
    } catch (e) {
      print("Error during retry: $e");
    }
  }

  // Android Host Implementation
  Future<void> _initAndroidHost() async {
    final deviceName = "Deckly-$_userName-$_roomCode-host";

    await androidNearby.startAdvertising(
      deviceName,
      nearby.Strategy.P2P_CLUSTER,
      serviceId: 'deckly',
      onConnectionInitiated: (endpointId, connectionInfo) async {
        await androidNearby.acceptConnection(
          endpointId,
          onPayLoadRecieved: (endpointId, payload) {
            _handleAndroidPayload(endpointId, payload);
          },
        );
      },
      onConnectionResult: (endpointId, status) {
        _handleAndroidConnectionResult(endpointId, status);
      },
      onDisconnected: (endpointId) {
        _handleAndroidDisconnection(endpointId);
      },
    );
  }

  // Android Client Implementation
  Future<void> _initAndroidClient() async {
    final deviceName = "Deckly-$_userName-$_roomCode";
    _updateConnectionState(ConnectionState.searching);

    await androidNearby.startDiscovery(
      deviceName,
      nearby.Strategy.P2P_CLUSTER,
      onEndpointFound: (String id, String userName, String serviceId) {
        if (userName.startsWith('Deckly-') &&
            userName.contains("-$_roomCode") &&
            userName.contains("host")) {
          _updateConnectionState(ConnectionState.connecting);
          androidNearby.requestConnection(
            userName,
            id,
            onConnectionInitiated: (endpointId, info) async {
              await androidNearby.acceptConnection(
                endpointId,
                onPayLoadRecieved: (endpointId, payload) {
                  _handleAndroidPayload(endpointId, payload);
                },
              );
            },
            onConnectionResult: (endpointId, status) {
              _handleAndroidConnectionResult(endpointId, status);
            },
            onDisconnected: (endpointId) {
              _handleAndroidDisconnection(endpointId);
            },
          );
        }
      },
      onEndpointLost: (endpointId) {
        print("Endpoint lost: $endpointId");
      },
      serviceId: 'deckly',
    );
  }

  // iOS Event Handlers
  void _handleIOSStateChange(List<Device> devicesList) {
    if (isHost) {
      _players = [
        GamePlayer(
          id: 'Deckly-$_userName-$_roomCode-host',
          name: _userName!,
          isHost: true,
        ),
      ];

      _players.addAll(
        devicesList
            .where(
              (d) =>
                  d.state == SessionState.connected &&
                  d.deviceName.contains("-$_roomCode"),
            )
            .map(
              (d) => GamePlayer(
                id: d.deviceId,
                name: d.deviceName.split("-")[1],
                isHost: false,
              ),
            ),
      );

      _players.addAll(_bots);

      playersController.add(_players);
      _broadcastPlayerList();
    } else {
      // Client: look for host
      final hostDevices =
          devicesList
              .where((d) => d.deviceName.contains("-$_roomCode-host"))
              .toList();

      if (hostDevices.isNotEmpty) {
        final host = hostDevices.first;
        if (host.state == SessionState.notConnected) {
          _updateConnectionState(ConnectionState.connecting);
          print("Inviting host: ${host.deviceName}");
          nearbyService.invitePeer(
            deviceID: host.deviceId,
            deviceName: host.deviceName,
          );
        } else if (host.state == SessionState.connected) {
          print("Connected to host: ${host.deviceName}");
          _updateConnectionState(ConnectionState.connected);
        }
      }
    }
  }

  void _handleIOSDataReceived(dynamic data) {
    try {
      Map<String, dynamic> dataMap;

      if (data is String) {
        dataMap = jsonDecode(data);
      } else if (data is Map) {
        dataMap = jsonDecode(Map<String, dynamic>.from(data)["message"]);
      } else {
        return;
      }

      _processGameData(dataMap);
    } catch (e) {
      print("Error processing iOS data: $e");
    }
  }

  // Android Event Handlers
  void _handleAndroidPayload(String endpointId, nearby.Payload payload) {
    if (payload.type == nearby.PayloadType.BYTES) {
      try {
        final data = utf8.decode(payload.bytes!);
        final dataMap = jsonDecode(data) as Map<String, dynamic>;
        _processGameData(dataMap);
      } catch (e) {
        print("Error processing Android payload: $e");
      }
    }
  }

  void _handleAndroidConnectionResult(String endpointId, nearby.Status status) {
    if (status == nearby.Status.CONNECTED) {
      _connectedEndpointId = endpointId;
      _updateConnectionState(ConnectionState.connected);

      if (isHost) {
        // Add new player
        _players.add(
          GamePlayer(
            id: endpointId,
            name: endpointId.split("-")[1],
            isHost: false,
          ),
        );
        playersController.add(_players);
        _broadcastPlayerList();
      }
    }
  }

  void _handleAndroidDisconnection(String endpointId) {
    _players.removeWhere((p) => p.id == endpointId);
    playersController.add(_players);

    if (!isHost && endpointId == _connectedEndpointId) {
      _updateConnectionState(ConnectionState.disconnected);
    }
  }

  // Common Data Processing
  void _processGameData(Map<String, dynamic> dataMap) {
    switch (dataMap['type']) {
      case 'relay_message':
        if (isHost) {
          // Host receives relay request and broadcasts to all other clients
          final originalMessage =
              dataMap['original_message'] as Map<String, dynamic>;
          final senderId = dataMap['sender_id'] as String;

          // Send to all clients except the original sender
          for (final player in _players.where(
            (p) => !p.isHost && p.id != senderId,
          )) {
            sendMessage(player.id, jsonEncode(originalMessage));
          }
        }
        break;
      case 'playerList':
        if (!isHost) {
          final playersData = dataMap['players'] as List;
          _players =
              playersData
                  .map((p) => GamePlayer.fromMap(p as Map<String, dynamic>))
                  .toList();
          playersController.add(_players);
        }
        break;
      case 'startGame':
        gameDataController.add(dataMap);
        break;

      default:
        gameDataController.add(dataMap);
    }
  }

  // Helper Methods
  void _updateConnectionState(ConnectionState state) {
    _connectionState = state;
    connectionStateController.add(state);
  }

  void _broadcastPlayerList() {
    if (!isHost) return;

    final playerData = _players.map((p) => p.toMap()).toList();
    final message = jsonEncode({'type': 'playerList', 'players': playerData});

    for (final player in _players) {
      if (!player.isHost && !player.isBot) {
        sendMessage(player.id, message);
        sendMessage(
          player.id,
          jsonEncode({'type': 'game_type', 'game_type': _game!.toString()}),
        );
      }
    }
  }

  // Public Methods
  Future<void> sendMessage(String playerId, String message) async {
    if (Platform.isIOS) {
      await nearbyService.sendMessage(playerId, message);
    } else {
      await nearby.Nearby().sendBytesPayload(playerId, utf8.encode(message));
    }
  }

  Future<void> startGame() async {
    if (!isHost) return;

    final message = jsonEncode({
      'type': 'startGame',
      'roomCode': _roomCode,
      'players': _players.map((p) => p.toMap()).toList(),
    });

    // Collect all sendMessage futures and wait for all to complete
    final futures =
        _players
            .where((p) => !p.isHost)
            .map((player) => sendMessage(player.id, message))
            .toList();
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> dispose() async {
    try {
      await _stateSub?.cancel();
      await _dataSub?.cancel();
      _connectionTimeout?.cancel();

      if (Platform.isAndroid) {
        if (_connectedEndpointId != null) {
          await androidNearby.disconnectFromEndpoint(_connectedEndpointId!);
        }
        if (isHost) {
          await androidNearby.stopAdvertising();
        } else {
          await androidNearby.stopDiscovery();
        }
      } else {
        await nearbyService.stopAdvertisingPeer();
        await nearbyService.stopBrowsingForPeers();
      }

      _isInitialized = false;
      _role = null;
      _roomCode = null;
      _userName = null;
      _connectedEndpointId = null;
      _players.clear();
      _bots.clear();
      _updateConnectionState(ConnectionState.disconnected);
    } catch (e) {
      print("Error during dispose: $e");
    }
  }

  Future<void> broadcastMessage(
    Map<String, dynamic> messageData,
    String senderId,
  ) async {
    final message = jsonEncode(messageData);

    if (isHost) {
      // Host sends to all clients
      final futures =
          _players
              .where((p) => !p.isHost && !p.isBot)
              .map((player) => sendMessage(player.id, message))
              .toList();

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    } else {
      // Client sends to host, who will relay to others
      final hostPlayer = _players.firstWhere((p) => p.isHost);
      await sendMessage(
        hostPlayer.id,
        jsonEncode({
          'type': 'relay_message',
          'original_message': messageData,
          'sender_id': senderId, // Current client's ID
        }),
      );
      await sendMessage(hostPlayer.id, jsonEncode(messageData));
    }
  }

  Future<void> addBot(BotPlayer botPlayer) async {
    if (!isHost) return;

    // Add bot player to the list
    _players.add(botPlayer);
    _bots.add(botPlayer);
    playersController.add(_players);

    // Broadcast updated player list
    _broadcastPlayerList();
  }

  Future<void> updateBotDifficulty(
    String botId,
    BotDifficulty difficulty,
  ) async {
    if (!isHost) return;

    // Find the bot player and update its difficulty
    final botPlayer = _players.firstWhere(
      (p) => p.id == botId && p.isBot,
      orElse: () => throw Exception("Bot not found"),
    );

    (botPlayer as BotPlayer).difficulty = difficulty;

    final botsBotPlayer = _bots.firstWhere(
      (b) => b.id == botId,
      orElse: () => throw Exception("Bot not found in bots list"),
    );
    botsBotPlayer.difficulty = difficulty;

    // Broadcast updated player list
    _broadcastPlayerList();
  }

  Future<void> removeBot(String botId) async {
    if (!isHost) return;

    // Remove bot player from the list
    _players.removeWhere((p) => p.id == botId && p.isBot);
    _bots.removeWhere((b) => b.id == botId);
    playersController.add(_players);

    // Broadcast updated player list
    _broadcastPlayerList();
  }
}

enum ConnectionState { disconnected, connecting, connected, hosting, searching }
