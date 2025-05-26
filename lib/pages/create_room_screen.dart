import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:deckly/constants.dart';
import 'package:deckly/pages/game_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nearby_connections/flutter_nearby_connections.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:permission_handler/permission_handler.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key, required this.userName});
  final String userName;
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  late NearbyService nearbyService;
  late StreamSubscription<dynamic> _stateSub;
  late StreamSubscription<dynamic> _dataSub;

  final List<GamePlayer> _players = [];
  final String _roomCode = (1000 + Random().nextInt(9000)).toString();

  @override
  void initState() {
    super.initState();
    _players.add(GamePlayer(id: 'host', name: 'Host (You)', isHost: true));
    _initService();
  }

  Future<void> _initService() async {
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

    // 1) init: advertise & browse
    await nearbyService.init(
      serviceType: 'deckly',
      deviceName: "Deckly-" + devInfo + '-' + _roomCode + '-host',

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
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _dataSub.cancel();
    nearbyService.stopAdvertisingPeer();

    super.dispose();
  }

  void _startGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => GameScreen(
              isHost: true,
              roomCode: _roomCode,
              players: _players,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Deckly Room')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Room Code: $_roomCode',
              style: const TextStyle(fontSize: 32, letterSpacing: 8),
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
                            leading: Icon(p.isHost ? Icons.star : Icons.person),
                            title: Text(p.name),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _players.length >= 2 ? _startGame : null,
                child: const Text('Start Game'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
