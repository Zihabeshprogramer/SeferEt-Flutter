import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/user.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? errors;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, int statusCode, [T? data]) {
    T? responseData;
    if (data != null) {
      responseData = data;
    } else {
      // Try to extract json['data'] and handle different types
      final jsonData = json['data'];
      if (jsonData != null) {
        // Check if jsonData is compatible with T before casting
        if (jsonData is T) {
          responseData = jsonData;
        } else {
          // Type mismatch, leave as null
          responseData = null;
        }
      }
    }
    
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: responseData,
      errors: json['errors'],
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String? _authToken;

  /// Initialize the service and load stored token
  Future<void> initialize() async {
    await _loadStoredToken();
  }

  /// Load authentication token from storage
  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString(AppConstants.tokenKey);
    } catch (e) {
      print('Error loading stored token: $e');
    }
  }

  /// Save authentication token to storage
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.tokenKey, token);
      _authToken = token;
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// Remove authentication token from storage
  Future<void> _removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      _authToken = null;
    } catch (e) {
      print('Error removing token: $e');
    }
  }

  /// Get request headers with authentication
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Make GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requireAuth = true,
  }) async {
    try {
      Uri uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      if (queryParameters != null) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final response = await _client
          .get(uri, headers: _getHeaders(includeAuth: requireAuth))
          .timeout(Duration(seconds: AppConstants.receiveTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Make POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConstants.baseUrl}$endpoint'),
            headers: _getHeaders(includeAuth: requireAuth),
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: AppConstants.sendTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Make PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse('${AppConstants.baseUrl}$endpoint'),
            headers: _getHeaders(includeAuth: requireAuth),
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: AppConstants.sendTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Make DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${AppConstants.baseUrl}$endpoint'),
            headers: _getHeaders(includeAuth: requireAuth),
          )
          .timeout(Duration(seconds: AppConstants.receiveTimeout));

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(http.Response response) {
    try {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ApiResponse<T>.fromJson(jsonData, response.statusCode);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  /// Handle request errors
  ApiResponse<T> _handleError<T>(dynamic error) {
    String message = 'Network error occurred';
    
    if (error is SocketException) {
      message = 'No internet connection';
    } else if (error is HttpException) {
      message = 'HTTP error: ${error.message}';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Request timeout';
    }

    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: 0,
    );
  }

  /// Login user
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email, 
    String password, {
    bool rememberMe = false,
  }) async {
    final loginData = {
      'email': email, 
      'password': password,
      if (rememberMe) 'remember': true,
    };

    final response = await post<Map<String, dynamic>>(
      AppConstants.loginEndpoint,
      loginData,
      requireAuth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data!['access_token'] as String?;
      if (token != null) {
        await _saveToken(token);
      }
    }

    return response;
  }

  /// Register user
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? country,
  }) async {
    final userData = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': AppConstants.roleCustomer, // Default to customer role
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (country != null && country.isNotEmpty) 'country': country,
    };

    final response = await post<Map<String, dynamic>>(
      AppConstants.registerEndpoint,
      userData,
      requireAuth: false,
    );

    if (response.success && response.data != null) {
      final token = response.data!['access_token'] as String?;
      if (token != null) {
        await _saveToken(token);
      }
    }

    return response;
  }

  /// Logout user
  Future<ApiResponse<void>> logout() async {
    final response = await post<void>(
      AppConstants.logoutEndpoint,
      {},
    );

    await _removeToken();
    return response;
  }

  /// Get current user
  Future<ApiResponse<User>> getCurrentUser() async {
    final response = await get<Map<String, dynamic>>(AppConstants.meEndpoint);

    if (response.success && response.data != null) {
      final user = User.fromJson(response.data!);
      return ApiResponse<User>(
        success: true,
        message: response.message,
        data: user,
        statusCode: response.statusCode,
      );
    }

    return ApiResponse<User>(
      success: false,
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  /// Refresh authentication token
  Future<ApiResponse<String>> refreshToken() async {
    final response = await post<Map<String, dynamic>>(
      AppConstants.refreshEndpoint,
      {},
    );

    if (response.success && response.data != null) {
      final token = response.data!['access_token'] as String?;
      if (token != null) {
        await _saveToken(token);
        return ApiResponse<String>(
          success: true,
          message: response.message,
          data: token,
          statusCode: response.statusCode,
        );
      }
    }

    return ApiResponse<String>(
      success: false,
      message: response.message,
      statusCode: response.statusCode,
    );
  }

  /// Get customer dashboard data
  Future<ApiResponse<Map<String, dynamic>>> getCustomerDashboard() async {
    return await get<Map<String, dynamic>>(AppConstants.customerDashboardEndpoint);
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null;

  /// Get current auth token
  String? get authToken => _authToken;

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
