package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;

import io.flutter.embedding.engine.FlutterEngine;

/**
 * Generated file. Do not edit.
 * This file is generated by the Flutter tool based on the
 * plugins that support the Android platform.
 */
@Keep
public final class GeneratedPluginRegistrant {
  private static final String TAG = "GeneratedPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.deviceinfo.DeviceInfoPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin device_info, io.flutter.plugins.deviceinfo.DeviceInfoPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.nankai.flutter_nearby_connections.FlutterNearbyConnectionsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_nearby_connections, com.nankai.flutter_nearby_connections.FlutterNearbyConnectionsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new de.gigadroid.flutter_udid.FlutterUdidPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_udid, de.gigadroid.flutter_udid.FlutterUdidPlugin", e);
    }
  }
}
