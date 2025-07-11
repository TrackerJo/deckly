import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/orientation_checker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  HapticLevel hapticFeedback = HapticLevel.medium;
  bool allowAnalytics = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SharedPrefs.getHapticSettings().then((value) {
      setState(() {
        hapticFeedback = value;
      });
    });
    analytics.isAnalyticsEnabled().then((value) {
      setState(() {
        allowAnalytics = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrientationChecker(
      allowedOrientations: [
        Orientation.portrait,
        if (isTablet(context)) Orientation.landscape,
      ],
      child: Scaffold(
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
        backgroundColor: styling.background,
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
                          fillColor: styling.primary,
                        ),
                        dropdownColor: styling.background,
                        iconEnabledColor: styling.primary,
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
                          HapticLevel hapticLevel = HapticLevel.fromString(
                            value,
                          );
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FancyBorder(
                  child: ListTile(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    title: const Text(
                      "Allow Anonymous Analytics Tracking",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "Help us improve the app by allowing us to collect anonymous usage data.",
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: Switch(
                      value: allowAnalytics,
                      onChanged: (value) async {
                        await SharedPrefs.hapticInputSelect();
                        await SharedPrefs.setAnalyticsEnabled(value);
                        setState(() {
                          allowAnalytics = value;
                        });
                        analytics.setAnalyticsEnabled(value);
                      },
                      activeColor: styling.primary,
                      activeTrackColor: styling.primary.withOpacity(0.5),
                      inactiveTrackColor: Colors.white.withOpacity(0.2),
                      inactiveThumbColor: styling.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              //Rich text for privacy policy and terms of service
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "By using this app, you agree to our ",
                    style: const TextStyle(color: Colors.white, fontSize: 14),

                    children: [
                      TextSpan(
                        text: "Privacy Policy",
                        style: TextStyle(
                          color: styling.primary,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap = () {
                                // Open privacy policy link
                                launchUrl(
                                  Uri.parse(
                                    'https://trackerjo.github.io/DecklyPrivacy/',
                                  ),
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
