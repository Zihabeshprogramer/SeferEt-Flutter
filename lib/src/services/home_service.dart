import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/featured_product.dart';
import 'api_service.dart';

class HomeService {
  static final HomeService _instance = HomeService._internal();
  factory HomeService() => _instance;
  HomeService._internal();

  final ApiService _apiService = ApiService();

  // Cache settings
  static const String _cachePrefix = 'home_cache_';
  static const String _featuredCacheKey = '${_cachePrefix}featured';
  static const String _recommendationsCacheKey = '${_cachePrefix}recommendations';
  static const String _popularCacheKey = '${_cachePrefix}popular';
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Get featured products (flights, hotels, packages) with local-first priority
  Future<ApiResponse<List<FeaturedProduct>>> getFeaturedProducts({
    bool forceRefresh = false,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cached = await _getCached<List<FeaturedProduct>>(
          _featuredCacheKey,
          (json) => (json as List)
              .map((item) => FeaturedProduct.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
        if (cached != null) {
          return ApiResponse<List<FeaturedProduct>>(
            success: true,
            message: 'Featured products loaded from cache',
            data: cached,
            statusCode: 200,
          );
        }
      }

      // Fetch from API
      final response = await _apiService.get<List<dynamic>>(
        '/featured/products',
        queryParameters: {
          'page': page.toString(),
          'per_page': perPage.toString(),
        },
        requireAuth: false,
      );

      if (response.success && response.data != null) {
        print('Featured products API response: ${response.data}'); // Debug log
        
        final products = (response.data as List)
            .map((item) => FeaturedProduct.fromJson(item as Map<String, dynamic>))
            .toList();

        // Sort: local providers first
        products.sort((a, b) {
          if (a.isLocal && !b.isLocal) return -1;
          if (!a.isLocal && b.isLocal) return 1;
          return 0;
        });

        // Cache the results
        await _cacheData(_featuredCacheKey, products.map((p) => p.toJson()).toList());

        return ApiResponse<List<FeaturedProduct>>(
          success: true,
          message: response.message,
          data: products,
          statusCode: response.statusCode,
        );
      }

      print('Featured products API call failed: ${response.message}'); // Debug log
      return ApiResponse<List<FeaturedProduct>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('Featured products error: $e'); // Debug log
      return ApiResponse<List<FeaturedProduct>>(
        success: false,
        message: 'Error loading featured products: $e',
        statusCode: 0,
      );
    }
  }

  /// Get personalized recommendations for authenticated users
  Future<ApiResponse<List<Recommendation>>> getRecommendations({
    bool forceRefresh = false,
    String? userId,
    int limit = 10,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cacheKey = userId != null 
            ? '${_recommendationsCacheKey}_$userId' 
            : _recommendationsCacheKey;
        
        final cached = await _getCached<List<Recommendation>>(
          cacheKey,
          (json) => (json as List)
              .map((item) => Recommendation.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
        if (cached != null) {
          return ApiResponse<List<Recommendation>>(
            success: true,
            message: 'Recommendations loaded from cache',
            data: cached,
            statusCode: 200,
          );
        }
      }

      // Fetch from API
      final queryParams = <String, String>{'limit': limit.toString()};
      if (userId != null) {
        queryParams['user_id'] = userId;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/recommendations',
        queryParameters: queryParams,
        requireAuth: userId != null,
      );

      if (response.success && response.data != null) {
        final dataField = response.data!['data'] ?? response.data!['recommendations'];
        
        if (dataField == null) {
          return ApiResponse<List<Recommendation>>(
            success: false,
            message: 'Invalid API response format',
            statusCode: response.statusCode,
          );
        }

        final recommendations = (dataField as List)
            .map((item) => Recommendation.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the results
        final cacheKey = userId != null 
            ? '${_recommendationsCacheKey}_$userId' 
            : _recommendationsCacheKey;
        await _cacheData(cacheKey, recommendations.map((r) => r.toJson()).toList());

        return ApiResponse<List<Recommendation>>(
          success: true,
          message: response.message,
          data: recommendations,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<Recommendation>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<Recommendation>>(
        success: false,
        message: 'Error loading recommendations: $e',
        statusCode: 0,
      );
    }
  }

  /// Get popular products by location
  Future<ApiResponse<List<FeaturedProduct>>> getPopular({
    bool forceRefresh = false,
    String? location,
    int limit = 10,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cacheKey = location != null 
            ? '${_popularCacheKey}_$location' 
            : _popularCacheKey;
        
        final cached = await _getCached<List<FeaturedProduct>>(
          cacheKey,
          (json) => (json as List)
              .map((item) => FeaturedProduct.fromJson(item as Map<String, dynamic>))
              .toList(),
        );
        if (cached != null) {
          return ApiResponse<List<FeaturedProduct>>(
            success: true,
            message: 'Popular products loaded from cache',
            data: cached,
            statusCode: 200,
          );
        }
      }

      // Fetch from API
      final queryParams = <String, String>{'limit': limit.toString()};
      if (location != null) {
        queryParams['location'] = location;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/popular',
        queryParameters: queryParams,
        requireAuth: false,
      );

      if (response.success && response.data != null) {
        final dataField = response.data!['data'] ?? response.data!['products'];
        
        if (dataField == null) {
          return ApiResponse<List<FeaturedProduct>>(
            success: false,
            message: 'Invalid API response format',
            statusCode: response.statusCode,
          );
        }

        final products = (dataField as List)
            .map((item) => FeaturedProduct.fromJson(item as Map<String, dynamic>))
            .toList();

        // Cache the results
        final cacheKey = location != null 
            ? '${_popularCacheKey}_$location' 
            : _popularCacheKey;
        await _cacheData(cacheKey, products.map((p) => p.toJson()).toList());

        return ApiResponse<List<FeaturedProduct>>(
          success: true,
          message: response.message,
          data: products,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<FeaturedProduct>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<FeaturedProduct>>(
        success: false,
        message: 'Error loading popular products: $e',
        statusCode: 0,
      );
    }
  }

  /// Generic cache getter
  Future<T?> _getCached<T>(
    String key,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(key);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Check if cache is still valid
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDuration.inMilliseconds) {
        await prefs.remove(key);
        return null;
      }
      
      return fromJson(cacheData['data']);
    } catch (e) {
      return null;
    }
  }

  /// Generic cache setter
  Future<void> _cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(key, jsonEncode(cacheData));
    } catch (e) {
      // Log error but don't throw
    }
  }

  /// Clear all home cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final homeCacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      
      for (final key in homeCacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Log error but don't throw
    }
  }

  /// Navigation helper: Get detail route based on product type
  String getDetailRoute(String type) {
    switch (type) {
      case 'flight':
        return '/flight-detail';
      case 'hotel':
        return '/hotel-detail';
      case 'package':
        return '/tour-details';
      default:
        return '/explore-screen';
    }
  }

  /// Navigation helper: Build navigation arguments
  Map<String, dynamic> getNavigationArgs(FeaturedProduct product) {
    return {
      'id': product.id,
      'type': product.type,
      'source': product.source,
      'title': product.title,
      ...?product.metadata,
    };
  }
}
