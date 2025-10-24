import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/package.dart' hide Duration;
import 'api_service.dart';

class PackageService {
  static final PackageService _instance = PackageService._internal();
  factory PackageService() => _instance;
  PackageService._internal();

  final ApiService _apiService = ApiService();
  
  // Cache settings
  static const String _cachePrefix = 'packages_cache_';
  static const String _featuredCacheKey = '${_cachePrefix}featured';
  static const String _categoriesCacheKey = '${_cachePrefix}categories';
  static const Duration _cacheDuration = Duration(milliseconds: 30 * 60 * 1000); // 30 minutes
  static const Duration _categoriesCacheDuration = Duration(milliseconds: 2 * 60 * 60 * 1000); // 2 hours

  /// Get paginated list of packages with filtering and sorting
  Future<ApiResponse<PackageListResponse>> getPackages({
    int page = 1,
    int perPage = 20,
    String? type,
    double? minPrice,
    double? maxPrice,
    int? duration,
    List<String>? destinations,
    List<String>? features,
    String sortBy = 'created_at',
    String sortOrder = 'desc',
  }) async {
    try {
      Map<String, String> queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };

      if (type != null) queryParams['type'] = type;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (duration != null) queryParams['duration'] = duration.toString();
      if (destinations != null && destinations.isNotEmpty) {
        queryParams['destinations'] = destinations.join(',');
      }
      if (features != null && features.isNotEmpty) {
        queryParams['features'] = features.join(',');
      }

      print('PackageService: Making request to: ${AppConstants.baseUrl}${AppConstants.packagesEndpoint}');
      print('PackageService: Query parameters: $queryParams');
      
      final response = await _apiService.get<Map<String, dynamic>>(
        AppConstants.packagesEndpoint,
        queryParameters: queryParams,
        requireAuth: false,
      );
      
      print('PackageService: Response received - Success: ${response.success}, StatusCode: ${response.statusCode}');
      print('PackageService: Response message: ${response.message}');

      if (response.success && response.data != null) {
        // Debug: Print the actual response structure
        print('PackageService: Raw API response keys: ${response.data!.keys.toList()}');
        
        // Check if the response has the expected 'data' field
        final dataField = response.data!['data'];
        
        if (dataField == null) {
          print('PackageService: ERROR - \'data\' field is null in API response');
          print('PackageService: Available fields: ${response.data!.keys.toList()}');
          
          // Try to handle different response structures
          if (response.data!.containsKey('packages')) {
            print('PackageService: Found \'packages\' field, trying alternative structure');
            final packageListResponse = PackageListResponse.fromJson(response.data!);
            return ApiResponse<PackageListResponse>(
              success: true,
              message: response.message,
              data: packageListResponse,
              statusCode: response.statusCode,
            );
          }
          
          return ApiResponse<PackageListResponse>(
            success: false,
            message: 'API response missing expected \'data\' field. Available fields: ${response.data!.keys.toList()}',
            statusCode: response.statusCode,
          );
        }
        
        print('PackageService: Data field keys: ${(dataField as Map<String, dynamic>).keys.toList()}');
        
        // Check packages field structure
        final packagesField = dataField['packages'];
        if (packagesField != null && packagesField is List && packagesField.isNotEmpty) {
          print('PackageService: First package sample: ${packagesField[0]}');
        }
        
        try {
          final packageListResponse = PackageListResponse.fromJson(dataField as Map<String, dynamic>);
          return ApiResponse<PackageListResponse>(
            success: true,
            message: response.message,
            data: packageListResponse,
            statusCode: response.statusCode,
          );
        } catch (e, stackTrace) {
          print('PackageService: Error parsing PackageListResponse: $e');
          print('PackageService: Stack trace: $stackTrace');
          return ApiResponse<PackageListResponse>(
            success: false,
            message: 'Error parsing package data: $e',
            statusCode: response.statusCode,
          );
        }
      }

      return ApiResponse<PackageListResponse>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<PackageListResponse>(
        success: false,
        message: 'Error loading packages: $e',
        statusCode: 0,
      );
    }
  }

  /// Search packages by query
  Future<ApiResponse<PackageSearchResponse>> searchPackages({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      Map<String, String> queryParams = {
        'query': query,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final response = await _apiService.get<Map<String, dynamic>>(
        AppConstants.packageSearchEndpoint,
        queryParameters: queryParams,
        requireAuth: false,
      );

      if (response.success && response.data != null) {
        final searchResponse = PackageSearchResponse.fromJson(response.data!['data']);
        return ApiResponse<PackageSearchResponse>(
          success: true,
          message: response.message,
          data: searchResponse,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<PackageSearchResponse>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<PackageSearchResponse>(
        success: false,
        message: 'Error searching packages: $e',
        statusCode: 0,
      );
    }
  }

  /// Get featured packages with caching
  Future<ApiResponse<List<Package>>> getFeaturedPackages({bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedPackages = await _getCachedFeaturedPackages();
        if (cachedPackages != null) {
          return ApiResponse<List<Package>>(
            success: true,
            message: 'Featured packages loaded from cache',
            data: cachedPackages,
            statusCode: 200,
          );
        }
      }

      final response = await _apiService.get<List<dynamic>>(
        AppConstants.featuredPackagesEndpoint,
        requireAuth: false,
      );

      if (response.success && response.data != null) {
        final packages = response.data!
            .map((json) => Package.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Cache the results
        await _cacheFeaturedPackages(packages);

        return ApiResponse<List<Package>>(
          success: true,
          message: response.message,
          data: packages,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<Package>>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<List<Package>>(
        success: false,
        message: 'Error loading featured packages: $e',
        statusCode: 0,
      );
    }
  }

  /// Get package details by ID or slug
  Future<ApiResponse<Package>> getPackageDetails(dynamic packageId) async {
    try {
      print('PackageService: Getting details for package ID: $packageId');
      
      final response = await _apiService.get<Map<String, dynamic>>(
        AppConstants.packageDetailsEndpoint(packageId),
        requireAuth: false,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Package details request timed out', const Duration(seconds: 10));
        },
      );

      print('PackageService: Details response - Success: ${response.success}, StatusCode: ${response.statusCode}');
      
      if (response.success && response.data != null) {
        print('PackageService: Package details response keys: ${response.data!.keys.toList()}');
        
        try {
          // The Laravel API returns the package data directly in 'data' field
          if (response.data!.containsKey('data')) {
            final packageData = response.data!['data'];
            print('PackageService: Package details data type: ${packageData.runtimeType}');
            final package = Package.fromJson(packageData as Map<String, dynamic>);
            return ApiResponse<Package>(
              success: true,
              message: response.message,
              data: package,
              statusCode: response.statusCode,
            );
          } else {
            print('PackageService: No \'data\' field found, trying direct parsing');
            final package = Package.fromJson(response.data!);
            return ApiResponse<Package>(
              success: true,
              message: response.message,
              data: package,
              statusCode: response.statusCode,
            );
          }
        } catch (e, stackTrace) {
          print('PackageService: Error parsing package details: $e');
          print('PackageService: Stack trace: $stackTrace');
          print('PackageService: Raw response data: ${response.data}');
          throw e; // Re-throw for proper error handling
        }
      }

      return ApiResponse<Package>(
        success: false,
        message: response.message.isEmpty ? 'Package details not found' : response.message,
        statusCode: response.statusCode,
      );
    } on TimeoutException catch (e) {
      print('PackageService: Package details request timed out: $e');
      return ApiResponse<Package>(
        success: false,
        message: 'Request timed out. Please try again.',
        statusCode: 408,
      );
    } catch (e) {
      print('PackageService: Error loading package details: $e');
      return ApiResponse<Package>(
        success: false,
        message: 'Unable to load package details. Please try again later.',
        statusCode: 0,
      );
    }
  }

  /// Get package categories with caching
  Future<ApiResponse<PackageCategories>> getCategories({bool forceRefresh = false}) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedCategories = await _getCachedCategories();
        if (cachedCategories != null) {
          return ApiResponse<PackageCategories>(
            success: true,
            message: 'Categories loaded from cache',
            data: cachedCategories,
            statusCode: 200,
          );
        }
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        AppConstants.packageCategoriesEndpoint,
        requireAuth: false,
      );

      if (response.success && response.data != null) {
        // Debug: Print the actual response structure
        print('PackageService (Categories): Raw API response: ${response.data}');
        
        // Check if the response has the expected 'data' field
        final dataField = response.data!['data'];
        print('PackageService (Categories): Data field content: $dataField');
        
        if (dataField == null) {
          print('PackageService (Categories): ERROR - \'data\' field is null in API response');
          print('PackageService (Categories): Available fields: ${response.data!.keys.toList()}');
          
          // Try to handle different response structures
          if (response.data!.containsKey('types')) {
            print('PackageService (Categories): Found \'types\' field, trying alternative structure');
            final categories = PackageCategories.fromJson(response.data!);
            await _cacheCategories(categories);
            return ApiResponse<PackageCategories>(
              success: true,
              message: response.message,
              data: categories,
              statusCode: response.statusCode,
            );
          }
          
          return ApiResponse<PackageCategories>(
            success: false,
            message: 'Categories API response missing expected \'data\' field. Available fields: ${response.data!.keys.toList()}',
            statusCode: response.statusCode,
          );
        }
        
        final categories = PackageCategories.fromJson(dataField as Map<String, dynamic>);
        
        // Cache the results
        await _cacheCategories(categories);

        return ApiResponse<PackageCategories>(
          success: true,
          message: response.message,
          data: categories,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<PackageCategories>(
        success: false,
        message: response.message,
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ApiResponse<PackageCategories>(
        success: false,
        message: 'Error loading categories: $e',
        statusCode: 0,
      );
    }
  }

  /// Cache featured packages
  Future<void> _cacheFeaturedPackages(List<Package> packages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': packages.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_featuredCacheKey, jsonEncode(cacheData));
    } catch (e) {
      // Log error - could use proper logging service in production
    }
  }

  /// Get cached featured packages
  Future<List<Package>?> _getCachedFeaturedPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_featuredCacheKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Check if cache is still valid
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDuration.inMilliseconds) {
        // Cache expired, remove it
        await prefs.remove(_featuredCacheKey);
        return null;
      }
      
      final packagesJson = cacheData['data'] as List<dynamic>;
      return packagesJson
          .map((json) => Package.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Log error - could use proper logging service in production
      return null;
    }
  }

  /// Cache categories
  Future<void> _cacheCategories(PackageCategories categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': categories.toJson(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_categoriesCacheKey, jsonEncode(cacheData));
    } catch (e) {
      // Log error - could use proper logging service in production
    }
  }

  /// Get cached categories
  Future<PackageCategories?> _getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_categoriesCacheKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Check if cache is still valid
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _categoriesCacheDuration.inMilliseconds) {
        // Cache expired, remove it
        await prefs.remove(_categoriesCacheKey);
        return null;
      }
      
      return PackageCategories.fromJson(cacheData['data'] as Map<String, dynamic>);
    } catch (e) {
      // Log error - could use proper logging service in production
      return null;
    }
  }

  /// Clear all package cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final packageCacheKeys = keys.where((key) => key.startsWith(_cachePrefix));
      
      for (final key in packageCacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Log error - could use proper logging service in production
    }
  }

  /// Get cache status
  Future<Map<String, bool>> getCacheStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final featuredCacheString = prefs.getString(_featuredCacheKey);
      final categoriesCacheString = prefs.getString(_categoriesCacheKey);
      
      bool featuredCacheValid = false;
      bool categoriesCacheValid = false;
      
      if (featuredCacheString != null) {
        final cacheData = jsonDecode(featuredCacheString);
        final timestamp = cacheData['timestamp'] as int;
        final cacheAge = now - timestamp;
        featuredCacheValid = cacheAge <= _cacheDuration.inMilliseconds;
      }
      
      if (categoriesCacheString != null) {
        final cacheData = jsonDecode(categoriesCacheString);
        final timestamp = cacheData['timestamp'] as int;
        final cacheAge = now - timestamp;
        categoriesCacheValid = cacheAge <= _categoriesCacheDuration.inMilliseconds;
      }
      
      return {
        'featured': featuredCacheValid,
        'categories': categoriesCacheValid,
      };
    } catch (e) {
      // Log error - could use proper logging service in production
      return {
        'featured': false,
        'categories': false,
      };
    }
  }
}