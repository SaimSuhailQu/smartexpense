import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors - Futuristic Cyber-Indigo & Vibrant Neon Accents
  static const Color primary = Color(0xFF6366F1); // Indigo / Neon Purple
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF00F2FE); // Aqua Neon Cyan
  
  // Neutral Colors (Light Theme - Pearl Alabaster Acrylic)
  static const Color backgroundLight = Color(0xFFFAFAFD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF0B0C10);
  static const Color textSecondaryLight = Color(0xFF5A607F);
  
  // Neutral Colors (Dark Theme - Infinite Obsidian Space)
  static const Color backgroundDark = Color(0xFF05050C);
  static const Color surfaceDark = Color(0xFF10111A);
  static const Color textPrimaryDark = Color(0xFFF1F2F6);
  static const Color textSecondaryDark = Color(0xFF8C92AC);

  // Semantic Colors - Glowing & High-Fidelity
  static const Color success = Color(0xFF10B981); // Radiant Emerald
  static const Color warning = Color(0xFFF59E0B); // Glowing Amber
  static const Color error = Color(0xFFEC4899);   // Neon Coral Pink / Fuchsia
  static const Color info = Color(0xFF3B82F6);    // Bright Blue
  
  // Legacy mapping for compatibility
  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color warningColor = warning;
  static const Color errorColor = error;
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF00F2FE), // Neon Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Neon Pink
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
  ];
}