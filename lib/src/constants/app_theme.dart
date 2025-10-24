import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static const String fontFamily = 'Poppins';
  
  // Text styles
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );
  
  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );
  
  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );
  
  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );
  
  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textColor,
  );
  
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textColor,
  );
  
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textColor,
  );
  
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textColor,
  );
  
  // Button text styles
  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitleColor,
  );
  
  static const TextStyle buttonTextSecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );
  
  // Faded text styles
  static TextStyle get fadedText => bodyMedium.copyWith(
    color: AppColors.fadedTextColor,
  );
  
  static TextStyle get placeholderText => bodyMedium.copyWith(
    color: AppColors.placeholderTextColor,
  );
  
  // Spacing constants
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  
  // Border radius constants
  static const double borderRadiusXSmall = 3.0;
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  
  // Elevation constants
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
}
