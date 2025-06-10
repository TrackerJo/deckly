import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  HapticLevel hapticFeedback = HapticLevel.medium;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SharedPrefs.getHapticSettings().then((value) {
      setState(() {
        hapticFeedback = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: "Settings",
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FancyBorder(
                child: ListTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),

                  title: const Text(
                    "Haptic Feedback Intensity",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Choose the intensity of the haptic feedback (the vibration when you interact with the app)",
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: SizedBox(
                    width: 110,
                    child: DropdownButtonFormField(
                      value: hapticFeedback.toString() ?? "medium",
                      decoration: styling.textInputDecoration().copyWith(
                        fillColor: styling.primaryColor,
                      ),
                      dropdownColor: styling.backgroundColor,
                      iconEnabledColor: styling.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                      items:
                          ["heavy", "medium", "light", "none"].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                      onTap: () async {
                        await SharedPrefs.hapticInputSelect();
                      },
                      onChanged: (String? value) async {
                        if (value == null) return;
                        await SharedPrefs.hapticButtonPress();
                        HapticLevel hapticLevel = HapticLevel.fromString(value);
                        await SharedPrefs.setHapticSettings(hapticLevel);
                        setState(() {
                          hapticFeedback = hapticLevel;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
