import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorites_service.dart';
import 'auth_provider.dart';

/// Provider for the FavoritesService
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return FavoritesService(apiService);
});

/// Provider for favorites list
final favoritesProvider = FutureProvider.family<List<FavoriteItem>, String?>((ref, type) async {
  final authState = ref.watch(authNotifierProvider);
  
  // Return empty list if user is not authenticated
  if (!authState.isAuthenticated) {
    return [];
  }

  final favoritesService = ref.read(favoritesServiceProvider);
  final response = await favoritesService.getFavorites(type: type);
  
  if (response.success && response.data != null) {
    return response.data!;
  }
  
  return [];
});

/// Provider for favorites counts
final favoritesCountsProvider = FutureProvider<FavoritesCounts>((ref) async {
  final authState = ref.watch(authNotifierProvider);
  
  // Return empty counts if user is not authenticated
  if (!authState.isAuthenticated) {
    return FavoritesCounts.empty();
  }

  final favoritesService = ref.read(favoritesServiceProvider);
  final response = await favoritesService.getFavoritesCounts();
  
  if (response.success && response.data != null) {
    return response.data!;
  }
  
  return FavoritesCounts.empty();
});

/// State for managing favorite operations
class FavoritesState {
  final bool isLoading;
  final String? error;
  final Set<String> favoriteItems; // Set of "type:referenceId" strings
  
  const FavoritesState({
    this.isLoading = false,
    this.error,
    this.favoriteItems = const {},
  });
  
  FavoritesState copyWith({
    bool? isLoading,
    String? error,
    Set<String>? favoriteItems,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      favoriteItems: favoriteItems ?? this.favoriteItems,
    );
  }
}

/// Notifier for managing favorites state and operations
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final FavoritesService _favoritesService;
  final Ref _ref;
  
  FavoritesNotifier(this._favoritesService, this._ref) : super(const FavoritesState());
  
  /// Check if an item is in favorites
  bool isFavorite(String type, int? referenceId) {
    if (referenceId == null) return false;
    return state.favoriteItems.contains('$type:$referenceId');
  }
  
  /// Add an item to favorites
  Future<bool> addToFavorites({
    required String type,
    required Map<String, dynamic> itemData,
    int? referenceId,
    String? title,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _favoritesService.addToFavorites(
        type: type,
        itemData: itemData,
        referenceId: referenceId,
        title: title,
        notes: notes,
      );
      
      if (response.success) {
        // Update local state
        final newFavoriteItems = Set<String>.from(state.favoriteItems);
        if (referenceId != null) {
          newFavoriteItems.add('$type:$referenceId');
        }
        
        state = state.copyWith(
          isLoading: false,
          favoriteItems: newFavoriteItems,
        );
        
        // Refresh favorites list
        _ref.invalidate(favoritesProvider);
        _ref.invalidate(favoritesCountsProvider);
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Remove an item from favorites
  Future<bool> removeFromFavorites(int favoriteId, {String? type, int? referenceId}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _favoritesService.removeFromFavorites(favoriteId);
      
      if (response.success) {
        // Update local state
        final newFavoriteItems = Set<String>.from(state.favoriteItems);
        if (type != null && referenceId != null) {
          newFavoriteItems.remove('$type:$referenceId');
        }
        
        state = state.copyWith(
          isLoading: false,
          favoriteItems: newFavoriteItems,
        );
        
        // Refresh favorites list
        _ref.invalidate(favoritesProvider);
        _ref.invalidate(favoritesCountsProvider);
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Toggle favorite status
  Future<bool> toggleFavorite({
    required String type,
    required Map<String, dynamic> itemData,
    int? referenceId,
    int? favoriteId,
    String? title,
  }) async {
    if (isFavorite(type, referenceId)) {
      if (favoriteId != null) {
        return await removeFromFavorites(favoriteId, type: type, referenceId: referenceId);
      } else {
        // If we don't have favoriteId, we need to find it first
        state = state.copyWith(error: 'Cannot remove favorite without ID');
        return false;
      }
    } else {
      return await addToFavorites(
        type: type,
        itemData: itemData,
        referenceId: referenceId,
        title: title,
      );
    }
  }
  
  /// Update favorite notes
  Future<bool> updateFavoriteNotes(int favoriteId, String? notes) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _favoritesService.updateFavoriteNotes(favoriteId, notes);
      
      if (response.success) {
        state = state.copyWith(isLoading: false);
        
        // Refresh favorites list
        _ref.invalidate(favoritesProvider);
        
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  /// Remove multiple favorites
  Future<int> removeMultipleFavorites(List<int> favoriteIds) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _favoritesService.removeMultipleFavorites(favoriteIds);
      
      state = state.copyWith(isLoading: false);
      
      if (response.success && response.data != null) {
        // Refresh favorites list
        _ref.invalidate(favoritesProvider);
        _ref.invalidate(favoritesCountsProvider);
        
        return response.data!;
      } else {
        state = state.copyWith(error: response.message);
        return 0;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return 0;
    }
  }
  
  /// Check and sync favorite status for an item
  Future<void> checkFavoriteStatus({
    required String type,
    int? referenceId,
  }) async {
    if (referenceId == null) return;
    
    try {
      final response = await _favoritesService.checkIsFavorite(
        type: type,
        referenceId: referenceId,
      );
      
      if (response.success && response.data != null) {
        final newFavoriteItems = Set<String>.from(state.favoriteItems);
        final key = '$type:$referenceId';
        
        if (response.data!) {
          newFavoriteItems.add(key);
        } else {
          newFavoriteItems.remove(key);
        }
        
        state = state.copyWith(favoriteItems: newFavoriteItems);
      }
    } catch (e) {
      // Silently handle errors for status checks
    }
  }
  
  /// Clear favorites state (for logout)
  void clearState() {
    state = const FavoritesState();
  }
  
  /// Get and clear error
  String? getAndClearError() {
    final error = state.error;
    if (error != null) {
      state = state.copyWith(error: null);
    }
    return error;
  }
}

/// Provider for favorites notifier
final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final favoritesService = ref.read(favoritesServiceProvider);
  return FavoritesNotifier(favoritesService, ref);
});

/// Provider to check if a specific item is favorited
final isFavoriteProvider = Provider.family<bool, Map<String, dynamic>>((ref, params) {
  final favoritesState = ref.watch(favoritesNotifierProvider);
  final type = params['type'] as String;
  final referenceId = params['referenceId'] as int?;
  
  if (referenceId == null) return false;
  return favoritesState.favoriteItems.contains('$type:$referenceId');
});

/// Provider for favorite button state
final favoriteButtonStateProvider = Provider<bool>((ref) {
  final favoritesState = ref.watch(favoritesNotifierProvider);
  return favoritesState.isLoading;
});