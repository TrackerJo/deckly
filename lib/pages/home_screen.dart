import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/widgets/gradient_input_field.dart';
import 'package:deckly/widgets/solid_action_button.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/create_room_screen.dart';
import 'package:deckly/pages/join_room_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
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
                    ActionButton(
                      label: 'Create Room',
                      onTap:
                          () => showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              final myController = TextEditingController();
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
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.all(
                                      2,
                                    ), // Creates the border thickness
                                    decoration: BoxDecoration(
                                      color: styling.backgroundColor,
                                      borderRadius: BorderRadius.circular(10),
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
                                                  color: styling.secondaryColor,
                                                ),
                                              ),
                                              onPressed: () {
                                                SharedPrefs.hapticButtonPress();
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            SizedBox(
                                              width: 128,

                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  8.0,
                                                ),
                                                child: SolidActionButton(
                                                  label: "Create Room",
                                                  onTap: () {
                                                    SharedPrefs.hapticButtonPress();
                                                    Navigator.of(context).pop();
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
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            // TextButton(
                                            //   child: Text(
                                            //     "Create Room",
                                            //     style: TextStyle(
                                            //       color: styling.secondaryColor,
                                            //     ),
                                            //   ),
                                            //   onPressed: () {
                                            //     // Close the dialog
                                            //     Navigator.of(context).pop();
                                            //     // Navigate to the browser screen with the room code
                                            //     Navigator.push(
                                            //       context,
                                            //       MaterialPageRoute(
                                            //         builder:
                                            //             (_) => CreateRoomScreen(
                                            //               userName:
                                            //                   myController.text,
                                            //             ),
                                            //       ),
                                            //     );
                                            //   },
                                            // ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    ),
                    const SizedBox(height: 16),
                    ActionButton(
                      label: 'Join Room',
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => JoinRoomScreen()),
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
