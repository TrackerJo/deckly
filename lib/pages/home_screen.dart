import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/widgets/fancy_text.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: styling.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24),
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
                        colors: [styling.primaryColor, styling.secondaryColor],
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
                    // ActionButton(
                    //   text: Text(
                    //     'Create Room',
                    //     style: TextStyle(
                    //       color:
                    //           Colors
                    //               .white, // This will be masked by the gradient
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //     textAlign: TextAlign.center,
                    //   ),
                    //   onTap:
                    //       () => showDialog(
                    //         context: context,
                    //         builder: (BuildContext context) {
                    //           final myController = TextEditingController();
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
                    //                     styling.primaryColor,
                    //                     styling.secondaryColor,
                    //                   ],
                    //                 ),
                    //                 borderRadius: BorderRadius.circular(12),
                    //               ),
                    //               child: Container(
                    //                 margin: EdgeInsets.all(
                    //                   2,
                    //                 ), // Creates the border thickness
                    //                 decoration: BoxDecoration(
                    //                   color: styling.backgroundColor,
                    //                   borderRadius: BorderRadius.circular(10),
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
                    //                       padding: const EdgeInsets.all(8.0),
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
                    //                               color: styling.secondaryColor,
                    //                             ),
                    //                           ),
                    //                           onPressed: () {
                    //                             SharedPrefs.hapticButtonPress();
                    //                             Navigator.of(context).pop();
                    //                           },
                    //                         ),
                    //                         SizedBox(
                    //                           width: 128,

                    //                           child: Padding(
                    //                             padding: const EdgeInsets.all(
                    //                               8.0,
                    //                             ),
                    //                             child: SolidActionButton(
                    //                               text: Text(
                    //                                 "Create Room",
                    //                                 style: TextStyle(
                    //                                   color:
                    //                                       Colors
                    //                                           .white, // This will be masked by the gradient
                    //                                   fontSize: 14,
                    //                                   fontWeight:
                    //                                       FontWeight.bold,
                    //                                 ),
                    //                                 textAlign: TextAlign.center,
                    //                               ),
                    //                               onTap: () {
                    //                                 SharedPrefs.hapticButtonPress();
                    //                                 Navigator.of(context).pop();
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
                    //                                         ),
                    //                                   ),
                    //                                 );
                    //                               },
                    //                             ),
                    //                           ),
                    //                         ),
                    //                         // TextButton(
                    //                         //   child: Text(
                    //                         //     "Create Room",
                    //                         //     style: TextStyle(
                    //                         //       color: styling.secondaryColor,
                    //                         //     ),
                    //                         //   ),
                    //                         //   onPressed: () {
                    //                         //     // Close the dialog
                    //                         //     Navigator.of(context).pop();
                    //                         //     // Navigate to the browser screen with the room code
                    //                         //     Navigator.push(
                    //                         //       context,
                    //                         //       MaterialPageRoute(
                    //                         //         builder:
                    //                         //             (_) => CreateRoomScreen(
                    //                         //               userName:
                    //                         //                   myController.text,
                    //                         //             ),
                    //                         //       ),
                    //                         //     );
                    //                         //   },
                    //                         // ),
                    //                       ],
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             ),
                    //           );
                    //         },
                    //       ),
                    // ),
                    // const SizedBox(height: 16),
                    ActionButton(
                      text: Text(
                        'Join Game',
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
                          child: Divider(
                            color: styling.primaryColor,
                            thickness: 2,
                          ),
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
                          child: Divider(
                            color: styling.primaryColor,
                            thickness: 2,
                          ),
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
                                              styling.primaryColor,
                                              styling.secondaryColor,
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
                                            color: styling.backgroundColor,
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
                                                            styling
                                                                .secondaryColor,
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
                                                        text: Text(
                                                          "Create Game",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .white, // This will be masked by the gradient
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        onTap: () {
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
                                              styling.primaryColor,
                                              styling.secondaryColor,
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
                                            color: styling.backgroundColor,
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
                                                            styling
                                                                .secondaryColor,
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
                                                        text: Text(
                                                          "Create Game",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .white, // This will be masked by the gradient
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        onTap: () {
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
                                    final myController =
                                        TextEditingController();
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
                                              styling.primaryColor,
                                              styling.secondaryColor,
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
                                            color: styling.backgroundColor,
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
                                                            styling
                                                                .secondaryColor,
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
                                                        text: Text(
                                                          "Create Game",
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .white, // This will be masked by the gradient
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        onTap: () {
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
                                                                        Game.euchre,
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
                        ],
                      ),
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
