import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/dutch_blitz.dart';
import 'package:deckly/pages/game_screen.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/gradient_input_field.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nearby_connections/nearby_connections.dart' as nearby;

class JoinRoomScreen extends StatefulWidget {
  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;
  final List<GamePlayer> _players = [];
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  bool _initialized = false;
  bool joinedRoom = false;

  @override
  void dispose() {
    if (_initialized && Platform.isIOS) {
      _stateSub.cancel();
      _dataSub.cancel();
    }
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> requestAndroidPermissions() async {
    bool locationIsGranted = await Permission.location.isGranted;
    // Check Permission
    if (!locationIsGranted) {
      await Permission.location.request();
    } // Ask

    // Check Location Status
    bool locationSeriveEnabled =
        await Permission.location.serviceStatus.isEnabled;
    if (!locationSeriveEnabled) {
      // If location service is not enabled, request it
      await Location().requestService();
    }

    bool stoargeIsGranted = await Permission.storage.isGranted;
    if (!stoargeIsGranted) {
      // Check Permission
      await Permission.storage.request(); // Ask
    }
    // Bluetooth permissions
    bool granted =
        !(await Future.wait([
          // Check Permissions
          Permission.bluetooth.isGranted,
          Permission.bluetoothAdvertise.isGranted,
          Permission.bluetoothConnect.isGranted,
          Permission.bluetoothScan.isGranted,
        ])).any((element) => false);
    [
      // Ask Permissions
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    // Check Bluetooth Status
    bool nearbyWifiDevicesIsGranted =
        await Permission.nearbyWifiDevices.isGranted;
    if (!nearbyWifiDevicesIsGranted) {
      // Android 12+
      await Permission.nearbyWifiDevices.request();
    }
  }

  Future<void> _joinRoom() async {
    if (_codeCtrl.text.length != 4 || _nameCtrl.text.isEmpty) return;

    final roomCode = _codeCtrl.text;

    // Android permissions
    if (Platform.isAndroid) {
      await [Permission.locationWhenInUse].request();
      await requestAndroidPermissions();
    }

    if (Platform.isIOS) {
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
              print("Invited peer: ${device.deviceId}");

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
          } else if (dataMap['type'] == 'startGame') {
            // Navigate to the game screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => DutchBlitz(
                      players: _players,
                      player: _players.firstWhere(
                        (p) => p.name == _nameCtrl.text,
                      ),
                    ),
              ),
            );
          }
        },
      );
    } else {
      //Android implementation
      await nearby.Nearby().startDiscovery(
        "Deckly-" + _nameCtrl.text + '-' + roomCode,
        nearby.Strategy.P2P_CLUSTER,
        onEndpointFound: (String id, String userName, String serviceId) {
          print("Endpoint found: $id, $userName, $serviceId");
          if (userName.startsWith('Deckly-') &&
              userName.contains("-$roomCode")) {
            nearby.Nearby().requestConnection(
              userName,
              id,
              onConnectionInitiated: (endpointId, info) async {
                print("Connection initiated with $endpointId");
                await nearby.Nearby().acceptConnection(
                  endpointId,
                  onPayLoadRecieved: (endpointId, payload) {
                    print("Payload received from $endpointId: ${payload.type}");
                    if (payload.type == nearby.PayloadType.BYTES) {
                      final data = utf8.decode(payload.bytes!);
                      print("Data: $data");
                      Map<String, dynamic> dataMap = jsonDecode(data);
                      if (dataMap['type'] == 'playerList') {
                        final playersData = dataMap['players'] as List;
                        setState(() {
                          _players.clear();
                          _players.addAll(
                            playersData
                                .map(
                                  (p) => GamePlayer.fromMap(
                                    p as Map<String, dynamic>,
                                  ),
                                )
                                .toList(),
                          );
                        });
                      } else if (dataMap['type'] == 'startGame') {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DutchBlitz(
                                  players: _players,
                                  player: _players.firstWhere(
                                    (p) => p.name == _nameCtrl.text,
                                  ),
                                ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
              onConnectionResult: (endpointId, status) {
                print("Connection result for $endpointId: $status");
                if (status == nearby.Status.CONNECTED) {
                  print("Successfully connected to $endpointId");
                  setState(() {
                    joinedRoom = true;
                  });
                } else {
                  print("Failed to connect to $endpointId");
                }
              },
              onDisconnected: (endpointId) {
                print("Disconnected from $endpointId");
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: "Join Deckly Room",
          showBackButton: true,
          onBackButtonPressed: (context) {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: styling.backgroundColor,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GradientInputField(
                      textField: TextField(
                        controller: _codeCtrl,
                        decoration: styling.gradientInputDecoration().copyWith(
                          hintText: 'Enter 4-digit code',
                        ),
                        keyboardType: TextInputType.number,
                        cursorColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        maxLength: 4,
                        onTap: () {
                          SharedPrefs.hapticInputSelect();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    GradientInputField(
                      textField: TextField(
                        controller: _nameCtrl,
                        decoration: styling.gradientInputDecoration().copyWith(
                          hintText: 'Enter your name',
                        ),
                        cursorColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        onTap: () {
                          SharedPrefs.hapticInputSelect();
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ActionButton(
                        onTap: _joinRoom,
                        label: _initialized ? 'Scanning…' : 'Join Room',
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
