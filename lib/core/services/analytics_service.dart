import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    await _analytics!.setAnalyticsCollectionEnabled(!kDebugMode);
  }

  Future<void> logScreen(String screenName) async {
    await _analytics?.logScreenView(screenName: screenName);
  }

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  Future<void> logOnboardingComplete() async {
    await logEvent('onboarding_complete');
  }
}
