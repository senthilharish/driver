// App colors and theme configuration
import 'package:flutter/material.dart';

class AppColors {
  // Primary colors - Rapido style
  static const Color primaryYellow = Color(0xFFFFD700); // Gold/Yellow
  static const Color primaryBlack = Color(0xFF1A1A1A); // Deep Black
  static const Color accentYellow = Color(0xFFFFC107); // Amber
  
  // Neutral colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFF999999);
  static const Color darkGray = Color(0xFF333333);
  
  // Functional colors
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color infoBlue = Color(0xFF1976D2);
  
  // Gradients
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primaryYellow, accentYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryYellow,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryBlack,
      foregroundColor: AppColors.primaryYellow,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightGray,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.mediumGray),
      labelStyle: const TextStyle(color: AppColors.primaryBlack),
      errorStyle: const TextStyle(color: AppColors.errorRed),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: AppColors.primaryYellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlack,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlack,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlack,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlack,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.darkGray,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.darkGray,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.white,
      ),
    ),
  );
}

class AppPadding {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 15;
  static const double lg = 20;
  static const double xl = 30;
}
