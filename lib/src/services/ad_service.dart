import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/ad_simple.dart';
import 'api_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  final ApiService _apiService = ApiService();
  final http.Client _httpClient = http.Client();

  // Cache settings
  static const String _cacheKey = 'ad_cache';
  static const String _impressionsCacheKey = 'ad_impressions_cache';
  static const Duration _cacheDuration = Duration(minutes: 15);
  static const int _maxRetries = 3;

  // In-memory cache to avoid duplicate impressions
  final Set<String> _trackedImpressions = {};
  final Set<String> _trackedClicks = {};

  /// Fetch active ads from the server
  Future<ApiResponse<List<Ad>>> getActiveAds({
    bool forceRefresh = false,
    String? placement,
    int limit = 5,
  }) async {
    try {
      // Check cache first if not forcing refresh
      if (!forceRefresh) {
        final cached = await _getCachedAds();
        if (cached != null && cached.isNotEmpty) {
          return ApiResponse<List<Ad>>(
            success: true,
            message: 'Ads loaded from cache',
            data: cached,
            statusCode: 200,
          );
        }
      }

      // Fetch from API
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'active': 'true',
      };
      
      if (placement != null) {
        queryParams['placement'] = placement;
      }

      final response = await _apiService.get<Map<String, dynamic>>(
        '/ads/active',
        queryParameters: queryParams,
        requireAuth: false,
      );

      if (response.success && response.data != null) {
        final adsData = response.data!['data'] ?? response.data!['ads'];
        
        if (adsData == null) {
          return ApiResponse<List<Ad>>(
            success: false,
            message: 'Invalid API response format',
            statusCode: response.statusCode,
          );
        }

        final ads = (adsData as List)
            .map((item) => Ad.fromJson(item as Map<String, dynamic>))
            .where((ad) => ad.isActive) // Filter out inactive ads
            .toList();

        // Sort by priority (highest first)
        ads.sort((a, b) => b.priority.compareTo(a.priority));

        // Cache the results
        await _cacheAds(ads);

        return ApiResponse<List<Ad>>(
          success: true,
          message: response.message,
          data: ads,
          statusCode: response.statusCode,
        );
      }

      return ApiResponse<List<Ad>>(
        success: false,
        message: response.message,
        data: [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('Error fetching ads: $e');
      
      // Try to return cached data even if fetch fails
      final cached = await _getCachedAds();
      if (cached != null && cached.isNotEmpty) {
        return ApiResponse<List<Ad>>(
          success: true,
          message: 'Ads loaded from cache (network error)',
          data: cached,
          statusCode: 200,
        );
      }
      
      return ApiResponse<List<Ad>>(
        success: false,
        message: 'Error loading ads: $e',
        data: [],
        statusCode: 0,
      );
    }
  }

  /// Report ad impression
  Future<bool> reportImpression(Ad ad) async {
    try {
      // Check if already tracked in this session
      if (_trackedImpressions.contains(ad.id)) {
        return true; // Already tracked, don't report again
      }

      final impressionUrl = ad.tracking.impressionUrl;
      if (impressionUrl == null || impressionUrl.isEmpty) {
        return true; // No tracking URL, consider it successful
      }

      // Mark as tracked before making the request
      _trackedImpressions.add(ad.id);

      // Make tracking request with retry logic
      bool success = false;
      for (int i = 0; i < _maxRetries; i++) {
        try {
          final url = _buildTrackingUrl(impressionUrl, ad.id, 'impression');
          final response = await _httpClient.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ad_id': ad.id,
              'timestamp': DateTime.now().toIso8601String(),
              'type': 'impression',
            }),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            success = true;
            break;
          }
        } catch (e) {
          print('Impression tracking attempt ${i + 1} failed: $e');
          if (i == _maxRetries - 1) {
            // Store for retry later
            await _storeFailedTracking('impression', ad.id, impressionUrl);
          }
        }
      }

      // Track additional pixels
      if (ad.tracking.pixels != null && ad.tracking.pixels!.isNotEmpty) {
        _trackPixels(ad.tracking.pixels!);
      }

      return success;
    } catch (e) {
      print('Error reporting impression: $e');
      return false;
    }
  }

  /// Report ad click
  Future<bool> reportClick(Ad ad) async {
    try {
      // Check if already tracked in this session
      if (_trackedClicks.contains(ad.id)) {
        return true; // Already tracked, don't report again
      }

      final clickUrl = ad.tracking.clickUrl;
      if (clickUrl == null || clickUrl.isEmpty) {
        return true; // No tracking URL, consider it successful
      }

      // Mark as tracked before making the request
      _trackedClicks.add(ad.id);

      // Make tracking request with retry logic
      bool success = false;
      for (int i = 0; i < _maxRetries; i++) {
        try {
          final url = _buildTrackingUrl(clickUrl, ad.id, 'click');
          final response = await _httpClient.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ad_id': ad.id,
              'timestamp': DateTime.now().toIso8601String(),
              'type': 'click',
            }),
          ).timeout(const Duration(seconds: 5));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            success = true;
            break;
          }
        } catch (e) {
          print('Click tracking attempt ${i + 1} failed: $e');
          if (i == _maxRetries - 1) {
            // Store for retry later
            await _storeFailedTracking('click', ad.id, clickUrl);
          }
        }
      }

      return success;
    } catch (e) {
      print('Error reporting click: $e');
      return false;
    }
  }

  /// Build tracking URL with parameters
  String _buildTrackingUrl(String baseUrl, String adId, String type) {
    final uri = Uri.parse(baseUrl);
    final params = Map<String, String>.from(uri.queryParameters);
    params['ad_id'] = adId;
    params['type'] = type;
    params['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    
    return uri.replace(queryParameters: params).toString();
  }

  /// Track additional pixels (fire and forget)
  void _trackPixels(List<String> pixels) {
    for (final pixel in pixels) {
      try {
        _httpClient.get(Uri.parse(pixel)).timeout(
          const Duration(seconds: 3),
          onTimeout: () => http.Response('', 408),
        );
      } catch (e) {
        // Silently fail for pixels
        print('Pixel tracking failed: $e');
      }
    }
  }

  /// Cache ads to local storage
  Future<void> _cacheAds(List<Ad> ads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': ads.map((ad) => ad.toJson()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching ads: $e');
    }
  }

  /// Get cached ads from local storage
  Future<List<Ad>?> _getCachedAds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheString = prefs.getString(_cacheKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final timestamp = cacheData['timestamp'] as int;
      
      // Check if cache is still valid
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheDuration.inMilliseconds) {
        await prefs.remove(_cacheKey);
        return null;
      }
      
      final adsData = cacheData['data'] as List;
      return adsData
          .map((item) => Ad.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error reading cached ads: $e');
      return null;
    }
  }

  /// Store failed tracking events for retry
  Future<void> _storeFailedTracking(
    String type,
    String adId,
    String url,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingString = prefs.getString(_impressionsCacheKey) ?? '[]';
      final existing = jsonDecode(existingString) as List;
      
      existing.add({
        'type': type,
        'ad_id': adId,
        'url': url,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only the last 100 failed trackings
      if (existing.length > 100) {
        existing.removeRange(0, existing.length - 100);
      }
      
      await prefs.setString(_impressionsCacheKey, jsonEncode(existing));
    } catch (e) {
      print('Error storing failed tracking: $e');
    }
  }

  /// Retry failed tracking events
  Future<void> retryFailedTracking() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingString = prefs.getString(_impressionsCacheKey);
      
      if (existingString == null) return;
      
      final existing = jsonDecode(existingString) as List;
      final failed = <Map<String, dynamic>>[];
      
      for (final item in existing) {
        try {
          final url = item['url'] as String;
          final response = await _httpClient.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item),
          ).timeout(const Duration(seconds: 5));
          
          if (response.statusCode < 200 || response.statusCode >= 300) {
            failed.add(item as Map<String, dynamic>);
          }
        } catch (e) {
          failed.add(item as Map<String, dynamic>);
        }
      }
      
      // Update cache with only failed items
      if (failed.isEmpty) {
        await prefs.remove(_impressionsCacheKey);
      } else {
        await prefs.setString(_impressionsCacheKey, jsonEncode(failed));
      }
    } catch (e) {
      print('Error retrying failed tracking: $e');
    }
  }

  /// Clear ad cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      _trackedImpressions.clear();
      _trackedClicks.clear();
    } catch (e) {
      print('Error clearing ad cache: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
