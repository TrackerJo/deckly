import 'package:deckly/api/shared_prefs.dart';
import 'package:deckly/constants.dart';
import 'package:deckly/main.dart';
import 'package:deckly/widgets/custom_app_bar.dart';
import 'package:deckly/widgets/fancy_border.dart';
import 'package:deckly/widgets/fancy_widget.dart';
import 'package:deckly/widgets/orientation_checker.dart';
import 'package:flutter/material.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int nertzRoundsPlayed = 0;
  int nertzRoundsNertzed = 0;
  int nertzGamesWon = 0;
  double nertzAveragePlaySpeed = 0;

  int blitzRoundsPlayed = 0;
  int blitzRoundsBlitzed = 0;
  int blitzGamesWon = 0;
  double blitzAveragePlaySpeed = 0;

  int euchreGamesPlayed = 0;
  int euchreGamesWon = 0;

  int solitaireGamesWon = 0;
  void getStats() async {
    nertzRoundsPlayed = await SharedPrefs.getNertzRoundsPlayed();
    nertzRoundsNertzed = await SharedPrefs.getNertzRoundsNertzed();
    nertzGamesWon = await SharedPrefs.getNertzGamesWon();
    nertzAveragePlaySpeed = await SharedPrefs.getNertzAveragePlaySpeed();

    blitzRoundsPlayed = await SharedPrefs.getBlitzRoundsPlayed();
    blitzRoundsBlitzed = await SharedPrefs.getBlitzRoundsBlitzed();
    blitzGamesWon = await SharedPrefs.getBlitzGamesWon();
    blitzAveragePlaySpeed = await SharedPrefs.getBlitzAveragePlaySpeed();

    euchreGamesPlayed = await SharedPrefs.getEuchreGamesPlayed();
    euchreGamesWon = await SharedPrefs.getEuchreGamesWon();

    solitaireGamesWon = await SharedPrefs.getSolitaireGamesWon();

    // You can use these values to update your UI or perform other actions

    setState(() {
      // Update the state to reflect the fetched stats
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getStats();
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
            title: "Stats",
            showBackButton: true,
            onBackButtonPressed: (context) {
              Navigator.pop(context);
            },
          ),
        ),
        backgroundColor: styling.background,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FancyBorder(
                    child: ListTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      title: FancyWidget(
                        child: const Text(
                          "Nertz Stats",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        "Rounds Played: $nertzRoundsPlayed\nRounds Nertzed: $nertzRoundsNertzed\nGames Won: $nertzGamesWon${nertzAveragePlaySpeed > 0 ? "\nAverage Play Speed: ${nertzAveragePlaySpeed.toStringAsFixed(2)} seconds" : ""}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
                      title: FancyWidget(
                        child: const Text(
                          "Nordic Dash Stats",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        "Rounds Played: $blitzRoundsPlayed\nRounds Dashed: $blitzRoundsBlitzed\nGames Won: $blitzGamesWon${blitzAveragePlaySpeed > 0 ? "\nAverage Play Speed: ${blitzAveragePlaySpeed.toStringAsFixed(2)} seconds" : ""}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
                      title: FancyWidget(
                        child: const Text(
                          "Euchre Stats",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        "Games Played: $euchreGamesPlayed\nGames Won: $euchreGamesWon",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
                      title: FancyWidget(
                        child: const Text(
                          "Solitaire Stats",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        "Games Won: $solitaireGamesWon",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
