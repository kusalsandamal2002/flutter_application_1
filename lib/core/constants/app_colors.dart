import 'package:flutter/material.dart';

class AppColors {
  // New design system names
  static const Color bg = Color(0xFF0B1220);
  static const Color surface = Color(0xFF121A2B);
  static const Color surfaceAlt = Color(0xFF1A2438);
  static const Color card = Color(0xFF182235);
  static const Color border = Color(0xFF2A3550);

  static const Color primary = Color(0xFFEF8F8F);
  static const Color primarySoft = Color(0xFF3B2630);

  static const Color textPrimary = Color(0xFFF3F6FB);
  static const Color textSecondary = Color(0xFFB7C0D1);
  static const Color textMuted = Color(0xFF8390A7);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFE57373);
  static const Color info = Color(0xFF64B5F6);

  // Backward-compatible aliases for existing app code
  static const Color scaffoldDark = bg;
  static const Color darkCard = card;
  static const Color darkField = surfaceAlt;

  static const Color primaryRed = primary;
  static const Color softText = textSecondary;

  static const Color successGreen = success;
  static const Color blue = info;
}