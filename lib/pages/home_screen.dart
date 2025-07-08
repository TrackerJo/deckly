import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/pages/settings_page.dart';
import 'package:deckly/pages/solitare.dart';
import 'package:deckly/pages/stats_page.dart';
import 'package:deckly/widgets/fancy_widget.dart';

import 'package:deckly/widgets/gradient_input_field.dart';
import 'package:deckly/widgets/orientation_checker.dart';
import 'package:deckly/widgets/solid_action_button.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/create_room_screen.dart';
import 'package:deckly/pages/join_room_screen.dart';
import 'package:deckly/widgets/whats_new.dart';
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String lastUsedName = "";
  bool showWhatsNew = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SharedPrefs.getLastUsedName().then((value) {
      if (!mounted) return;
      setState(() {
        lastUsedName = value;
      });
    });
    SharedPrefs.getNewestSeenVersion().then((value) async {
      if (!mounted) return;
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentBuildNumber = packageInfo.buildNumber;
      if (value != currentBuildNumber) {
        setState(() {
          showWhatsNew = true;
        });
      }
    });
  }

  void showHowSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: styling.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(23),
          topRight: Radius.circular(23),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "How Deckly Works",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Deckly is a platform for playing card games with friends without the need for physical cards or even a wifi connection!",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "To get started, you can either create a local game or join an existing one. Once you're in a game, you can invite your friends to join by sharing the room code.",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Deckly uses Bluetooth to connect devices, so you can play with friends nearby without needing an internet connection. Just make sure Bluetooth is enabled on your device.",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double calculateButtonWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableScreenWidth =
        (screenWidth - 24) * 0.8; // 80% of the screen width
    final buttonWidth =
        availableScreenWidth / 2 - 8; // Two buttons with spacing
    return buttonWidth.clamp(100.0, 300.0); // Ensure width
  }

  @override
  Widget build(BuildContext context) {
    double buttonWidth = calculateButtonWidth(context);
    return Scaffold(
      backgroundColor: styling.background,
      body: OrientationChecker(
        allowedOrientations: [
          Orientation.portrait,
          if (isTablet(context)) Orientation.landscape,
        ],
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 12),
          child: SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 35),
                  FancyWidget(
                    child: Text(
                      "Welcome to Deckly",
                      style: TextStyle(
                        color:
                            Colors.white, // This will be masked by the gradient
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ActionButton(
                  //   width: 100,
                  //   text: Text(
                  //     'How Deckly Works',
                  //     style: TextStyle(
                  //       color:
                  //           Colors.white, // This will be masked by the gradient
                  //       fontSize: 14,
                  //       fontWeight: FontWeight.bold,
                  //     ),
                  //     textAlign: TextAlign.center,
                  //   ),
                  //   onTap: () async {
                  //     SharedPrefs.hapticButtonPress();

                  //     print("=== BLUETOOTH PERMISSION DEBUG ===");
                  //     try {
                  //       print(
                  //         "Bluetooth basic: ${await Permission.bluetooth.status}",
                  //       );
                  //     } catch (e) {
                  //       print("Bluetooth basic ERROR: $e");
                  //     }

                  //     try {
                  //       print(
                  //         "Bluetooth scan: ${await Permission.bluetoothScan.status}",
                  //       );
                  //     } catch (e) {
                  //       print("Bluetooth scan ERROR: $e");
                  //     }

                  //     try {
                  //       print(
                  //         "Bluetooth connect: ${await Permission.bluetoothConnect.status}",
                  //       );
                  //     } catch (e) {
                  //       print("Bluetooth connect ERROR: $e");
                  //     }

                  //     try {
                  //       print(
                  //         "Bluetooth advertise: ${await Permission.bluetoothAdvertise.status}",
                  //       );
                  //     } catch (e) {
                  //       print("Bluetooth advertise ERROR: $e");
                  //     }
                  //     print("=== END DEBUG ===");
                  //   },
                  // ),
                  ActionButton(
                    text: Text(
                      'Join Local Game',
                      style: TextStyle(
                        color:
                            Colors.white, // This will be masked by the gradient
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      analytics.logJoinRoomEvent();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JoinRoomScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ActionButton(
                    text: Text(
                      'Join Online Game',
                      style: TextStyle(
                        color:
                            Colors.white, // This will be masked by the gradient
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    onTap: () {
                      analytics.logJoinRoomEvent();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JoinRoomScreen(isOnline: true),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Container(
                        width: 100,
                        child: Divider(color: styling.primary, thickness: 2),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'or',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Container(
                        width: 100,
                        child: Divider(color: styling.primary, thickness: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select a game:',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Wrap(
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      // mainAxisSize: MainAxisSize.min,
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        ActionButton(
                          height: 60,
                          width: buttonWidth,
                          text: Text(
                            'Nertz',
                            style: TextStyle(
                              color:
                                  Colors
                                      .white, // This will be masked by the gradient
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final myController = TextEditingController();
                                if (lastUsedName.isNotEmpty) {
                                  myController.text = lastUsedName;
                                }
                                return Dialog(
                                  backgroundColor: Colors.transparent,

                                  child: Container(
                                    width: 400,

                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          styling.primary,
                                          styling.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        2,
                                      ), // Creates the border thickness
                                      decoration: BoxDecoration(
                                        color: styling.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                            "Enter Your Name",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GradientInputField(
                                              textField: TextField(
                                                controller: myController,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: styling
                                                    .gradientInputDecoration()
                                                    .copyWith(
                                                      hintText: "Your Name",
                                                    ),
                                                onTap: () {
                                                  SharedPrefs.hapticInputSelect();
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: styling.secondary,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  SharedPrefs.hapticButtonPress();
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Local Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Nertz Local",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.nertz,
                                                                    maxPlayers:
                                                                        8,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Online Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Nertz Online",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.nertz,
                                                                    maxPlayers:
                                                                        8,
                                                                    isOnline:
                                                                        true,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        ActionButton(
                          height: 60,
                          width: buttonWidth,
                          text: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Nordic Dash',
                              style: TextStyle(
                                color:
                                    Colors
                                        .white, // This will be masked by the gradient
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final myController = TextEditingController();
                                if (lastUsedName.isNotEmpty) {
                                  myController.text = lastUsedName;
                                }
                                return Dialog(
                                  backgroundColor: Colors.transparent,

                                  child: Container(
                                    width: 400,

                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          styling.primary,
                                          styling.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        2,
                                      ), // Creates the border thickness
                                      decoration: BoxDecoration(
                                        color: styling.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                            "Enter Your Name",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GradientInputField(
                                              textField: TextField(
                                                controller: myController,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: styling
                                                    .gradientInputDecoration()
                                                    .copyWith(
                                                      hintText: "Your Name",
                                                    ),
                                                onTap: () {
                                                  SharedPrefs.hapticInputSelect();
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: styling.secondary,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  SharedPrefs.hapticButtonPress();
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Local Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Nordic Dash Local",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.dash,
                                                                    maxPlayers:
                                                                        8,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Online Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Nordic Dash Online",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.dash,
                                                                    maxPlayers:
                                                                        8,
                                                                    isOnline:
                                                                        true,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                        ActionButton(
                          height: 60,
                          width: buttonWidth,
                          text: Text(
                            'Euchre',
                            style: TextStyle(
                              color:
                                  Colors
                                      .white, // This will be masked by the gradient
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final myController = TextEditingController();
                                if (lastUsedName.isNotEmpty) {
                                  myController.text = lastUsedName;
                                }
                                return Dialog(
                                  backgroundColor: Colors.transparent,

                                  child: Container(
                                    width: 400,

                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          styling.primary,
                                          styling.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        2,
                                      ), // Creates the border thickness
                                      decoration: BoxDecoration(
                                        color: styling.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                            "Enter Your Name",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GradientInputField(
                                              textField: TextField(
                                                controller: myController,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: styling
                                                    .gradientInputDecoration()
                                                    .copyWith(
                                                      hintText: "Your Name",
                                                    ),
                                                onTap: () {
                                                  SharedPrefs.hapticInputSelect();
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: styling.secondary,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  SharedPrefs.hapticButtonPress();
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Local Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Euchre Local",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.euchre,
                                                                    requiredPlayers:
                                                                        4,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Online Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Euchre Online",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.euchre,
                                                                    requiredPlayers:
                                                                        4,
                                                                    isOnline:
                                                                        true,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ActionButton(
                          height: 60,
                          width: buttonWidth,
                          showNewIndicator: true,
                          game: Game.crazyEights,
                          text: Text(
                            'Crazy Eights',
                            style: TextStyle(
                              color:
                                  Colors
                                      .white, // This will be masked by the gradient
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final myController = TextEditingController();
                                if (lastUsedName.isNotEmpty) {
                                  myController.text = lastUsedName;
                                }
                                return Dialog(
                                  backgroundColor: Colors.transparent,

                                  child: Container(
                                    width: 400,

                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          styling.primary,
                                          styling.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        2,
                                      ), // Creates the border thickness
                                      decoration: BoxDecoration(
                                        color: styling.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                            "Enter Your Name",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GradientInputField(
                                              textField: TextField(
                                                controller: myController,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: styling
                                                    .gradientInputDecoration()
                                                    .copyWith(
                                                      hintText: "Your Name",
                                                    ),
                                                onTap: () {
                                                  SharedPrefs.hapticInputSelect();
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: styling.secondary,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  SharedPrefs.hapticButtonPress();
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Local Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Crazy Eights Local",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          SharedPrefs.addNewGamesSeen(
                                                            Game.crazyEights,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.crazyEights,
                                                                    maxPlayers:
                                                                        5,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Online Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Crazy Eights Online",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          SharedPrefs.addNewGamesSeen(
                                                            Game.crazyEights,
                                                          );
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.crazyEights,
                                                                    maxPlayers:
                                                                        5,
                                                                    isOnline:
                                                                        true,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ActionButton(
                          height: 60,
                          width: buttonWidth,
                          showNewIndicator: true,
                          game: Game.kalamattack,
                          text: Text(
                            'Kalamattack',
                            style: TextStyle(
                              color:
                                  Colors
                                      .white, // This will be masked by the gradient
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                final myController = TextEditingController();
                                if (lastUsedName.isNotEmpty) {
                                  myController.text = lastUsedName;
                                }
                                return Dialog(
                                  backgroundColor: Colors.transparent,

                                  child: Container(
                                    width: 400,

                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          styling.primary,
                                          styling.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(
                                        2,
                                      ), // Creates the border thickness
                                      decoration: BoxDecoration(
                                        color: styling.background,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 12),
                                          Text(
                                            "Enter Your Name",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GradientInputField(
                                              textField: TextField(
                                                controller: myController,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                decoration: styling
                                                    .gradientInputDecoration()
                                                    .copyWith(
                                                      hintText: "Your Name",
                                                    ),
                                                onTap: () {
                                                  SharedPrefs.hapticInputSelect();
                                                },
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              TextButton(
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                    color: styling.secondary,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  SharedPrefs.hapticButtonPress();
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              Column(
                                                children: [
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Local Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Kalamatack Local",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          SharedPrefs.addNewGamesSeen(
                                                            Game.kalamattack,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.kalamattack,
                                                                    maxPlayers:
                                                                        5,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 128,

                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8.0,
                                                          ),
                                                      child: SolidActionButton(
                                                        text: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            "Create Online Game",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors
                                                                      .white, // This will be masked by the gradient
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),

                                                            textAlign:
                                                                TextAlign
                                                                    .center,
                                                          ),
                                                        ),
                                                        onTap: () {
                                                          if (myController
                                                              .text
                                                              .isEmpty) {
                                                            showSnackBar(
                                                              context,
                                                              Colors.red,
                                                              "Please enter a name",
                                                            );
                                                            return;
                                                          }
                                                          analytics
                                                              .logSelectGameEvent(
                                                                "Kalamatack Online",
                                                              );
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          SharedPrefs.addNewGamesSeen(
                                                            Game.kalamattack,
                                                          );
                                                          Navigator.of(
                                                            context,
                                                          ).pop();
                                                          // Navigate to the browser screen with the room code
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => CreateRoomScreen(
                                                                    userName:
                                                                        myController
                                                                            .text,
                                                                    game:
                                                                        Game.kalamattack,
                                                                    maxPlayers:
                                                                        5,
                                                                    isOnline:
                                                                        true,
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        ActionButton(
                          height: 60,
                          width: buttonWidth,
                          text: Text(
                            'Solitaire',
                            style: TextStyle(
                              color:
                                  Colors
                                      .white, // This will be masked by the gradient
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          onTap: () {
                            analytics.logSelectGameEvent("Solitaire");
                            nextScreen(
                              context,
                              Solitare(
                                player: GamePlayer(
                                  id: "host",
                                  name: lastUsedName,
                                  isHost: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,

                        child: IconButton(
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: styling.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          onPressed: () {
                            analytics.logViewHelpEvent();
                            SharedPrefs.hapticButtonPress();
                            showHowSheet();
                          },

                          icon: Icon(
                            Icons.question_mark_outlined,
                            color: styling.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        height: 48,

                        child: IconButton(
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: styling.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          onPressed: () {
                            analytics.logViewSettingsEvent();
                            SharedPrefs.hapticButtonPress();
                            nextScreen(context, SettingsPage());
                          },

                          icon: Icon(
                            Icons.settings_outlined,
                            color: styling.primary,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        height: 48,

                        child: IconButton(
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: styling.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(4.0),
                          onPressed: () {
                            analytics.logViewStatsEvent();
                            SharedPrefs.hapticButtonPress();
                            nextScreen(context, StatsPage());
                          },

                          icon: Icon(
                            Icons.leaderboard_outlined,
                            color: styling.primary,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showWhatsNew) const SizedBox(height: 16),
                  if (showWhatsNew)
                    WhatsNew(
                      onClose: () async {
                        PackageInfo packageInfo =
                            await PackageInfo.fromPlatform();
                        String currentBuildNumber = packageInfo.buildNumber;
                        await SharedPrefs.setNewestSeenVersion(
                          currentBuildNumber,
                        );
                        setState(() {
                          showWhatsNew = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
