import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF1B4332);      // Scout Green
  static const Color secondary = Color(0xFFF59E0B);    // Golden Amber
  static const Color info = Color(0xFF0EA5E9);         // Sky Blue

  // UI state colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF97316);
  static const Color error = Color(0xFFEF4444);

  // Background and surface colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textLight = Color(0xFF0F172A);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textDark = Color(0xFFF8FAFC);

  // Section Accent Colors (Dynamic theme mapping based on active scout section)
  static const Map<String, Color> sectionColors = {
    'singithi': Color(0xFFFCD34D), // Sunshine Yellow
    'cub': Color(0xFFFB923C),      // Coral Orange
    'junior': Color(0xFF3B82F6),   // Royal Blue
    'senior': Color(0xFF16A34A),   // Forest Green
    'rover': Color(0xFF7C3AED),    // Deep Purple
    'leader': Color(0xFF9F1239),   // Rich Burgundy
  };

  static Color getSectionColor(String? sectionId) {
    if (sectionId == null) return primary;
    return sectionColors[sectionId.toLowerCase()] ?? primary;
  }
}
