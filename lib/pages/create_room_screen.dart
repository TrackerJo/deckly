import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/dutch_blitz.dart';
import 'package:deckly/pages/game_screen.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_text.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nearby_connections/nearby_connections.dart' as nearby;

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key, required this.userName});
  final String userName;
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;

  final List<GamePlayer> _players = [];
  final String _roomCode = (1000 + Random().nextInt(9000)).toString();

  String _hostDeviceId = '';

  @override
  void initState() {
    super.initState();
    _players.add(GamePlayer(id: 'host', name: widget.userName, isHost: true));
    _initService();
  }

  Future<void> _initService() async {
    // Android permissions
    if (Platform.isAndroid) {
      await [Permission.locationWhenInUse].request();
    }

    setState(() {
      _hostDeviceId = "Deckly-" + widget.userName + '-' + _roomCode + '-host';
      _players.clear();
      _players.add(
        GamePlayer(
          id: "Deckly-" + widget.userName + '-' + _roomCode + '-host',
          name: widget.userName,
          isHost: true,
        ),
      );
      print("Host Device ID: $_hostDeviceId");
    });

    if (Platform.isIOS) {
      // 1) init: advertise & browse
      await nearbyService.init(
        serviceType: 'deckly',
        deviceName: "Deckly-" + widget.userName + '-' + _roomCode + '-host',

        strategy: Strategy.P2P_CLUSTER,
        callback: (isRunning) async {
          if (isRunning) {
            await nearbyService.stopAdvertisingPeer();
            await nearbyService.stopBrowsingForPeers();
            await Future.delayed(Duration(microseconds: 200));
            await nearbyService.startAdvertisingPeer();
            await nearbyService.startBrowsingForPeers();
          }
        },
      );

      _stateSub = nearbyService.stateChangedSubscription(
        callback: (devicesList) {
          devicesList.forEach((element) {
            print(
              " deviceId: ${element.deviceId} | deviceName: ${element.deviceName} | state: ${element.state}",
            );

            if (Platform.isAndroid) {
              if (element.state == SessionState.connected) {
                nearbyService.stopBrowsingForPeers();
              } else {
                nearbyService.startBrowsingForPeers();
              }
            }
          });

          setState(() {
            _players.clear();
            _players.add(
              GamePlayer(
                id: _hostDeviceId,
                name: widget.userName,
                isHost: true,
              ),
            );
            _players.addAll(
              devicesList
                  .where((d) => d.state == SessionState.connected)
                  .map(
                    (d) => GamePlayer(
                      id: d.deviceId,
                      name: d.deviceName.split("-")[1],
                      isHost: d.deviceName.contains("host"),
                    ),
                  ),
            );
            List<GamePlayer> allPlayers =
                devicesList
                    .where((d) => d.state == SessionState.connected)
                    .map(
                      (d) => GamePlayer(
                        id: d.deviceId,
                        name: d.deviceName.split("-")[1],
                        isHost: d.deviceName.contains("host"),
                      ),
                    )
                    .toList();
            for (var player in allPlayers) {
              if (!player.isHost) {
                List<Map<String, dynamic>> playerData =
                    _players.map((p) => p.toMap()).toList();
                nearbyService.sendMessage(
                  player.id,
                  jsonEncode({'type': 'playerList', 'players': playerData}),
                );
              }
            }
          });
        },
      );

      _dataSub = nearbyService.dataReceivedSubscription(
        callback: (data) {
          print("dataReceivedSubscription: ${jsonEncode(data)}");
          showToast(
            jsonEncode(data),
            context: context,
            axis: Axis.horizontal,
            alignment: Alignment.center,
            position: StyledToastPosition.bottom,
          );
        },
      );
    } else {
      //Android implementation
      await nearby.Nearby().startAdvertising(
        _hostDeviceId,
        nearby.Strategy.P2P_CLUSTER,
        serviceId: 'deckly',
        onConnectionInitiated: (endpointId, connectionInfo) async {
          await nearby.Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: (endpointId, payload) {
              print("Payload received: ${payload.type}");
              if (payload.type == nearby.PayloadType.BYTES) {
                String data = utf8.decode(payload.bytes!);
                print("Data: $data");
                showToast(
                  data,
                  context: context,
                  axis: Axis.horizontal,
                  alignment: Alignment.center,
                  position: StyledToastPosition.bottom,
                );
              }
            },
          );
        },
        onConnectionResult: (endpointId, status) {
          if (status == nearby.Status.CONNECTED) {
            print("Connection successful with $endpointId");
            List<GamePlayer> allPlayers = [..._players];
            allPlayers.add(
              GamePlayer(
                id: endpointId,
                name: endpointId.split("-")[1],
                isHost: endpointId.contains("host"),
              ),
            );
            List<Map<String, dynamic>> playerData =
                allPlayers.map((p) => p.toMap()).toList();
            for (var player in allPlayers) {
              if (!player.isHost) {
                nearby.Nearby().sendBytesPayload(
                  player.id,
                  utf8.encode(
                    jsonEncode({'type': 'playerList', 'players': playerData}),
                  ),
                );
              }
            }
            setState(() {
              _players.add(
                GamePlayer(
                  id: endpointId,
                  name: endpointId.split("-")[1],
                  isHost: endpointId.contains("host"),
                ),
              );
            });
          } else {
            print("Connection failed with $endpointId: $status");
          }
        },
        onDisconnected: (endpointId) {
          print("Disconnected from $endpointId");
          setState(() {
            _players.removeWhere((p) => p.id == endpointId);
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _dataSub.cancel();

    super.dispose();
  }

  void _startGame() async {
    for (var player in _players) {
      if (!player.isHost) {
        if (Platform.isIOS) {
          await nearbyService.sendMessage(
            player.id,
            jsonEncode({
              'type': 'startGame',
              'roomCode': _roomCode,
              'players': _players.map((p) => p.toMap()).toList(),
            }),
          );
        } else {
          // Android implementation
          await nearby.Nearby().sendBytesPayload(
            player.id,
            utf8.encode(
              jsonEncode({
                'type': 'startGame',
                'roomCode': _roomCode,
                'players': _players.map((p) => p.toMap()).toList(),
              }),
            ),
          );
        }
      }
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => DutchBlitz(
              player: _players.where((p) => p.isHost).first,
              players: _players,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: "Deckly Room",
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
            FancyWidget(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Room Code: $_roomCode',
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
              'Players:',
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FancyWidget(
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
            if (_players.length < 2)
              FancyText(
                text: const Text(
                  'Waiting for more players to join...',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ActionButton(
                  onTap: _players.length >= 2 ? _startGame : null,
                  label:
                      _players.length >= 2
                          ? 'Start Game'
                          : 'Waiting for players',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
