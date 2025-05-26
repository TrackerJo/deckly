import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:deckly/constants.dart';
import 'package:deckly/pages/game_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class JoinRoomScreen extends StatefulWidget {
  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late NearbyService nearbyService;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  final List<GamePlayer> _players = [];
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _initialized = false;
  bool joinedRoom = false;

  @override
  void dispose() {
    if (_initialized) {
      _stateSub.cancel();
      _dataSub.cancel();
      nearbyService.stopBrowsingForPeers();
    }
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.length != 4 || _nameCtrl.text.isEmpty) return;

    final roomCode = _codeCtrl.text;

    // Android permissions
    if (Platform.isAndroid) {
      await [Permission.locationWhenInUse].request();
    }
    nearbyService = NearbyService();
    String devInfo = '';
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      devInfo = androidInfo.model;
    }
    if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      devInfo = iosInfo.localizedModel;
    }
    await nearbyService.init(
      serviceType: 'deckly',
      deviceName: "Deckly-" + _nameCtrl.text + '-' + roomCode,
      strategy: Strategy.P2P_CLUSTER,
      callback: (isRunning) async {
        if (isRunning) {
          await nearbyService.stopBrowsingForPeers();
          await Future.delayed(Duration(microseconds: 200));
          await nearbyService.startBrowsingForPeers();
        }
      },
    );

    _stateSub = nearbyService.stateChangedSubscription(
      callback: (devicesList) async {
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

        List<Device> filteredDevices =
            devicesList
                .where(
                  (d) =>
                      d.deviceName.startsWith('Deckly-') &&
                      d.deviceName.contains("-${roomCode}"),
                )
                .toList();
        if (filteredDevices.isNotEmpty) {
          final device = filteredDevices.first;
          if (device.state == SessionState.notConnected) {
            await nearbyService.invitePeer(
              deviceID: device.deviceId,
              deviceName: device.deviceName,
            );

            // nearbyService.stopBrowsingForPeers();
          } else if (device.state == SessionState.connected) {
            // Successfully connected to the room
            setState(() {
              joinedRoom = true;
            });
          }
        }
      },
    );

    _dataSub = nearbyService.dataReceivedSubscription(
      callback: (data) {
        print("dataReceivedSubscription: ${jsonEncode(data)}");
        Map<String, dynamic> dataMap;

        if (data is String) {
          // If data is a string, decode it
          try {
            dataMap = jsonDecode(data);
          } catch (e) {
            print("Error decoding JSON string: $e");
            return;
          }
        } else if (data is Map) {
          // If data is already a map, cast it
          dataMap = jsonDecode(Map<String, dynamic>.from(data)["message"]);
        } else {
          print("Unexpected data type: ${data.runtimeType}");
          return;
        }
        print("Type of data: ${dataMap['type']}");
        if (dataMap['type'] == 'playerList') {
          final playersData = dataMap['players'] as List;
          print("Received player list: ${jsonEncode(playersData)}");
          setState(() {
            _players.clear();
            _players.addAll(
              playersData
                  .map((p) => GamePlayer.fromMap(p as Map<String, dynamic>))
                  .toList(),
            );
          });
        }
      },
    );

    setState(() => _initialized = true);
  }

  bool get _isReadyToJoin =>
      !_initialized && _codeCtrl.text.length == 4 && _nameCtrl.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final canJoin =
        !_initialized &&
        _codeCtrl.text.length == 4 &&
        _nameCtrl.text.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Join Deckly Room')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child:
            joinedRoom
                ? Column(
                  children: [
                    Text(
                      'You have joined the room!',
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Players (${_players.length}):',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children:
                            _players
                                .map(
                                  (p) => ListTile(
                                    leading: Icon(
                                      p.isHost ? Icons.star : Icons.person,
                                    ),
                                    title: Text(p.name),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                )
                : Column(
                  children: [
                    TextField(
                      controller: _codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Room Code',
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Your Name'),
                    ),
                    const SizedBox(height: 24),
                    Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _joinRoom,
                        child:
                            _initialized
                                ? const Text('Scanning…')
                                : const Text('Join Room'),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
