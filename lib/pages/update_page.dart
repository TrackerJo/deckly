import 'dart:io';

import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/main.dart';
import 'package:deckly/pages/home_screen.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';

class UpdatePage extends StatefulWidget {
  final Function() onUpdate;
  const UpdatePage({super.key, required this.onUpdate});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: styling.background,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(title: 'Update', showBackButton: false),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                "An update is available! Please update the app to continue.",
                style: TextStyle(fontSize: 30, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ActionButton(
                width: 200,
                height: 50,
                onTap: () async {
                  Uri sms = Uri.parse(
                    'https://apps.apple.com/us/app/deckly-cards-with-friends/id6746527909',
                  );
                  if (Platform.isAndroid) {
                    sms = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.kazoom.deckly',
                    );
                  }
                  try {
                    if (await launchUrl(sms)) {
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Unable to open app store"),
                            content: const Text("Please try again later."),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  await SharedPrefs.hapticButtonPress();

                                  Navigator.of(context).pop();
                                },
                                child: const Text("Okay"),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } catch (e) {
                    print("Error launching URL: $e");
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Unable to open app store"),
                          content: const Text("Please try again later."),
                          actions: [
                            TextButton(
                              onPressed: () async {
                                await SharedPrefs.hapticButtonPress();

                                Navigator.of(context).pop();
                              },
                              child: const Text("Okay"),
                            ),
                          ],
                        );
                      },
                    );
                  }
                  widget.onUpdate();
                },

                text: Text("Update", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
