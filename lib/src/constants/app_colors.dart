import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryColor = Color(0xFF003B95);
  static const Color secondaryColor = Color(0xFF0365FA);
  
  // Background colors
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color lightgrayBackground =  Color(0xFFF5F5F5);

  // Text colors
  static const Color textTitleColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF212121);
  static const Color fadedTextColor = Color(0xFF838383);
  static const Color placeholderTextColor = Color(0xFFC8C8C8);
  
  // Status colors
  static const Color errorColor = Color(0xFFD32F2F);
  
  // Additional colors commonly used in travel apps
  static const Color cardBackgroundColor = Color.fromARGB(255, 213, 221, 255);
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color greyDividerColor = Color(0xFFBDBDBD);
  static const Color iconColor = Color(0xFF757575);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  
  // Gradient colors
  static const List<Color> primaryGradient = [primaryColor, secondaryColor];
  
  // Transparent colors
  static const Color blackTransparent = Color(0x80000000);
  static const Color whiteTransparent = Color(0x80FFFFFF);
}
