import 'dart:async';

import 'package:deckly/constants.dart';

import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

// import 'package:image_downloader/image_downloader.dart';

class SharedPrefs {
  static String hapticSettingsKey = "HAPTICSETTINGSKEY";
  static String lastUsedNameKey = "LASTUSEDNAMEKEY";
  static String firstUseKey = "FIRSTUSEKEY";
  static String newUserKey = "NEWUSERKEY";

  static String nertzRoundsPlayedKey = "NERTZROUNDSPLAYEDKEY";
  static String nertzRoundsNertzedKey = "NERTZROUNDSNERTZEDKEY";
  static String nertzGamesWonKey = "NERTZGAMESWONKEY";
  static String nertzPlaySpeedKey = "NERTZPLAYSPEEDKEY";

  static String blitzRoundsPlayedKey = "BLITZROUNDSPLAYEDKEY";
  static String blitzRoundsBlitzedKey = "BLITZROUNDSBLITZEDKEY";
  static String blitzGamesWonKey = "BLITZGAMESWONKEY";
  static String blitzPlaySpeedKey = "BLITZPLAYSPEEDKEY";

  static String euchreGamesPlayedKey = "EUCHREGAMESPLAYEDKEY";
  static String euchreGamesWonKey = "EUCHREGAMESWONKEY";

  static String seenSolitaireKey = "SEENSOLITAIREKEY";
  static String solitaireGamesWon = "SOLITAIREGAMESWONKEY";

  static String crazyEightsGamesPlayedKey = "CRAZYEIGHTSGAMESPLAYEDKEY";
  static String crazyEightsGamesWonKey = "CRAZYEIGHTSGAMESWONKEY";

  static String kalamattackGamesPlayedKey = "KALAMATTACKGAMESPLAYEDKEY";
  static String kalamattackGamesWonKey = "KALAMATTACKGAMESWONKEY";

  static String newestSeenVersionKey = "NEWESTSEENVERSIONKEY";

  static String seenRateAppKey = "SEENRATEAPPKEY";
  static String seenShareAppKey = "SEENSHAREAPPKEY";

  static String firstOpenDateKey = "FIRSTOPENDATEKEY";
  static String appLaunchCountKey = "APPLAUNCHCOUNTKEY";

  static String analyticsEnabledKey = "ANALYTICSENABLEDKEY";

  static String seenPrivacyPolicyKey = "SEENPRIVACYPOLICYKEY";

  static String newGamesSeenKey = "NEWGAMESSEENKEY";

  static String seenKalamattackDialogKey = "SEENKALAMATTACKDIALOGKEY";

  static Future<bool> setSeenKalamattackDialog(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(seenKalamattackDialogKey, val);
  }

  static Future<bool> getSeenKalamattackDialog() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(seenKalamattackDialogKey) ?? false; // Default to false
  }

  static final StreamController<List<Game>> _newGamesSeenController =
      StreamController<List<Game>>.broadcast();

  // ✅ Static stream getter
  static Stream<List<Game>> get newGamesSeenStream =>
      _newGamesSeenController.stream;
  static Future<List<Game>> getNewGamesSeenAsEnum() async {
    List<String> gameStrings = await getNewGamesSeen();
    return gameStrings
        .map((gameString) => Game.fromString(gameString))
        .toList();
  }

  // ✅ Initialize the stream (call this in main.dart)
  static Future<void> initializeNewGamesStream() async {
    // Emit initial value
    List<Game> currentGames = await getNewGamesSeenAsEnum();
    _newGamesSeenController.add(currentGames);
  }

  // ✅ Dispose the stream controller (call this when app closes)
  static void disposeNewGamesStream() {
    _newGamesSeenController.close();
  }

  static Future<bool> setNewUser(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(newUserKey, val);
  }

  static Future<bool> getNewUser() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(newUserKey) ?? true; // Default to true
  }

  static Future<bool> setNewGamesSeen(List<String> val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    bool success = await sf.setStringList(newGamesSeenKey, val);

    if (success) {
      // ✅ Emit updated list to stream
      List<Game> updatedGames = await getNewGamesSeenAsEnum();
      _newGamesSeenController.add(updatedGames);
    }

    return success;
  }

  static Future<List<String>> getNewGamesSeen() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getStringList(newGamesSeenKey) ?? []; // Default to empty list
  }

  static Future<bool> addNewGamesSeen(Game val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    List<String>? currentGamesSeen = sf.getStringList(newGamesSeenKey);
    currentGamesSeen ??= [];

    if (!currentGamesSeen.contains(val.toString())) {
      currentGamesSeen.add(val.toString());
      bool success = await sf.setStringList(newGamesSeenKey, currentGamesSeen);

      if (success) {
        // ✅ Emit updated list to stream
        List<Game> updatedGames = await getNewGamesSeenAsEnum();
        _newGamesSeenController.add(updatedGames);
      }

      return success;
    }
    return false; // No change made
  }

  static Future<bool> clearNewGamesSeen() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    bool success = await sf.remove(newGamesSeenKey);

    if (success) {
      // ✅ Emit empty list to stream
      _newGamesSeenController.add([]);
    }

    return success;
  }

  static Future<bool> hasSeenNewGame(Game game) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    List<String>? currentGamesSeen = sf.getStringList(newGamesSeenKey);
    return currentGamesSeen?.contains(game.toString()) ??
        false; // Default to false
  }

  static Future<bool> setSeenPrivacyPolicy(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(seenPrivacyPolicyKey, val);
  }

  static Future<bool> getSeenPrivacyPolicy() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(seenPrivacyPolicyKey) ?? false; // Default to false
  }

  static Future<bool> setAnalyticsEnabled(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(analyticsEnabledKey, val);
  }

  static Future<bool> getAnalyticsEnabled() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(analyticsEnabledKey) ?? true; // Default to true
  }

  static Future<bool> setFirstOpenDate(DateTime date) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(firstOpenDateKey, date.toIso8601String());
  }

  static Future<DateTime> getFirstOpenDate() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    String? dateString = sf.getString(firstOpenDateKey);
    if (dateString == null) {
      await setFirstOpenDate(DateTime.now());
      return DateTime.now();
    }
    return DateTime.parse(dateString);
  }

  static Future<bool> setAppLaunchCount(int count) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(appLaunchCountKey, count);
  }

  static Future<int> getAppLaunchCount() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(appLaunchCountKey) ?? 0;
  }

  static Future<bool> incrementAppLaunchCount() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentCount = sf.getInt(appLaunchCountKey) ?? 0;
    return await sf.setInt(appLaunchCountKey, currentCount + 1);
  }

  static Future<bool> setSeenRateApp(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(seenRateAppKey, val);
  }

  static Future<bool> getSeenRateApp() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(seenRateAppKey) ?? false;
  }

  static Future<bool> setSeenShareApp(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(seenShareAppKey, val);
  }

  static Future<bool> getSeenShareApp() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(seenShareAppKey) ?? false;
  }

  static Future<bool> setKalamattackGamesPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(kalamattackGamesPlayedKey, val);
  }

  static Future<bool> addKalamattackGamesPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentGamesPlayed = sf.getInt(kalamattackGamesPlayedKey) ?? 0;
    return await sf.setInt(kalamattackGamesPlayedKey, currentGamesPlayed + val);
  }

  static Future<int> getKalamattackGamesPlayed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(kalamattackGamesPlayedKey) ?? 0;
  }

  static Future<bool> setKalamattackGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(kalamattackGamesWonKey, val);
  }

  static Future<bool> addKalamattackGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentGamesWon = sf.getInt(kalamattackGamesWonKey) ?? 0;
    return await sf.setInt(kalamattackGamesWonKey, currentGamesWon + val);
  }

  static Future<int> getKalamattackGamesWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(kalamattackGamesWonKey) ?? 0;
  }

  static Future<bool> setCrazyEightsGamesPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(crazyEightsGamesPlayedKey, val);
  }

  static Future<bool> addCrazyEightsGamesPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentGamesPlayed = sf.getInt(crazyEightsGamesPlayedKey) ?? 0;
    return await sf.setInt(crazyEightsGamesPlayedKey, currentGamesPlayed + val);
  }

  static Future<int> getCrazyEightsGamesPlayed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(crazyEightsGamesPlayedKey) ?? 0;
  }

  static Future<bool> setCrazyEightsGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(crazyEightsGamesWonKey, val);
  }

  static Future<bool> addCrazyEightsGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentGamesWon = sf.getInt(crazyEightsGamesWonKey) ?? 0;
    return await sf.setInt(crazyEightsGamesWonKey, currentGamesWon + val);
  }

  static Future<int> getCrazyEightsGamesWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(crazyEightsGamesWonKey) ?? 0;
  }

  static Future<bool> setSolitaireGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(solitaireGamesWon, val);
  }

  static Future<int> getSolitaireGamesWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(solitaireGamesWon) ?? 0;
  }

  static Future<bool> addSolitaireGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentGamesWon = sf.getInt(solitaireGamesWon) ?? 0;
    return await sf.setInt(solitaireGamesWon, currentGamesWon + val);
  }

  static Future<bool> setSeenSolitaire(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(seenSolitaireKey, val);
  }

  static Future<bool> getSeenSolitaire() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(seenSolitaireKey) ?? false;
  }

  static Future<bool> setNewestSeenVersion(String version) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(newestSeenVersionKey, version);
  }

  static Future<String> getNewestSeenVersion() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(newestSeenVersionKey) ?? "0.0.0";
  }

  static Future<bool> setNertzRoundsPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(nertzRoundsPlayedKey, val);
  }

  static Future<bool> addNertzRoundsPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(nertzRoundsPlayedKey) ?? 0;
    return await sf.setInt(nertzRoundsPlayedKey, currentRounds + val);
  }

  static Future<int> getNertzRoundsPlayed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(nertzRoundsPlayedKey) ?? 0;
  }

  static Future<bool> setNertzRoundsNertzed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(nertzRoundsNertzedKey, val);
  }

  static Future<bool> addNertzRoundsNertzed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(nertzRoundsNertzedKey) ?? 0;
    return await sf.setInt(nertzRoundsNertzedKey, currentRounds + val);
  }

  static Future<int> getNertzRoundsNertzed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(nertzRoundsNertzedKey) ?? 0;
  }

  static Future<bool> setNertzGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(nertzGamesWonKey, val);
  }

  static Future<bool> addNertzGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(nertzGamesWonKey) ?? 0;
    return await sf.setInt(nertzGamesWonKey, currentRounds + val);
  }

  static Future<int> getNertzGamesWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(nertzGamesWonKey) ?? 0;
  }

  static Future<bool> setNertzPlaySpeed(List<double> val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setStringList(
      nertzPlaySpeedKey,
      val.map((e) => e.toString()).toList(),
    );
  }

  static Future<bool> addNertzPlaySpeed(double val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    List<String>? currentSpeeds = sf.getStringList(nertzPlaySpeedKey);
    currentSpeeds ??= [];
    currentSpeeds.add(val.toString());
    return await sf.setStringList(nertzPlaySpeedKey, currentSpeeds);
  }

  static Future<List<double>> getNertzPlaySpeed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    List<String>? speedStrings = sf.getStringList(nertzPlaySpeedKey);
    if (speedStrings == null) {
      return [];
    }
    return speedStrings.map((e) => double.tryParse(e) ?? 1.0).toList();
  }

  static Future<double> getNertzAveragePlaySpeed() async {
    List<double> speeds = await getNertzPlaySpeed();
    if (speeds.isEmpty) {
      return 0.0;
    }
    double total = speeds.reduce((a, b) => a + b);
    double avg = (total / 1000) / speeds.length;
    //return average rounded to 2 decimal places
    return double.parse(avg.toStringAsFixed(2));
  }

  static Future<bool> setBlitzRoundsPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(blitzRoundsPlayedKey, val);
  }

  static Future<bool> addBlitzRoundsPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(blitzRoundsPlayedKey) ?? 0;
    return await sf.setInt(blitzRoundsPlayedKey, currentRounds + val);
  }

  static Future<int> getBlitzRoundsPlayed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(blitzRoundsPlayedKey) ?? 0;
  }

  static Future<bool> setBlitzRoundsBlitzed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(blitzRoundsBlitzedKey, val);
  }

  static Future<bool> addBlitzRoundsBlitzed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(blitzRoundsBlitzedKey) ?? 0;
    return await sf.setInt(blitzRoundsBlitzedKey, currentRounds + val);
  }

  static Future<int> getBlitzRoundsBlitzed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(blitzRoundsBlitzedKey) ?? 0;
  }

  static Future<bool> setBlitzGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(blitzGamesWonKey, val);
  }

  static Future<bool> addBlitzGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(blitzGamesWonKey) ?? 0;
    return await sf.setInt(blitzGamesWonKey, currentRounds + val);
  }

  static Future<int> getBlitzGamesWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(blitzGamesWonKey) ?? 0;
  }

  static Future<bool> setBlitzPlaySpeed(List<double> val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setStringList(
      blitzPlaySpeedKey,
      val.map((e) => e.toString()).toList(),
    );
  }

  static Future<bool> addBlitzPlaySpeed(double val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    List<String>? currentSpeeds = sf.getStringList(blitzPlaySpeedKey);
    currentSpeeds ??= [];
    currentSpeeds.add(val.toString());
    return await sf.setStringList(blitzPlaySpeedKey, currentSpeeds);
  }

  static Future<List<double>> getBlitzPlaySpeed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    List<String>? speedStrings = sf.getStringList(blitzPlaySpeedKey);
    if (speedStrings == null) {
      return [];
    }
    return speedStrings.map((e) => double.tryParse(e) ?? 1.0).toList();
  }

  static Future<double> getBlitzAveragePlaySpeed() async {
    List<double> speeds = await getBlitzPlaySpeed();
    if (speeds.isEmpty) {
      return 0.0;
    }
    double total = speeds.reduce((a, b) => a + b);
    double avg = (total / 1000) / speeds.length;
    //return average rounded to 2 decimal places
    return double.parse(avg.toStringAsFixed(2));
  }

  static Future<bool> setEuchreGamesPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(euchreGamesPlayedKey, val);
  }

  static Future<bool> addEuchreGamesPlayed(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(euchreGamesPlayedKey) ?? 0;
    return await sf.setInt(euchreGamesPlayedKey, currentRounds + val);
  }

  static Future<int> getEuchreGamesPlayed() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(euchreGamesPlayedKey) ?? 0;
  }

  static Future<bool> setEuchreGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(euchreGamesWonKey, val);
  }

  static Future<bool> addEuchreGamesWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(euchreGamesWonKey) ?? 0;
    return await sf.setInt(euchreGamesWonKey, currentRounds + val);
  }

  static Future<int> getEuchreGamesWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(euchreGamesWonKey) ?? 0;
  }

  static Future<bool> setFirstUse(bool val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(firstUseKey, val);
  }

  static Future<bool> getFirstUse() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(firstUseKey) ?? true;
  }

  static Future<bool> setHapticSettings(HapticLevel val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(hapticSettingsKey, val.toString());
  }

  static Future<HapticLevel> getHapticSettings() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return HapticLevel.fromString(sf.getString(hapticSettingsKey) ?? "medium");
  }

  static Future<void> hapticButtonPress() async {
    HapticLevel hapticLevel = await getHapticSettings();
    switch (hapticLevel) {
      case HapticLevel.none:
        break;
      case HapticLevel.light:
        HapticFeedback.lightImpact();
        break;
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticLevel.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  static Future<void> hapticInputSelect() async {
    HapticLevel hapticLevel = await getHapticSettings();
    switch (hapticLevel) {
      case HapticLevel.none:
        break;
      case HapticLevel.light:
        HapticFeedback.selectionClick();
        break;
      case HapticLevel.medium:
        HapticFeedback.selectionClick();
        break;
      case HapticLevel.heavy:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  static Future<String> getLastUsedName() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(lastUsedNameKey) ?? '';
  }

  static Future<bool> setLastUsedName(String name) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(lastUsedNameKey, name);
  }
}
