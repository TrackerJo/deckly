import 'dart:convert';
import 'dart:io';

import 'package:deckly/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';

// import 'package:image_downloader/image_downloader.dart';

class SharedPrefs {
  static String hapticSettingsKey = "HAPTICSETTINGSKEY";
  static String lastUsedNameKey = "LASTUSEDNAMEKEY";

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
      default:
        HapticFeedback.mediumImpact();
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
      default:
        HapticFeedback.selectionClick();
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
