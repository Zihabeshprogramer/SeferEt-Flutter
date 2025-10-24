import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.blackTransparent,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                      if (loadingText != null) ...[
                        const SizedBox(height: AppTheme.spacingMedium),
                        Text(
                          loadingText!,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
