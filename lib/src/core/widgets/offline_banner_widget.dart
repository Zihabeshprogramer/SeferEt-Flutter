import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../services/connectivity_service.dart';

class OfflineBannerWidget extends ConsumerWidget {
  final Widget child;

  const OfflineBannerWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    
    return connectivityAsync.when(
      data: (status) {
        if (status == ConnectivityStatus.offline) {
          return Column(
            children: [
              _buildOfflineBanner(context, ref),
              Expanded(child: child),
            ],
          );
        }
        return child;
      },
      loading: () => child,
      error: (_, __) => child,
    );
  }

  Widget _buildOfflineBanner(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      color: AppColors.errorColor,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off,
              color: AppColors.textTitleColor,
              size: 16,
            ),
            const SizedBox(width: AppTheme.spacingSmall),
            Expanded(
              child: Text(
                'You\'re offline. Some features may not be available.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textTitleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(connectivityServiceProvider).checkConnectivity();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTitleColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSmall,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textTitleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to show a reconnection snackbar when connectivity is restored
class ConnectivitySnackBar {
  static void show(BuildContext context, ConnectivityStatus status) {
    final messenger = ScaffoldMessenger.of(context);
    
    if (status == ConnectivityStatus.online) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.cloud_done,
                color: AppColors.textTitleColor,
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Connection restored',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textTitleColor,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.successColor,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppTheme.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
        ),
      );
    } else if (status == ConnectivityStatus.offline) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.cloud_off,
                color: AppColors.textTitleColor,
                size: 16,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'No internet connection',
                style: AppTheme.bodySmall.copyWith(
                  color: AppColors.textTitleColor,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.errorColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppTheme.spacingMedium),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: AppColors.textTitleColor,
            onPressed: () {
              // You can trigger a retry here if needed
            },
          ),
        ),
      );
    }
  }
}

/// Mixin to handle connectivity status changes in widgets
mixin ConnectivityMixin on ConsumerState {
  late final StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  
  @override
  void initState() {
    super.initState();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    final service = ref.read(connectivityServiceProvider);
    _connectivitySubscription = service.statusStream.listen(
      (status) => onConnectivityChanged(status),
      onError: (error) => onConnectivityError(error),
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Override this method to handle connectivity changes
  void onConnectivityChanged(ConnectivityStatus status) {
    if (mounted) {
      ConnectivitySnackBar.show(context, status);
    }
  }

  /// Override this method to handle connectivity errors
  void onConnectivityError(dynamic error) {
    print('Connectivity error in $runtimeType: $error');
  }
}