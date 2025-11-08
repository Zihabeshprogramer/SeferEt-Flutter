import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Handles both internal deep links and external URLs
class DeepLinkHandler {
  /// Known safe internal routes
  static const Set<String> _safeRoutes = {
    '/home',
    '/explore-screen',
    '/flight-search',
    '/flight-detail',
    '/flight-results',
    '/flight-booking',
    '/hotel-search',
    '/hotel-detail',
    '/tour-details',
    '/package-detail',
    '/search',
    '/profile-screen',
    '/my-bookings',
    '/favorites',
    '/settings',
    '/notifications',
    '/help',
    '/about',
  };

  /// Handle a CTA tap - routes internally or opens externally
  static Future<bool> handleCTA({
    required BuildContext context,
    required String targetUrl,
    required String type,
    Map<String, dynamic>? arguments,
  }) async {
    try {
      if (type.toLowerCase() == 'internal') {
        return await _handleInternalRoute(
          context: context,
          route: targetUrl,
          arguments: arguments,
        );
      } else if (type.toLowerCase() == 'external') {
        return await _handleExternalUrl(targetUrl);
      } else {
        // Unknown type, try to determine based on URL format
        if (_isInternalRoute(targetUrl)) {
          return await _handleInternalRoute(
            context: context,
            route: targetUrl,
            arguments: arguments,
          );
        } else {
          return await _handleExternalUrl(targetUrl);
        }
      }
    } catch (e) {
      debugPrint('Error handling CTA: $e');
      return false;
    }
  }

  /// Check if a route is a known safe internal route
  static bool _isInternalRoute(String route) {
    // Remove query parameters and fragments for checking
    final uri = Uri.tryParse(route);
    if (uri == null) return false;

    final path = uri.path;
    
    // Check exact match
    if (_safeRoutes.contains(path)) return true;
    
    // Check if it's a parametric route (e.g., /flight-detail/:id)
    for (final safeRoute in _safeRoutes) {
      if (path.startsWith(safeRoute)) return true;
    }
    
    return false;
  }

  /// Handle internal route navigation
  static Future<bool> _handleInternalRoute({
    required BuildContext context,
    required String route,
    Map<String, dynamic>? arguments,
  }) async {
    try {
      // Parse the route to extract path and query parameters
      final uri = Uri.tryParse(route);
      if (uri == null) {
        debugPrint('Invalid route format: $route');
        return false;
      }

      final path = uri.path;
      
      // Check if route is safe
      if (!_isInternalRoute(path)) {
        debugPrint('Unsafe route attempted: $path');
        _showRouteError(context, 'This link cannot be opened');
        return false;
      }

      // Merge query parameters into arguments
      final finalArguments = <String, dynamic>{
        ...?arguments,
        ...uri.queryParameters,
      };

      // Navigate using Navigator
      await Navigator.pushNamed(
        context,
        path,
        arguments: finalArguments.isNotEmpty ? finalArguments : null,
      );

      return true;
    } catch (e) {
      debugPrint('Error navigating to internal route: $e');
      _showRouteError(context, 'Failed to open link');
      return false;
    }
  }

  /// Handle external URL opening
  static Future<bool> _handleExternalUrl(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        debugPrint('Invalid URL format: $url');
        return false;
      }

      // Security check: only allow http(s) schemes
      if (!uri.hasScheme || 
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        debugPrint('Unsafe URL scheme: ${uri.scheme}');
        return false;
      }

      // Check if URL can be launched
      if (!await canLaunchUrl(uri)) {
        debugPrint('Cannot launch URL: $url');
        return false;
      }

      // Launch URL in external browser
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return launched;
    } catch (e) {
      debugPrint('Error launching external URL: $e');
      return false;
    }
  }

  /// Show error dialog for route errors
  static void _showRouteError(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Parse deep link and extract route information
  static DeepLinkInfo? parseDeepLink(String deepLink) {
    try {
      final uri = Uri.tryParse(deepLink);
      if (uri == null) return null;

      return DeepLinkInfo(
        path: uri.path,
        queryParameters: uri.queryParameters,
        fragment: uri.fragment.isNotEmpty ? uri.fragment : null,
        isInternal: _isInternalRoute(uri.path),
      );
    } catch (e) {
      debugPrint('Error parsing deep link: $e');
      return null;
    }
  }

  /// Validate a route before navigation
  static bool isValidRoute(String route) {
    final uri = Uri.tryParse(route);
    if (uri == null) return false;

    // For external URLs, check scheme
    if (uri.hasScheme) {
      return uri.scheme == 'http' || uri.scheme == 'https';
    }

    // For internal routes, check against safe routes
    return _isInternalRoute(uri.path);
  }

  /// Build a safe route with query parameters
  static String buildRoute(String path, Map<String, String>? queryParams) {
    if (queryParams == null || queryParams.isEmpty) return path;

    final uri = Uri(path: path, queryParameters: queryParams);
    return uri.toString();
  }
}

/// Information parsed from a deep link
class DeepLinkInfo {
  final String path;
  final Map<String, String> queryParameters;
  final String? fragment;
  final bool isInternal;

  DeepLinkInfo({
    required this.path,
    required this.queryParameters,
    this.fragment,
    required this.isInternal,
  });

  @override
  String toString() {
    return 'DeepLinkInfo(path: $path, queryParameters: $queryParameters, '
        'fragment: $fragment, isInternal: $isInternal)';
  }
}
