import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/onboarding_service.dart';

/// Provider for the OnboardingService singleton
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Provider to check if user has seen onboarding
final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return await onboardingService.hasSeenOnboarding();
});

/// Provider to check if this is first launch
final isFirstLaunchProvider = FutureProvider<bool>((ref) async {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return await onboardingService.isFirstLaunch();
});

/// StateProvider for onboarding completion status
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

/// Notifier for managing onboarding state
class OnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  final OnboardingService _onboardingService;

  OnboardingNotifier(this._onboardingService) : super(const AsyncValue.loading()) {
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final hasSeenOnboarding = await _onboardingService.hasSeenOnboarding();
      state = AsyncValue.data(hasSeenOnboarding);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    state = const AsyncValue.loading();
    try {
      await _onboardingService.completeOnboarding();
      state = const AsyncValue.data(true);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    state = const AsyncValue.loading();
    try {
      await _onboardingService.resetOnboarding();
      state = const AsyncValue.data(false);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh onboarding status
  void refresh() {
    _checkOnboardingStatus();
  }
}

/// Provider for onboarding notifier
final onboardingNotifierProvider = StateNotifierProvider<OnboardingNotifier, AsyncValue<bool>>((ref) {
  final onboardingService = ref.watch(onboardingServiceProvider);
  return OnboardingNotifier(onboardingService);
});