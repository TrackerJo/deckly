import 'package:deckly/constants.dart';

import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

// import 'package:image_downloader/image_downloader.dart';

class SharedPrefs {
  static String hapticSettingsKey = "HAPTICSETTINGSKEY";
  static String lastUsedNameKey = "LASTUSEDNAMEKEY";
  static String firstUseKey = "FIRSTUSEKEY";
  static String nertzRoundsPlayedKey = "NERTZROUNDSPLAYEDKEY";
  static String nertzRoundsNertzedKey = "NERTZROUNDSNERTZEDKEY";
  static String nertzGamesWonKey = "NERTZGAMESWONKEY";
  static String nertzPlaySpeedKey = "NERTZPLAYSPEEDKEY";
  static String blitzRoundsPlayedKey = "BLITZROUNDSPLAYEDKEY";
  static String blitzRoundsBlitzedKey = "BLITZROUNDSBLITZEDKEY";
  static String blitzGamesWonKey = "BLITZGAMESWONKEY";
  static String blitzPlaySpeedKey = "BLITZPLAYSPEEDKEY";

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
