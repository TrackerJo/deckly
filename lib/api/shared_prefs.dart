import 'package:deckly/constants.dart';

import 'package:flutter/services.dart';

import 'package:shared_preferences/shared_preferences.dart';

// import 'package:image_downloader/image_downloader.dart';

class SharedPrefs {
  static String hapticSettingsKey = "HAPTICSETTINGSKEY";
  static String lastUsedNameKey = "LASTUSEDNAMEKEY";
  static String firstUseKey = "FIRSTUSEKEY";
  static String nertzRoundsPlayedKey = "NERTZROUNDSPLAYEDKEY";
  static String nertzRoundsWonKey = "NERTZROUNDSWONKEY";
  static String blitzRoundsPlayedKey = "BLITZROUNDSPLAYEDKEY";
  static String blitzRoundsWonKey = "BLITZROUNDSWONKEY";

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

  static Future<bool> setNertzRoundsWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(nertzRoundsWonKey, val);
  }

  static Future<bool> addNertzRoundsWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(nertzRoundsWonKey) ?? 0;
    return await sf.setInt(nertzRoundsWonKey, currentRounds + val);
  }

  static Future<int> getNertzRoundsWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(nertzRoundsWonKey) ?? 0;
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

  static Future<bool> setBlitzRoundsWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setInt(blitzRoundsWonKey, val);
  }

  static Future<bool> addBlitzRoundsWon(int val) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    int currentRounds = sf.getInt(blitzRoundsWonKey) ?? 0;
    return await sf.setInt(blitzRoundsWonKey, currentRounds + val);
  }

  static Future<int> getBlitzRoundsWon() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getInt(blitzRoundsWonKey) ?? 0;
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
