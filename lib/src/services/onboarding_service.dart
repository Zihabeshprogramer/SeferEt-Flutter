import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _isFirstLaunchKey = 'is_first_launch';

  /// Check if user has seen onboarding
  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  /// Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  /// Mark first launch as completed (without showing onboarding)
  Future<void> completeFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isFirstLaunchKey, false);
  }

  /// Reset onboarding status (for testing purposes)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
    await prefs.remove(_isFirstLaunchKey);
  }

  /// Clear all onboarding data
  Future<void> clearOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenOnboardingKey);
    await prefs.remove(_isFirstLaunchKey);
  }
}