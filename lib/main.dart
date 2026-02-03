// main.dart

import 'dart:async';
import 'dart:io';

import 'package:deckly/api/analytics.dart';
import 'package:deckly/api/auth.dart';
import 'package:deckly/api/connection_service.dart';
import 'package:deckly/api/remote_config.dart';
import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';

import 'package:deckly/pages/home_screen.dart';
import 'package:deckly/pages/kalamattack.dart';
import 'package:deckly/pages/update_page.dart';

import 'package:deckly/styling.dart';
import 'package:deckly/widgets/action_button.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/solid_action_button.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:has_dynamic_island/has_dynamic_island.dart';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'firebase_options.dart';

final Styling styling = Styling();
final ConnectionService connectionService = ConnectionService();
final Analytics analytics = Analytics();

final bluetoothDataStream = StreamController<Payload>.broadcast();
final bluetoothStateStream = StreamController.broadcast();
final RateAppHelper rateAppHelper = RateAppHelper();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

/// Simple model for a player

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool requiresUpdate = false;

  void checkAuth() async {
    final auth = Auth();
    if (!auth.isLoggedIn()) {
      await auth.login();
    }
  }

  void checkForUpdates() async {
    UpdateStatus updateStatus = await RemoteConfig().checkUpdates();
    HasDynamicIsland dynamicIsland = HasDynamicIsland();
    bool hasDynamicIsland = await dynamicIsland.hasDynamicIsland();
    if (updateStatus == UpdateStatus.available) {
      showOverlayNotification((context) {
        return Column(
          children: [
            if (hasDynamicIsland) const SizedBox(height: 48),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [styling.primary, styling.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                margin: EdgeInsets.all(2), // Creates the border thickness
                decoration: BoxDecoration(
                  color: styling.background,
                  borderRadius: BorderRadius.circular(
                    6,
                  ), // Slightly smaller radius
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: styling.secondary.withOpacity(0.3),
                    onTap: () {
                      OverlaySupportEntry.of(context)!.dismiss();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Leading icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.asset("assets/icon.png"),
                          ),
                          const SizedBox(width: 16),
                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "New Update Available!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "There's a new version of Deckly available.\nTap to dismiss.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Trailing close button
                          SolidActionButton(
                            width: 100,
                            height: 36,

                            text: Text(
                              "Update",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () async {
                              OverlaySupportEntry.of(context)!.dismiss();
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
                                        title: const Text(
                                          "Unable to open app store",
                                        ),
                                        content: const Text(
                                          "Please try again later.",
                                        ),
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
                                      title: const Text(
                                        "Unable to open app store",
                                      ),
                                      content: const Text(
                                        "Please try again later.",
                                      ),
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
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }, duration: const Duration(milliseconds: 0));
    } else if (updateStatus == UpdateStatus.required) {
      setState(() {
        requiresUpdate = true;
      });
    }
  }

  void checkIfRateOrShare() async {
    await SharedPrefs.incrementAppLaunchCount();
    int launchCount = await SharedPrefs.getAppLaunchCount();
    DateTime dateOpened = await SharedPrefs.getFirstOpenDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(dateOpened);

    HasDynamicIsland dynamicIsland = HasDynamicIsland();
    bool hasDynamicIsland = await dynamicIsland.hasDynamicIsland();

    bool hasRatedApp = await SharedPrefs.getSeenRateApp();
    print("DAY DIFFERENCE: ${difference.inDays}");

    if ((!hasRatedApp) && launchCount >= 5 && difference.inDays >= 2) {
      await rateAppHelper.initialize();
      showOverlayNotification((context) {
        return Column(
          children: [
            if (hasDynamicIsland) const SizedBox(height: 48),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [styling.primary, styling.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                margin: EdgeInsets.all(2), // Creates the border thickness
                decoration: BoxDecoration(
                  color: styling.background,
                  borderRadius: BorderRadius.circular(
                    6,
                  ), // Slightly smaller radius
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: styling.secondary.withOpacity(0.3),
                    onTap: () {
                      OverlaySupportEntry.of(context)!.dismiss();
                      SharedPrefs.setSeenRateApp(true);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Leading icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.asset("assets/icon.png"),
                          ),
                          const SizedBox(width: 16),
                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Rate Deckly!",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "If you enjoy using Deckly, please take a moment to rate us on the app store.\nTap to dismiss.",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Trailing close button
                          SolidActionButton(
                            width: 100,
                            height: 36,

                            text: Text(
                              "Rate",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () async {
                              OverlaySupportEntry.of(context)!.dismiss();
                              analytics.logRateAppEvent();
                              await SharedPrefs.setSeenRateApp(true);
                              rateAppHelper.launchStore();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }, duration: const Duration(milliseconds: 0));
    }

    bool hasSeenShareApp = await SharedPrefs.getSeenShareApp();
    if (hasRatedApp &&
        launchCount >= 7 &&
        difference.inDays >= 3 &&
        !hasSeenShareApp) {
      showOverlayNotification((context) {
        bool isRatingApp = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                if (hasDynamicIsland) const SizedBox(height: 48),
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  padding: const EdgeInsets.all(0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [styling.primary, styling.secondary],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    margin: EdgeInsets.all(2), // Creates the border thickness
                    decoration: BoxDecoration(
                      color: styling.background,
                      borderRadius: BorderRadius.circular(
                        6,
                      ), // Slightly smaller radius
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        splashColor: styling.secondary.withOpacity(0.3),
                        onTap: () {
                          OverlaySupportEntry.of(context)!.dismiss();
                          SharedPrefs.setSeenShareApp(true);
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Leading icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                clipBehavior: Clip.hardEdge,
                                child: Image.asset("assets/icon.png"),
                              ),
                              const SizedBox(width: 16),
                              // Title and subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Share Deckly with a Friend!",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "If you enjoy using Deckly, please share it with a friend.\nTap to dismiss.",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Trailing close button
                              if (isRatingApp)
                                //Loading indicator
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              else
                                SolidActionButton(
                                  width: 100,
                                  height: 36,

                                  text: Text(
                                    "Share",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () async {
                                    setState(() {
                                      isRatingApp = true;
                                    });
                                    analytics.logShareAppEvent();
                                    Uri sms = Uri.parse(
                                      'https://apps.apple.com/us/app/deckly-cards-with-friends/id6746527909',
                                    );
                                    final SharePlus sharePlus =
                                        SharePlus.instance;
                                    await sharePlus.share(
                                      ShareParams(
                                        text:
                                            "Check out Deckly, a fun card game app! Download it here: $sms",
                                        subject: "Deckly - Cards with Friends",
                                      ),
                                    );
                                    await SharedPrefs.setSeenShareApp(true);

                                    OverlaySupportEntry.of(context)!.dismiss();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }, duration: const Duration(milliseconds: 0));
    }
  }

  void checkPrivacyPolicy() async {
    bool hasSeenPrivacyPolicy = await SharedPrefs.getSeenPrivacyPolicy();
    if (!hasSeenPrivacyPolicy) {
      showOverlayNotification((context) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [styling.primary, styling.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                margin: EdgeInsets.all(2), // Creates the border thickness
                decoration: BoxDecoration(
                  color: styling.background,
                  borderRadius: BorderRadius.circular(
                    6,
                  ), // Slightly smaller radius
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: styling.secondary.withOpacity(0.3),
                    onTap: () {},
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Leading icon
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Image.asset("assets/icon.png"),
                          ),
                          const SizedBox(width: 16),
                          // Title and subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "New Privacy Policy",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: TextSpan(
                                    text: "Please review our ",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
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
                                                OverlaySupportEntry.of(
                                                  context,
                                                )!.dismiss();
                                                SharedPrefs.setSeenPrivacyPolicy(
                                                  true,
                                                );
                                                // Open privacy policy link
                                                launchUrl(
                                                  Uri.parse(
                                                    'https://trackerjo.github.io/DecklyPrivacy/',
                                                  ),
                                                );
                                              },
                                      ),
                                      TextSpan(
                                        text:
                                            ". Deckly uses Google Analytics to collect anonymous usage data to improve the app. No personal information is collected. You can disable analytics in settings at any time.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Trailing close button
                          IconButton(
                            onPressed: () {
                              SharedPrefs.hapticButtonPress();
                              OverlaySupportEntry.of(context)!.dismiss();
                              SharedPrefs.setSeenPrivacyPolicy(true);
                            },
                            icon: Icon(Icons.check, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }, duration: const Duration(milliseconds: 0));
    }
  }

  void getIsNewUser() async {
    bool isNewUser = await SharedPrefs.getNewUser();
    if (isNewUser) {
      print("New User Detected");
      for (Game game in Game.values) {
        await SharedPrefs.addNewGamesSeen(game);
      }
      await SharedPrefs.setNewUser(false);
    }
  }

  @override
  void initState() {
    SharedPrefs.initializeNewGamesStream();

    // TODO: implement initState
    super.initState();
    getIsNewUser();
    checkAuth();

    checkForUpdates();
    checkIfRateOrShare();
    checkPrivacyPolicy();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    connectionService.dispose();
    SharedPrefs.disposeNewGamesStream();
  }

  void onUpdate() {
    setState(() {
      requiresUpdate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //Run Fucntion after the build is complete

    return OverlaySupport(
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
        child: MaterialApp(
          title: 'Deckly',
          theme: ThemeData(primarySwatch: Colors.purple),
          debugShowCheckedModeBanner: false,
          navigatorObservers: [analytics.observer],
          home: requiresUpdate ? UpdatePage(onUpdate: onUpdate) : HomeScreen(),
          // home: Kalamattack(
          //   player: GamePlayer(
          //     id: "Deckly-test-1704-host",
          //     name: "test",
          //     isHost: true,
          //   ),
          //   players: [
          //     GamePlayer(
          //       id: "Deckly-test-1704-host",
          //       name: "test",
          //       isHost: true,
          //     ),
          //     BotPlayer(
          //       id: "Deckly-test3-1704",
          //       name: "Test Bot",
          //       difficulty: BotDifficulty.hard,
          //     ),
          //     BotPlayer(
          //       id: "Deckly-test4-1704",
          //       name: "Test Bot 2",
          //       difficulty: BotDifficulty.hard,
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }
}

/// Home chooses Create vs Join
