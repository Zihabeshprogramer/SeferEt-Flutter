import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Favorite item model
class FavoriteItem {
  final int id;
  final String type;
  final String title;
  final Map<String, dynamic> itemData;
  final bool isAvailable;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  FavoriteItem({
    required this.id,
    required this.type,
    required this.title,
    required this.itemData,
    required this.isAvailable,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      itemData: Map<String, dynamic>.from(json['item_data'] as Map),
      isAvailable: json['is_available'] as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'item_data': itemData,
      'is_available': isAvailable,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FavoriteItem copyWith({
    int? id,
    String? type,
    String? title,
    Map<String, dynamic>? itemData,
    bool? isAvailable,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FavoriteItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      itemData: itemData ?? this.itemData,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Favorites count model
class FavoritesCounts {
  final int flight;
  final int hotel;
  final int package;
  final int total;

  FavoritesCounts({
    required this.flight,
    required this.hotel,
    required this.package,
    required this.total,
  });

  factory FavoritesCounts.fromJson(Map<String, dynamic> json) {
    return FavoritesCounts(
      flight: json['flight'] as int? ?? 0,
      hotel: json['hotel'] as int? ?? 0,
      package: json['package'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  factory FavoritesCounts.empty() {
    return FavoritesCounts(flight: 0, hotel: 0, package: 0, total: 0);
  }
}

/// API response wrapper
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'] as T?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

/// Service for managing user favorites
class FavoritesService {
  final ApiService _apiService;
  static const String _cacheKeyPrefix = 'favorites_cache_';
  static const String _countsKey = 'favorites_counts';

  FavoritesService(this._apiService);

  /// Get all favorites for the current user
  Future<ApiResponse<List<FavoriteItem>>> getFavorites({
    String? type,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }

      final response = await _apiService.get(
        '/favorites',
        queryParameters: queryParams,
      );

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final favoritesData = data['data'] as List<dynamic>;
        
        final favorites = favoritesData
            .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the results
        await _cacheFavorites(type ?? 'all', favorites);

        return ApiResponse<List<FavoriteItem>>(
          success: true,
          message: response.message,
          data: favorites,
        );
      } else {
        return ApiResponse<List<FavoriteItem>>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      developer.log('Error getting favorites: $e', name: 'FavoritesService');
      
      // Try to return cached data on error
      final cachedFavorites = await _getCachedFavorites(type ?? 'all');
      if (cachedFavorites.isNotEmpty) {
        return ApiResponse<List<FavoriteItem>>(
          success: true,
          message: 'Loaded from cache',
          data: cachedFavorites,
        );
      }
      
      return ApiResponse<List<FavoriteItem>>(
        success: false,
        message: 'Failed to load favorites: ${e.toString()}',
      );
    }
  }

  /// Add an item to favorites
  Future<ApiResponse<FavoriteItem>> addToFavorites({
    required String type,
    required Map<String, dynamic> itemData,
    int? referenceId,
    String? title,
    String? notes,
  }) async {
    try {
      final body = {
        'type': type,
        'item_data': itemData,
        if (referenceId != null) 'reference_id': referenceId,
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
      };

      final response = await _apiService.post('/favorites', body);

      if (response.success && response.data != null) {
        final favoriteItem = FavoriteItem.fromJson(response.data as Map<String, dynamic>);
        
        // Clear cache to force refresh
        await _clearFavoritesCache();
        
        return ApiResponse<FavoriteItem>(
          success: true,
          message: response.message,
          data: favoriteItem,
        );
      } else {
        return ApiResponse<FavoriteItem>(
          success: false,
          message: response.message,
          errors: response.data as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      developer.log('Error adding to favorites: $e', name: 'FavoritesService');
      return ApiResponse<FavoriteItem>(
        success: false,
        message: 'Failed to add to favorites: ${e.toString()}',
      );
    }
  }

  /// Remove an item from favorites
  Future<ApiResponse<bool>> removeFromFavorites(int favoriteId) async {
    try {
      final response = await _apiService.delete('/favorites/$favoriteId');
      
      if (response.success) {
        // Clear cache to force refresh
        await _clearFavoritesCache();
      }

      return ApiResponse<bool>(
        success: response.success,
        message: response.message,
        data: response.success,
      );
    } catch (e) {
      developer.log('Error removing from favorites: $e', name: 'FavoritesService');
      return ApiResponse<bool>(
        success: false,
        message: 'Failed to remove from favorites: ${e.toString()}',
      );
    }
  }

  /// Check if an item is in favorites
  Future<ApiResponse<bool>> checkIsFavorite({
    required String type,
    int? referenceId,
  }) async {
    try {
      final body = {
        'type': type,
        if (referenceId != null) 'reference_id': referenceId,
      };

      final response = await _apiService.post('/favorites/check', body);

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final isFavorite = data['is_favorite'] as bool? ?? false;
        
        return ApiResponse<bool>(
          success: true,
          message: response.message,
          data: isFavorite,
        );
      } else {
        return ApiResponse<bool>(
          success: false,
          message: response.message,
          data: false,
        );
      }
    } catch (e) {
      developer.log('Error checking favorite status: $e', name: 'FavoritesService');
      return ApiResponse<bool>(
        success: false,
        message: 'Failed to check favorite status: ${e.toString()}',
        data: false,
      );
    }
  }

  /// Get favorites counts by type
  Future<ApiResponse<FavoritesCounts>> getFavoritesCounts() async {
    try {
      final response = await _apiService.get('/favorites/counts');

      if (response.success && response.data != null) {
        final counts = FavoritesCounts.fromJson(response.data as Map<String, dynamic>);
        
        // Cache the counts
        await _cacheFavoritesCounts(counts);
        
        return ApiResponse<FavoritesCounts>(
          success: true,
          message: response.message,
          data: counts,
        );
      } else {
        return ApiResponse<FavoritesCounts>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      developer.log('Error getting favorites counts: $e', name: 'FavoritesService');
      
      // Try to return cached counts on error
      final cachedCounts = await _getCachedFavoritesCounts();
      if (cachedCounts != null) {
        return ApiResponse<FavoritesCounts>(
          success: true,
          message: 'Loaded from cache',
          data: cachedCounts,
        );
      }
      
      return ApiResponse<FavoritesCounts>(
        success: false,
        message: 'Failed to load favorites counts: ${e.toString()}',
        data: FavoritesCounts.empty(),
      );
    }
  }

  /// Update favorite notes
  Future<ApiResponse<FavoriteItem>> updateFavoriteNotes(int favoriteId, String? notes) async {
    try {
      final body = {'notes': notes};
      final response = await _apiService.put('/favorites/$favoriteId', body);

      if (response.success && response.data != null) {
        final favoriteItem = FavoriteItem.fromJson(response.data as Map<String, dynamic>);
        
        // Clear cache to force refresh
        await _clearFavoritesCache();
        
        return ApiResponse<FavoriteItem>(
          success: true,
          message: response.message,
          data: favoriteItem,
        );
      } else {
        return ApiResponse<FavoriteItem>(
          success: false,
          message: response.message,
        );
      }
    } catch (e) {
      developer.log('Error updating favorite: $e', name: 'FavoritesService');
      return ApiResponse<FavoriteItem>(
        success: false,
        message: 'Failed to update favorite: ${e.toString()}',
      );
    }
  }

  /// Remove multiple favorites
  Future<ApiResponse<int>> removeMultipleFavorites(List<int> favoriteIds) async {
    try {
      final body = {'ids': favoriteIds};
      final response = await _apiService.post('/favorites/bulk-delete', body);

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final deletedCount = data['deleted_count'] as int? ?? 0;
        
        // Clear cache to force refresh
        await _clearFavoritesCache();
        
        return ApiResponse<int>(
          success: true,
          message: response.message,
          data: deletedCount,
        );
      } else {
        return ApiResponse<int>(
          success: false,
          message: response.message,
          data: 0,
        );
      }
    } catch (e) {
      developer.log('Error removing multiple favorites: $e', name: 'FavoritesService');
      return ApiResponse<int>(
        success: false,
        message: 'Failed to remove favorites: ${e.toString()}',
        data: 0,
      );
    }
  }

  // Cache management methods
  
  /// Cache favorites locally
  Future<void> _cacheFavorites(String type, List<FavoriteItem> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$type';
      final favoritesJson = favorites.map((f) => f.toJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(favoritesJson));
    } catch (e) {
      developer.log('Error caching favorites: $e', name: 'FavoritesService');
    }
  }

  /// Get cached favorites
  Future<List<FavoriteItem>> _getCachedFavorites(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacheKeyPrefix$type';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> decodedData = jsonDecode(cachedData);
        return decodedData
            .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      developer.log('Error getting cached favorites: $e', name: 'FavoritesService');
    }
    return [];
  }

  /// Cache favorites counts
  Future<void> _cacheFavoritesCounts(FavoritesCounts counts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsJson = {
        'flight': counts.flight,
        'hotel': counts.hotel,
        'package': counts.package,
        'total': counts.total,
      };
      await prefs.setString(_countsKey, jsonEncode(countsJson));
    } catch (e) {
      developer.log('Error caching favorites counts: $e', name: 'FavoritesService');
    }
  }

  /// Get cached favorites counts
  Future<FavoritesCounts?> _getCachedFavoritesCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_countsKey);
      
      if (cachedData != null) {
        final Map<String, dynamic> decodedData = jsonDecode(cachedData);
        return FavoritesCounts.fromJson(decodedData);
      }
    } catch (e) {
      developer.log('Error getting cached favorites counts: $e', name: 'FavoritesService');
    }
    return null;
  }

  /// Clear all favorites cache
  Future<void> _clearFavoritesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      // Remove all favorites cache keys
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix) || key == _countsKey) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      developer.log('Error clearing favorites cache: $e', name: 'FavoritesService');
    }
  }

  /// Clear cache when user logs out
  Future<void> clearUserCache() async {
    await _clearFavoritesCache();
  }
}