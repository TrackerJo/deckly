import 'dart:io';

import 'package:deckly/constants.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfig {
  final String? uid;
  RemoteConfig({this.uid});
  final remoteConfig = FirebaseRemoteConfig.instance;
  Future<UpdateStatus> checkUpdates() async {
    print("Checking for updates");
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: Duration.zero,
      ),
    );
    try {
      await remoteConfig.fetchAndActivate();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();

      if (Platform.isAndroid) {
        var requiredBuildNumber = int.parse(
          remoteConfig.getString('requiredAndroidBuildNumber'),
        );
        var latestBuildNumber = int.parse(
          remoteConfig.getString('latestAndroidBuildNumber'),
        );
        int currentBuildNumber = int.parse(packageInfo.buildNumber);
        if (currentBuildNumber < requiredBuildNumber) {
          return UpdateStatus.required;
        } else if (currentBuildNumber < latestBuildNumber) {
          return UpdateStatus.available;
        } else {
          return UpdateStatus.none;
        }
      } else if (Platform.isIOS) {
        var requiredBuildNumber = int.parse(
          remoteConfig.getString('requiredIOSBuildNumber'),
        );
        var latestBuildNumber = int.parse(
          remoteConfig.getString('latestIOSBuildNumber'),
        );
        int currentBuildNumber = int.parse(packageInfo.buildNumber);
        if (currentBuildNumber < requiredBuildNumber) {
          return UpdateStatus.required;
        } else if (currentBuildNumber < latestBuildNumber) {
          return UpdateStatus.available;
        } else {
          return UpdateStatus.none;
        }
      } else {
        return UpdateStatus.none;
      }
    } catch (e) {
      print(e);
      return UpdateStatus.none;
    }
  }
}
