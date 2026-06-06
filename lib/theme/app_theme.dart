import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'typography.dart';
import 'spacing.dart';

/// Enhanced Material theme configuration
///
/// Features:
/// - Tabular figures for all numeric typography
/// - WCAG AA compliant contrast ratios
/// - Refined elevation and shadow system
/// - Consistent spacing and border radius
/// - Optimized input decoration with proper accessibility
class AppTheme {
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,

      // ==================== COLOR SCHEME ====================
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: AppColors.error,
        onPrimary: Colors.white, // WCAG AAA on primary
        onSecondary: AppColors.textPrimaryLight, // WCAG AAA on secondary
        onSurface: AppColors.textPrimaryLight,
        onError: Colors.white, // WCAG AAA on error
      ),

      // ==================== TEXT THEME ====================
      textTheme: AppTypography.buildTextTheme(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),

      // ==================== APP BAR THEME ====================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryLight,
          size: 24,
        ),
        titleTextStyle: AppTypography.headingMedium(
          color: AppColors.textPrimaryLight,
        ),
      ),

      // ==================== CARD THEME ====================
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          side: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal,
          vertical: AppSpacing.cardGap / 2,
        ),
      ),

      // ==================== ELEVATED BUTTON THEME ====================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white, // WCAG AAA contrast
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          padding: AppSpacing.buttonPaddingInsets,
          textStyle: AppTypography.buttonLarge(color: Colors.white),
          minimumSize: const Size(88, 48), // Material Design minimum
        ),
      ),

      // ==================== TEXT BUTTON THEME ====================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.buttonMedium(color: AppColors.primary),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
        ),
      ),

      // ==================== OUTLINED BUTTON THEME ====================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
          textStyle: AppTypography.buttonLarge(color: AppColors.primary),
          padding: AppSpacing.buttonPaddingInsets,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          minimumSize: const Size(88, 48),
        ),
      ),

      // ==================== INPUT DECORATION THEME ====================
      // WCAG AA compliant with proper contrast ratios
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: AppSpacing.inputPaddingInsets,

        // Default border (unfocused)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: BorderSide(
            color: AppColors.neutralGrayLight.withOpacity(0.3),
            width: 1,
          ),
        ),

        // Enabled border (unfocused but interactive)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: BorderSide(
            color: AppColors.neutralGrayLight.withOpacity(0.3),
            width: 1,
          ),
        ),

        // Focused border (WCAG AA: 3:1 contrast for UI components)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),

        // Error border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),

        // Focused error border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),

        // Label and hint styles (WCAG AA compliant)
        labelStyle: AppTypography.labelLarge(
          color: AppColors.textSecondaryLight,
        ),
        hintStyle: AppTypography.bodyMedium(
          color: AppColors.textTertiaryLight,
        ),
        errorStyle: AppTypography.labelSmall(
          color: AppColors.error,
        ),
      ),

      // ==================== FLOATING ACTION BUTTON THEME ====================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
      ),

      // ==================== BOTTOM APP BAR THEME ====================
      bottomAppBarTheme: BottomAppBarThemeData(
        color: AppColors.surfaceLight,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: const CircularNotchedRectangle(),
      ),

      // ==================== CHIP THEME ====================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight2,
        deleteIconColor: AppColors.textSecondaryLight,
        disabledColor: AppColors.neutralGrayLight.withOpacity(0.3),
        selectedColor: AppColors.primary.withOpacity(0.2),
        labelStyle: AppTypography.labelMedium(
          color: AppColors.textPrimaryLight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
        ),
      ),

      // ==================== DIVIDER THEME ====================
      dividerTheme: DividerThemeData(
        color: AppColors.neutralGrayLight.withOpacity(0.2),
        thickness: 1,
        space: AppSpacing.lg,
      ),

      // ==================== DIALOG THEME ====================
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceLight,
        elevation: 24,
        shadowColor: Colors.black.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        ),
        titleTextStyle: AppTypography.headingMedium(
          color: AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTypography.bodyMedium(
          color: AppColors.textSecondaryLight,
        ),
      ),

      // ==================== BOTTOM SHEET THEME ====================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== SNACKBAR THEME ====================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.bodyMedium(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // ==================== COLOR SCHEME ====================
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceDark,
        error: AppColors.error,
        onPrimary: Colors.white, // WCAG AAA on primary
        onSecondary: AppColors.textPrimaryDark, // WCAG AAA on secondary
        onSurface: AppColors.textPrimaryDark,
        onError: Colors.white, // WCAG AAA on error
      ),

      // ==================== TEXT THEME ====================
      textTheme: AppTypography.buildTextTheme(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),

      // ==================== APP BAR THEME ====================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
        titleTextStyle: AppTypography.headingMedium(
          color: AppColors.textPrimaryDark,
        ),
      ),

      // ==================== CARD THEME ====================
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
          side: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal,
          vertical: AppSpacing.cardGap / 2,
        ),
      ),

      // ==================== ELEVATED BUTTON THEME ====================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white, // WCAG AAA contrast
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          padding: AppSpacing.buttonPaddingInsets,
          textStyle: AppTypography.buttonLarge(color: Colors.white),
          minimumSize: const Size(88, 48),
        ),
      ),

      // ==================== TEXT BUTTON THEME ====================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTypography.buttonMedium(color: AppColors.primaryLight),
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
        ),
      ),

      // ==================== OUTLINED BUTTON THEME ====================
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(
            color: AppColors.primaryLight,
            width: 1.5,
          ),
          textStyle: AppTypography.buttonLarge(color: AppColors.primaryLight),
          padding: AppSpacing.buttonPaddingInsets,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          ),
          minimumSize: const Size(88, 48),
        ),
      ),

      // ==================== INPUT DECORATION THEME ====================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: AppSpacing.inputPaddingInsets,

        // Default border (unfocused)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: BorderSide(
            color: AppColors.neutralGrayLight.withOpacity(0.2),
            width: 1,
          ),
        ),

        // Enabled border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: BorderSide(
            color: AppColors.neutralGrayLight.withOpacity(0.2),
            width: 1,
          ),
        ),

        // Focused border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),

        // Error border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(
            color: AppColors.errorLight,
            width: 1.5,
          ),
        ),

        // Focused error border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          borderSide: const BorderSide(
            color: AppColors.errorLight,
            width: 2,
          ),
        ),

        // Label and hint styles
        labelStyle: AppTypography.labelLarge(
          color: AppColors.textSecondaryDark,
        ),
        hintStyle: AppTypography.bodyMedium(
          color: AppColors.textTertiaryDark,
        ),
        errorStyle: AppTypography.labelSmall(
          color: AppColors.errorLight,
        ),
      ),

      // ==================== FLOATING ACTION BUTTON THEME ====================
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        ),
      ),

      // ==================== BOTTOM APP BAR THEME ====================
      bottomAppBarTheme: BottomAppBarThemeData(
        color: AppColors.surfaceDark,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: const CircularNotchedRectangle(),
      ),

      // ==================== CHIP THEME ====================
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceDark2,
        deleteIconColor: AppColors.textSecondaryDark,
        disabledColor: AppColors.neutralGrayDark.withOpacity(0.3),
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: AppTypography.labelMedium(
          color: AppColors.textPrimaryDark,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
        ),
      ),

      // ==================== DIVIDER THEME ====================
      dividerTheme: DividerThemeData(
        color: AppColors.neutralGrayLight.withOpacity(0.1),
        thickness: 1,
        space: AppSpacing.lg,
      ),

      // ==================== DIALOG THEME ====================
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.surfaceDark,
        elevation: 24,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        ),
        titleTextStyle: AppTypography.headingMedium(
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: AppTypography.bodyMedium(
          color: AppColors.textSecondaryDark,
        ),
      ),

      // ==================== BOTTOM SHEET THEME ====================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL),
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ==================== SNACKBAR THEME ====================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceDark2,
        contentTextStyle: AppTypography.bodyMedium(
          color: AppColors.textPrimaryDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
