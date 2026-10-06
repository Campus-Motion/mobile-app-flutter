import 'package:flutter/material.dart';

class AppColors {
  // Brand Tokens
  static const Color primary = Color(0xFFDE7356);
  static const Color primaryLight = Color(0xFFFBECE8);
  static const Color primaryDark = Color(0xFFC45A3E);

  // Background & Surfaces
  static const Color background = Colors.white;
  static const Color surface = Colors.grey;
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  static const Color divider = Color(0xFFEEEEEE);

  // Typography Tokens
  static const Color text = Colors.black;
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Status & Feedback Tokens
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF1E88E5);

  // Activity Category Tokens (Used in Activity & Profile screens)
  static const Color activityRun = Colors.deepOrange;
  static const Color activityWalk = Colors.teal;
  static const Color activityCycle = Colors.blue;
  static const Color activityHike = Colors.green;
  static const Color activitySwim = Colors.cyan;
  static const Color activityDefault = AppColors.primary;

  // Shadow token (10% black opacity)
  static Color get shadow => Colors.black.withValues(alpha: 0.08);
}
