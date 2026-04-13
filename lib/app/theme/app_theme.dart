import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkRedTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryRed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}