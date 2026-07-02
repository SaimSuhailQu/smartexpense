import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' show FontFeature;

/// Enhanced typography system with tabular figures for financial data
///
/// Design Philosophy:
/// - Semantic text styles for clear hierarchy
/// - Tabular figures (monospaced numbers) for all financial amounts
/// - Optimized for financial data presentation and readability
/// - Consistent font weights following typographic best practices
class AppTypography {
  // ==================== FONT FAMILIES ====================
  // Base font families using Google Fonts
  static TextStyle get _interBase => GoogleFonts.inter();
  static TextStyle get _jakartaBase => GoogleFonts.plusJakartaSans();

  // ==================== FINANCIAL TEXT STYLES ====================
  // Financial typography with tabular figures for aligned numbers

  /// Large financial amounts (e.g., dashboard totals, primary balances)
  /// Font: Plus Jakarta Sans Bold, 32px with tabular figures
  static TextStyle financialLarge({Color? color}) => _jakartaBase.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
    color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Medium financial amounts (e.g., expense/income cards, totals)
  /// Font: Plus Jakarta Sans SemiBold, 20px with tabular figures
  static TextStyle financialMedium({Color? color}) => _jakartaBase.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Small financial amounts (e.g., budget remaining, secondary amounts)
  /// Font: Plus Jakarta Sans SemiBold, 16px with tabular figures
  static TextStyle financialSmall({Color? color}) => _jakartaBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Extra small financial amounts (e.g., chart labels, table cells)
  /// Font: Plus Jakarta Sans Medium, 14px with tabular figures
  static TextStyle financialExtraSmall({Color? color}) => _jakartaBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
    color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // ==================== HEADING TEXT STYLES ====================
  // Headings for section titles, page headers, etc.

  /// Extra large heading (e.g., page titles, major sections)
  /// Font: Plus Jakarta Sans Bold, 28px
  static TextStyle headingXLarge({Color? color}) => _jakartaBase.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
    color: color,
  );

  /// Large heading (e.g., section titles)
  /// Font: Plus Jakarta Sans Bold, 24px
  static TextStyle headingLarge({Color? color}) => _jakartaBase.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.4,
    height: 1.3,
    color: color,
  );

  /// Medium heading (e.g., card titles, subsection headers)
  /// Font: Plus Jakarta Sans SemiBold, 20px
  static TextStyle headingMedium({Color? color}) => _jakartaBase.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.3,
    color: color,
  );

  /// Small heading (e.g., list item titles)
  /// Font: Plus Jakarta Sans SemiBold, 16px
  static TextStyle headingSmall({Color? color}) => _jakartaBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
    color: color,
  );

  // ==================== BODY TEXT STYLES ====================
  // Body text for general content, descriptions, etc.

  /// Large body text (e.g., important descriptions)
  /// Font: Inter Regular, 16px
  static TextStyle bodyLarge({Color? color}) => _interBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: color,
  );

  /// Medium body text (e.g., standard paragraphs, descriptions)
  /// Font: Inter Regular, 14px
  static TextStyle bodyMedium({Color? color}) => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: color,
  );

  /// Small body text (e.g., supporting text, hints)
  /// Font: Inter Regular, 12px
  static TextStyle bodySmall({Color? color}) => _interBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: color,
  );

  // ==================== LABEL TEXT STYLES ====================
  // Labels for form fields, captions, metadata, etc.

  /// Large label (e.g., form field labels, button text)
  /// Font: Inter Medium, 14px
  static TextStyle labelLarge({Color? color}) => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: color,
  );

  /// Medium label (e.g., secondary labels, category tags)
  /// Font: Inter Medium, 12px
  static TextStyle labelMedium({Color? color}) => _interBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
    color: color,
  );

  /// Small label (e.g., captions, timestamps, metadata)
  /// Font: Inter Medium, 11px
  static TextStyle labelSmall({Color? color}) => _interBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
    color: color,
  );

  // ==================== BUTTON TEXT STYLES ====================

  /// Large button text
  /// Font: Plus Jakarta Sans SemiBold, 16px
  static TextStyle buttonLarge({Color? color}) => _jakartaBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
    color: color,
  );

  /// Medium button text
  /// Font: Plus Jakarta Sans SemiBold, 14px
  static TextStyle buttonMedium({Color? color}) => _jakartaBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
    color: color,
  );

  /// Small button text
  /// Font: Plus Jakarta Sans SemiBold, 12px
  static TextStyle buttonSmall({Color? color}) => _jakartaBase.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.2,
    color: color,
  );

  // ==================== UTILITY STYLES ====================

  /// Overline text (e.g., section headers, category labels)
  /// Font: Inter SemiBold, 11px, uppercase
  static TextStyle overline({Color? color}) => _interBase.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
    height: 1.4,
    color: color,
  );

  /// Code/monospace text (e.g., transaction IDs, reference numbers)
  /// Font: Inter Regular, 14px with tabular figures
  static TextStyle code({Color? color}) => _interBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
    color: color,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // ==================== THEME TEXT THEME BUILDER ====================

  /// Builds a complete TextTheme for Material Design
  /// Uses our custom typography system while maintaining Material compatibility
  static TextTheme buildTextTheme({
    required Color bodyColor,
    required Color displayColor,
  }) {
    return TextTheme(
      // Display styles (largest headings)
      displayLarge: headingXLarge(color: displayColor),
      displayMedium: headingLarge(color: displayColor),
      displaySmall: headingMedium(color: displayColor),

      // Headline styles (section headers)
      headlineLarge: headingLarge(color: displayColor),
      headlineMedium: headingMedium(color: displayColor),
      headlineSmall: headingSmall(color: displayColor),

      // Title styles (card headers, list titles)
      titleLarge: headingMedium(color: bodyColor),
      titleMedium: headingSmall(color: bodyColor),
      titleSmall: labelLarge(color: bodyColor),

      // Body styles (paragraphs, content)
      bodyLarge: bodyLarge(color: bodyColor),
      bodyMedium: bodyMedium(color: bodyColor),
      bodySmall: bodySmall(color: bodyColor),

      // Label styles (form labels, captions)
      labelLarge: labelLarge(color: bodyColor),
      labelMedium: labelMedium(color: bodyColor),
      labelSmall: labelSmall(color: bodyColor),
    );
  }
}
