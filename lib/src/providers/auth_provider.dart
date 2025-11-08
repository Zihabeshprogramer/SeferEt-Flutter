import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

/// Authentication state data class
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isGuest;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    required this.isLoading,
    this.error,
    required this.isGuest,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
    bool? isGuest,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  /// Initial state with guest mode
  factory AuthState.guest() {
    return const AuthState(
      isAuthenticated: false,
      user: null,
      isLoading: false,
      error: null,
      isGuest: true,
    );
  }

  /// Loading state
  factory AuthState.loading() {
    return const AuthState(
      isAuthenticated: false,
      user: null,
      isLoading: true,
      error: null,
      isGuest: false,
    );
  }

  /// Authenticated state
  factory AuthState.authenticated(User user) {
    return AuthState(
      isAuthenticated: true,
      user: user,
      isLoading: false,
      error: null,
      isGuest: false,
    );
  }

  /// Error state
  factory AuthState.error(String error) {
    return AuthState(
      isAuthenticated: false,
      user: null,
      isLoading: false,
      error: error,
      isGuest: false,
    );
  }
}

/// Authentication notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState.loading()) {
    _initializeAuthState();
  }

  /// Initialize authentication state on app start
  Future<void> _initializeAuthState() async {
    try {
      // Check if user was previously authenticated
      if (_apiService.isAuthenticated) {
        // Try to get current user to verify token is still valid
        final response = await _apiService.getCurrentUser();
        if (response.success && response.data != null) {
          state = AuthState.authenticated(response.data!);
          await _saveUserData(response.data!);
        } else {
          // Token is invalid, clear stored data and go to guest mode
          await logout();
        }
      } else {
        // No previous authentication, start as guest
        state = AuthState.guest();
      }
    } catch (e) {
      // Error during initialization, start as guest
      state = AuthState.guest();
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    state = AuthState.loading();
    
    try {
      final response = await _apiService.login(email, password, rememberMe: rememberMe);
      
      if (response.success && response.data != null) {
        final userData = response.data!['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        state = AuthState.authenticated(user);
        await _saveUserData(user);
        return true;
      } else {
        state = AuthState.error(response.message);
        return false;
      }
    } catch (e) {
      state = AuthState.error('Login failed: ${e.toString()}');
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? country,
  }) async {
    state = AuthState.loading();
    
    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
        country: country,
      );
      
      if (response.success && response.data != null) {
        final userData = response.data!['user'] as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        state = AuthState.authenticated(user);
        await _saveUserData(user);
        return true;
      } else {
        state = AuthState.error(response.message);
        return false;
      }
    } catch (e) {
      state = AuthState.error('Registration failed: ${e.toString()}');
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Call logout endpoint if authenticated with timeout
      if (state.isAuthenticated) {
        await _apiService.logout().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Logout API call timed out');
            // Don't throw error, just continue with local cleanup
            return Future<ApiResponse<void>>.value(
              ApiResponse<void>(
                success: false,
                message: 'Logout timeout',
                data: null,
                statusCode: 408,
              ),
            );
          },
        );
      }
    } catch (e) {
      // Even if logout API call fails, we should clear local data
      print('Logout API call failed: $e');
    } finally {
      // Clear local data
      await _clearUserData();
      state = AuthState.guest();
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;

    try {
      final response = await _apiService.getCurrentUser();
      if (response.success && response.data != null) {
        state = AuthState.authenticated(response.data!);
        await _saveUserData(response.data!);
      }
    } catch (e) {
      // If refresh fails, keep current state but log error
      print('Failed to refresh user data: $e');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? country,
  }) async {
    if (!state.isAuthenticated || state.user == null) return false;

    try {
      // Create updated user data
      final updatedUser = state.user!.copyWith(
        name: name ?? state.user!.name,
        email: email ?? state.user!.email,
        phone: phone ?? state.user!.phone,
        country: country ?? state.user!.country,
      );

      // Update state immediately for better UX
      state = AuthState.authenticated(updatedUser);
      await _saveUserData(updatedUser);

      // Here you would call the API to update the backend
      // For now, we'll just save locally since the API endpoint isn't implemented
      return true;
    } catch (e) {
      print('Failed to update profile: $e');
      return false;
    }
  }

  /// Continue as guest
  void continueAsGuest() {
    state = AuthState.guest();
  }

  /// Force logout immediately (clear local data without API call)
  Future<void> forceLogout() async {
    await _clearUserData();
    state = AuthState.guest();
  }

  /// Save user data to local storage
  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.userKey, user.toJsonString());
      await prefs.setString(AppConstants.roleKey, user.role);
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  /// Clear user data from local storage
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.roleKey);
      await prefs.remove(AppConstants.tokenKey);
    } catch (e) {
      print('Error clearing user data: $e');
    }
  }

  /// Get error message and clear it
  String? getAndClearError() {
    final error = state.error;
    if (error != null) {
      state = state.copyWith(error: null);
    }
    return error;
  }
}

/// Provider for the ApiService singleton
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Provider for authentication state
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});

/// Provider for current user (derived from auth state)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.user;
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isAuthenticated;
});

/// Provider to check if user is in guest mode
final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.isGuest;
});