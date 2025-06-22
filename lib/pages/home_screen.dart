import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/pages/settings_page.dart';

import 'package:deckly/widgets/gradient_input_field.dart';
import 'package:deckly/widgets/solid_action_button.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/create_room_screen.dart';
import 'package:deckly/pages/join_room_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String lastUsedName = "";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: styling.background,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: ShaderMask(
                  shaderCallback:
                      (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [styling.primary, styling.secondary],
                      ).createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
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
              ),

              Positioned(
                top: 220,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    ActionButton(
                      text: Text(
                        'Join Local Game',
                        style: TextStyle(
                          color:
                              Colors
                                  .white, // This will be masked by the gradient
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JoinRoomScreen()),
                          ),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: ActionButton(
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
                                    final myController =
                                        TextEditingController();
                                    if (lastUsedName.isNotEmpty) {
                                      myController.text = lastUsedName;
                                    }
                                    return Dialog(
                                      backgroundColor: Colors.transparent,

                                      child: Container(
                                        width: 400,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              styling.primary,
                                              styling.secondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Container(
                                          margin: EdgeInsets.all(
                                            2,
                                          ), // Creates the border thickness
                                          decoration: BoxDecoration(
                                            color: styling.background,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Enter Your Name",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
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
                                                        color:
                                                            styling.secondary,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      SharedPrefs.hapticButtonPress();
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
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
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ActionButton(
                              text: Text(
                                'Dutch Blitz',
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
                                    final myController =
                                        TextEditingController();
                                    if (lastUsedName.isNotEmpty) {
                                      myController.text = lastUsedName;
                                    }
                                    return Dialog(
                                      backgroundColor: Colors.transparent,

                                      child: Container(
                                        width: 400,
                                        height: 200,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              styling.primary,
                                              styling.secondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Container(
                                          margin: EdgeInsets.all(
                                            2,
                                          ), // Creates the border thickness
                                          decoration: BoxDecoration(
                                            color: styling.background,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                "Enter Your Name",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
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
                                                        color:
                                                            styling.secondary,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      SharedPrefs.hapticButtonPress();
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
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
                                                          SharedPrefs.setLastUsedName(
                                                            myController.text,
                                                          );
                                                          setState(() {
                                                            lastUsedName =
                                                                myController
                                                                    .text;
                                                          });
                                                          SharedPrefs.hapticButtonPress();
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
                                                                        Game.blitz,
                                                                    maxPlayers:
                                                                        8,
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
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // Expanded(
                          //   child: ActionButton(
                          //     text: Text(
                          //       'Euchre',
                          //       style: TextStyle(
                          //         color:
                          //             Colors
                          //                 .white, // This will be masked by the gradient
                          //         fontSize: 14,
                          //         fontWeight: FontWeight.bold,
                          //       ),
                          //       textAlign: TextAlign.center,
                          //     ),
                          //     onTap: () {
                          //       showDialog(
                          //         context: context,
                          //         builder: (BuildContext context) {
                          //           final myController =
                          //               TextEditingController();
                          //           if (lastUsedName.isNotEmpty) {
                          //             myController.text = lastUsedName;
                          //           }
                          //           return Dialog(
                          //             backgroundColor: Colors.transparent,

                          //             child: Container(
                          //               width: 400,
                          //               height: 200,
                          //               decoration: BoxDecoration(
                          //                 gradient: LinearGradient(
                          //                   begin: Alignment.topLeft,
                          //                   end: Alignment.bottomRight,
                          //                   colors: [
                          //                     styling.primary,
                          //                     styling.secondary,
                          //                   ],
                          //                 ),
                          //                 borderRadius: BorderRadius.circular(
                          //                   12,
                          //                 ),
                          //               ),
                          //               child: Container(
                          //                 margin: EdgeInsets.all(
                          //                   2,
                          //                 ), // Creates the border thickness
                          //                 decoration: BoxDecoration(
                          //                   color: styling.background,
                          //                   borderRadius: BorderRadius.circular(
                          //                     10,
                          //                   ),
                          //                 ),
                          //                 child: Column(
                          //                   mainAxisSize: MainAxisSize.min,
                          //                   mainAxisAlignment:
                          //                       MainAxisAlignment.center,
                          //                   crossAxisAlignment:
                          //                       CrossAxisAlignment.center,
                          //                   children: [
                          //                     Text(
                          //                       "Enter Your Name",
                          //                       style: TextStyle(
                          //                         color: Colors.white,
                          //                         fontSize: 24,
                          //                         fontWeight: FontWeight.bold,
                          //                       ),
                          //                     ),
                          //                     Padding(
                          //                       padding: const EdgeInsets.all(
                          //                         8.0,
                          //                       ),
                          //                       child: GradientInputField(
                          //                         textField: TextField(
                          //                           controller: myController,
                          //                           style: TextStyle(
                          //                             color: Colors.white,
                          //                           ),
                          //                           decoration: styling
                          //                               .gradientInputDecoration()
                          //                               .copyWith(
                          //                                 hintText: "Your Name",
                          //                               ),
                          //                           onTap: () {
                          //                             SharedPrefs.hapticInputSelect();
                          //                           },
                          //                         ),
                          //                       ),
                          //                     ),
                          //                     Row(
                          //                       mainAxisAlignment:
                          //                           MainAxisAlignment.end,
                          //                       children: [
                          //                         TextButton(
                          //                           child: Text(
                          //                             "Cancel",
                          //                             style: TextStyle(
                          //                               color:
                          //                                   styling.secondary,
                          //                             ),
                          //                           ),
                          //                           onPressed: () {
                          //                             SharedPrefs.hapticButtonPress();
                          //                             Navigator.of(
                          //                               context,
                          //                             ).pop();
                          //                           },
                          //                         ),
                          //                         SizedBox(
                          //                           width: 128,

                          //                           child: Padding(
                          //                             padding:
                          //                                 const EdgeInsets.all(
                          //                                   8.0,
                          //                                 ),
                          //                             child: SolidActionButton(
                          //                               text: Padding(
                          //                                 padding:
                          //                                     const EdgeInsets.all(
                          //                                       8.0,
                          //                                     ),
                          //                                 child: Text(
                          //                                   "Create Local Game",
                          //                                   style: TextStyle(
                          //                                     color:
                          //                                         Colors
                          //                                             .white, // This will be masked by the gradient
                          //                                     fontSize: 14,
                          //                                     fontWeight:
                          //                                         FontWeight
                          //                                             .bold,
                          //                                   ),
                          //                                   textAlign:
                          //                                       TextAlign
                          //                                           .center,
                          //                                 ),
                          //                               ),
                          //                               onTap: () {
                          //                                 if (myController
                          //                                     .text
                          //                                     .isEmpty) {
                          //                                  showSnackBar(
                          //                                     context,
                          //                                      Colors.red,
                          //                                     "Please enter a name",

                          //                                   );
                          //                                   return;
                          //                                 }
                          //                                 SharedPrefs.setLastUsedName(
                          //                                   myController.text,
                          //                                 );
                          //                                 setState(() {
                          //                                   lastUsedName =
                          //                                       myController
                          //                                           .text;
                          //                                 });
                          //                                 SharedPrefs.hapticButtonPress();
                          //                                 Navigator.of(
                          //                                   context,
                          //                                 ).pop();
                          //                                 // Navigate to the browser screen with the room code
                          //                                 Navigator.push(
                          //                                   context,
                          //                                   MaterialPageRoute(
                          //                                     builder:
                          //                                         (
                          //                                           _,
                          //                                         ) => CreateRoomScreen(
                          //                                           userName:
                          //                                               myController
                          //                                                   .text,
                          //                                           game:
                          //                                               Game.euchre,
                          //                                           requiredPlayers:
                          //                                               4,
                          //                                         ),
                          //                                   ),
                          //                                 );
                          //                               },
                          //                             ),
                          //                           ),
                          //                         ),
                          //                       ],
                          //                     ),
                          //                   ],
                          //                 ),
                          //               ),
                          //             ),
                          //           );
                          //         },
                          //       );
                          //     },
                          //   ),
                          // ),
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
