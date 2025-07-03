import 'package:deckly/api/shared_prefs.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class Analytics {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  Future<void> logJoinRoomEvent() async {
    await _analytics.logEvent(name: 'join_room');
  }

  Future<void> logSelectGameEvent(String gameName) async {
    await _analytics.logEvent(
      name: 'select_game',
      parameters: {'game_name': gameName},
    );
  }

  Future<void> logShareAppEvent() async {
    await _analytics.logEvent(name: 'share_app');
  }

  Future<void> logRateAppEvent() async {
    await _analytics.logEvent(name: 'rate_app');
  }

  Future<void> logPlayWithBotEvent(
    String gameName,
    String botDifficulty,
  ) async {
    await _analytics.logEvent(
      name: '${gameName}_bot',
      parameters: {'difficulty': botDifficulty},
    );
  }

  Future<void> logViewStatsEvent() async {
    await _analytics.logEvent(name: 'view_stats');
  }

  Future<void> logViewSettingsEvent() async {
    await _analytics.logEvent(name: 'view_settings');
  }

  Future<void> logViewWhatsNewEvent() async {
    await _analytics.logEvent(name: 'view_whats_new');
  }

  Future<void> logViewHelpEvent() async {
    await _analytics.logEvent(name: 'view_help');
  }

  Future<bool> isAnalyticsEnabled() async {
    // Implement logic to check if analytics is enabled
    // This could be a shared preference or a remote config value
    return await SharedPrefs.getAnalyticsEnabled();
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    // Implement logic to enable or disable analytics
    // This could be a shared preference or a remote config value
    await SharedPrefs.setAnalyticsEnabled(enabled);
    _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
