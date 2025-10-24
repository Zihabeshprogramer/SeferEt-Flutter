import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_service.dart';

/// Connectivity state
enum ConnectivityStatus {
  online,
  offline,
  unknown,
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  ConnectivityStatus _currentStatus = ConnectivityStatus.unknown;
  final StreamController<ConnectivityStatus> _statusController = 
      StreamController<ConnectivityStatus>.broadcast();

  ConnectivityStatus get currentStatus => _currentStatus;
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;
  bool get isOnline => _currentStatus == ConnectivityStatus.online;
  bool get isOffline => _currentStatus == ConnectivityStatus.offline;

  /// Initialize the connectivity service
  Future<void> initialize() async {
    // Get initial connectivity state
    final initialConnectivity = await _connectivity.checkConnectivity();
    _updateStatus(initialConnectivity);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (error) {
        print('Connectivity error: $error');
        _updateStatus([ConnectivityResult.none]);
      },
    );
  }

  /// Update connectivity status based on connectivity results
  void _updateStatus(List<ConnectivityResult> results) {
    final bool hasConnection = results.any((result) => 
        result != ConnectivityResult.none
    );

    final newStatus = hasConnection 
        ? ConnectivityStatus.online 
        : ConnectivityStatus.offline;

    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(_currentStatus);
    }
  }

  /// Check connectivity status manually
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
      return isOnline;
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}

/// Provider for connectivity service
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for connectivity status stream
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});

/// Provider for current connectivity state
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStatusProvider);
  return connectivityAsync.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // Assume online while loading
    error: (_, __) => false, // Assume offline on error
  );
});

/// Extension to add offline capabilities to ApiResponse
extension OfflineSupport on ApiResponse {
  bool get isNetworkError => !success && statusCode == 0;
  
  String get offlineMessage {
    if (isNetworkError) {
      return 'You are offline. Please check your internet connection.';
    }
    return message;
  }
}