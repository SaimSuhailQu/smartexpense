import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Comprehensive gradient system for Smart Expense Application
///
/// Features:
/// - Financial gradients (expense, income, budget)
/// - Background gradients (light/dark mode)
/// - Card gradients (subtle overlays)
/// - Accent gradients (primary, secondary, success, error, warning)
/// - Shimmer gradients (for loading states)
/// - WCAG AA compliant gradients
/// - Helper methods for custom gradients
///
/// Design Philosophy:
/// - All gradients maintain WCAG AA contrast ratios
/// - Smooth transitions between colors
/// - Optimized for both light and dark themes
/// - Performance-focused with const constructors where possible
class AppGradients {
  // ==================== FINANCIAL GRADIENTS ====================

  /// Expense gradient - Red spectrum for outgoing money
  ///
  /// Visual cues:
  /// - Light mode: Bright coral to deep red
  /// - Dark mode: Subtle dark red to vibrant red
  /// - WCAG AA compliant on appropriate backgrounds
  static LinearGradient expenseGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF7F1D1D), // Dark red base
              const Color(0xFFEF4444), // Bright red highlight
              const Color(0xFFDC2626), // Deep red accent
            ]
          : [
              const Color(0xFFFEF2F2), // Very light red tint
              const Color(0xFFFF6B6B), // Coral red
              const Color(0xFFEF4444), // Bright red
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Income gradient - Green spectrum for incoming money
  ///
  /// Visual cues:
  /// - Light mode: Soft mint to emerald green
  /// - Dark mode: Deep forest to vibrant green
  /// - WCAG AA compliant on appropriate backgrounds
  static LinearGradient incomeGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              const Color(0xFF064E3B), // Dark green base
              const Color(0xFF10B981), // Emerald green
              const Color(0xFF34D399), // Lighter green highlight
            ]
          : [
              const Color(0xFFF0FDF4), // Very light green tint
              const Color(0xFF34D399), // Mint green
              const Color(0xFF10B981), // Emerald green
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Budget gradient - Dynamic gradient based on spending percentage
  ///
  /// Visual progression:
  /// - 0-70%: Green (safe)
  /// - 70-90%: Amber (warning)
  /// - 90-100%: Orange-red (critical)
  /// - >100%: Deep red (overspent)
  ///
  /// [percentage] - Budget utilization (0.0 to 1.0+)
  /// [isDark] - Dark mode flag
  static LinearGradient budgetGradient(double percentage, bool isDark) {
    final List<Color> colors;

    if (percentage < 0.70) {
      // Safe zone - Green gradient
      colors = isDark
          ? [
              const Color(0xFF064E3B), // Dark green
              const Color(0xFF10B981), // Emerald
              const Color(0xFF34D399), // Light emerald
            ]
          : [
              const Color(0xFFF0FDF4), // Very light green
              const Color(0xFF34D399), // Mint
              const Color(0xFF10B981), // Emerald
            ];
    } else if (percentage < 0.90) {
      // Warning zone - Amber gradient
      colors = isDark
          ? [
              const Color(0xFF78350F), // Dark amber
              const Color(0xFFF59E0B), // Bright amber
              const Color(0xFFFBBF24), // Light amber
            ]
          : [
              const Color(0xFFFEFCE8), // Very light amber
              const Color(0xFFFBBF24), // Light amber
              const Color(0xFFF59E0B), // Bright amber
            ];
    } else if (percentage <= 1.00) {
      // Critical zone - Orange-red gradient
      colors = isDark
          ? [
              const Color(0xFF7C2D12), // Dark orange
              const Color(0xFFF97316), // Bright orange
              const Color(0xFFEF4444), // Red
            ]
          : [
              const Color(0xFFFFF7ED), // Very light orange
              const Color(0xFFF97316), // Bright orange
              const Color(0xFFEF4444), // Red
            ];
    } else {
      // Overspent zone - Deep red gradient
      colors = isDark
          ? [
              const Color(0xFF7F1D1D), // Dark red
              const Color(0xFFDC2626), // Deep red
              const Color(0xFFEF4444), // Bright red
            ]
          : [
              const Color(0xFFFEF2F2), // Very light red
              const Color(0xFFEF4444), // Bright red
              const Color(0xFFDC2626), // Deep red
            ];
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // ==================== BACKGROUND GRADIENTS ====================

  /// Main background gradient for app screens
  ///
  /// Creates subtle depth with minimal visual noise
  /// - Light mode: Pearl to soft lavender
  /// - Dark mode: Deep obsidian to dark indigo
  static LinearGradient backgroundGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              AppColors.backgroundDark, // Infinite obsidian
              const Color(0xFF0A0B14), // Slightly lighter obsidian
              const Color(0xFF10111A), // Dark indigo tint
            ]
          : [
              AppColors.backgroundLight, // Pearl alabaster
              const Color(0xFFF8F9FC), // Soft lavender
              const Color(0xFFF5F6FA), // Light lavender
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Radial gradient for card backgrounds
  ///
  /// Creates subtle spotlight effect from center
  /// Perfect for featured cards or hero sections
  static RadialGradient cardBackgroundGradient(bool isDark) {
    return RadialGradient(
      center: Alignment.topLeft,
      radius: 1.5,
      colors: isDark
          ? [
              AppColors.surfaceDark2, // Elevated dark surface
              AppColors.surfaceDark1, // Mid-level surface
              AppColors.surfaceDark, // Base surface
            ]
          : [
              Colors.white, // Pure white center
              AppColors.surfaceLight1, // Subtle tint
              AppColors.surfaceLight2, // Soft tint
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // ==================== ACCENT GRADIENTS ====================

  /// Primary brand gradient - Cyber-indigo spectrum
  ///
  /// WCAG AA compliant for text overlays
  /// Use for primary CTAs and featured elements
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.primaryLight, // Light indigo
      AppColors.primary, // Cyber-indigo
      AppColors.primaryDark, // Deep indigo
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Secondary accent gradient - Neon cyan spectrum
  ///
  /// Eye-catching gradient for highlights and accents
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF06B6D4), // Cyan
      AppColors.secondary, // Neon cyan
      Color(0xFF00E5FF), // Bright cyan
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Success gradient - Emerald green spectrum
  ///
  /// For positive confirmations and success states
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.successLight, // Light emerald
      AppColors.success, // Emerald
      AppColors.successDark, // Deep emerald
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Error gradient - Vibrant pink-red spectrum
  ///
  /// For error states and critical alerts
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.errorLight, // Light pink
      AppColors.error, // Neon pink
      AppColors.errorDark, // Deep pink
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Warning gradient - Amber-orange spectrum
  ///
  /// For warning states and cautionary messages
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.warningLight, // Light amber
      AppColors.warning, // Bright amber
      AppColors.warningDark, // Deep amber
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Info gradient - Bright blue spectrum
  ///
  /// For informational messages and tips
  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.infoLight, // Light blue
      AppColors.info, // Bright blue
      AppColors.infoDark, // Deep blue
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ==================== SHIMMER GRADIENTS ====================

  /// Shimmer gradient for loading states
  ///
  /// Creates animated shimmer effect for skeleton screens
  /// Works with AnimatedContainer or custom animations
  ///
  /// Usage:
  /// ```dart
  /// Container(
  ///   decoration: BoxDecoration(
  ///     gradient: AppGradients.shimmerGradient(isDark),
  ///   ),
  /// );
  /// ```
  static LinearGradient shimmerGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment(-1.0, -0.3),
      end: Alignment(1.0, 0.3),
      colors: isDark
          ? [
              AppColors.surfaceDark,
              AppColors.surfaceDark1,
              AppColors.surfaceDark2,
              AppColors.surfaceDark1,
              AppColors.surfaceDark,
            ]
          : [
              AppColors.surfaceLight,
              AppColors.surfaceLight1,
              AppColors.surfaceLight2,
              AppColors.surfaceLight1,
              AppColors.surfaceLight,
            ],
      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
    );
  }

  // ==================== GLASS MORPHISM GRADIENTS ====================

  /// Glass overlay gradient for glassmorphism effects
  ///
  /// Semi-transparent gradient for glass containers
  /// Best used with BackdropFilter blur
  static LinearGradient glassGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.02),
              Colors.white.withValues(alpha: 0.01),
            ]
          : [
              Colors.white.withValues(alpha: 0.7),
              Colors.white.withValues(alpha: 0.5),
              Colors.white.withValues(alpha: 0.3),
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Glass border gradient for enhanced glass effects
  ///
  /// Subtle gradient for glass container borders
  /// Creates subtle shimmer on edges
  static LinearGradient glassBorderGradient(bool isDark) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.05),
            ]
          : [
              Colors.white.withValues(alpha: 0.8),
              Colors.white.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.1),
            ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // ==================== HELPER METHODS ====================

  /// Creates a custom linear gradient from a list of colors
  ///
  /// Parameters:
  /// - [colors] - List of colors for the gradient
  /// - [begin] - Starting alignment (default: topLeft)
  /// - [end] - Ending alignment (default: bottomRight)
  /// - [stops] - Optional color stops (evenly distributed if null)
  ///
  /// Example:
  /// ```dart
  /// final gradient = AppGradients.createLinearGradient(
  ///   colors: [Colors.blue, Colors.purple, Colors.pink],
  ///   begin: Alignment.centerLeft,
  ///   end: Alignment.centerRight,
  /// );
  /// ```
  static LinearGradient createLinearGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    List<double>? stops,
  }) {
    assert(colors.length >= 2, 'Gradient must have at least 2 colors');

    // Generate evenly distributed stops if not provided
    final gradientStops = stops ??
        List.generate(
          colors.length,
          (index) => index / (colors.length - 1),
        );

    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: gradientStops,
    );
  }

  /// Creates a custom radial gradient from a list of colors
  ///
  /// Parameters:
  /// - [colors] - List of colors for the gradient
  /// - [center] - Center alignment (default: center)
  /// - [radius] - Radius of the gradient (default: 1.0)
  /// - [stops] - Optional color stops (evenly distributed if null)
  ///
  /// Example:
  /// ```dart
  /// final gradient = AppGradients.createRadialGradient(
  ///   colors: [Colors.white, Colors.blue],
  ///   center: Alignment.topLeft,
  ///   radius: 1.5,
  /// );
  /// ```
  static RadialGradient createRadialGradient({
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double radius = 1.0,
    List<double>? stops,
  }) {
    assert(colors.length >= 2, 'Gradient must have at least 2 colors');

    // Generate evenly distributed stops if not provided
    final gradientStops = stops ??
        List.generate(
          colors.length,
          (index) => index / (colors.length - 1),
        );

    return RadialGradient(
      center: center,
      radius: radius,
      colors: colors,
      stops: gradientStops,
    );
  }

  /// Creates a sweep gradient (circular gradient)
  ///
  /// Parameters:
  /// - [colors] - List of colors for the gradient
  /// - [center] - Center alignment (default: center)
  /// - [startAngle] - Starting angle in radians (default: 0.0)
  /// - [endAngle] - Ending angle in radians (default: 2π)
  /// - [stops] - Optional color stops (evenly distributed if null)
  ///
  /// Example:
  /// ```dart
  /// final gradient = AppGradients.createSweepGradient(
  ///   colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue],
  /// );
  /// ```
  static SweepGradient createSweepGradient({
    required List<Color> colors,
    AlignmentGeometry center = Alignment.center,
    double startAngle = 0.0,
    double endAngle = 6.283185307179586, // 2 * pi
    List<double>? stops,
  }) {
    assert(colors.length >= 2, 'Gradient must have at least 2 colors');

    // Generate evenly distributed stops if not provided
    final gradientStops = stops ??
        List.generate(
          colors.length,
          (index) => index / (colors.length - 1),
        );

    return SweepGradient(
      center: center,
      startAngle: startAngle,
      endAngle: endAngle,
      colors: colors,
      stops: gradientStops,
    );
  }

  /// Applies opacity to all colors in a gradient
  ///
  /// Useful for creating translucent overlays
  ///
  /// Example:
  /// ```dart
  /// final transparentGradient = AppGradients.withValues(alpha: 
  ///   AppGradients.primaryGradient,
  ///   0.5,
  /// );
  /// ```
  static LinearGradient withOpacity(LinearGradient gradient, double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0, 'Opacity must be between 0 and 1');

    return LinearGradient(
      begin: gradient.begin,
      end: gradient.end,
      colors: gradient.colors.map((color) => color.withValues(alpha: opacity)).toList(),
      stops: gradient.stops,
      tileMode: gradient.tileMode,
      transform: gradient.transform,
    );
  }

  /// Creates a gradient that transitions between two existing gradients
  ///
  /// Useful for complex multi-layer effects
  ///
  /// Example:
  /// ```dart
  /// final blended = AppGradients.blendGradients(
  ///   AppGradients.primaryGradient,
  ///   AppGradients.secondaryGradient,
  ///   0.5, // 50% blend
  /// );
  /// ```
  static LinearGradient blendGradients(
    LinearGradient gradient1,
    LinearGradient gradient2,
    double t,
  ) {
    assert(t >= 0.0 && t <= 1.0, 't must be between 0 and 1');
    assert(
      gradient1.colors.length == gradient2.colors.length,
      'Gradients must have the same number of colors',
    );

    final blendedColors = List.generate(
      gradient1.colors.length,
      (index) => Color.lerp(
        gradient1.colors[index],
        gradient2.colors[index],
        t,
      )!,
    );

    return LinearGradient(
      begin: AlignmentGeometry.lerp(gradient1.begin, gradient2.begin, t)!,
      end: AlignmentGeometry.lerp(gradient1.end, gradient2.end, t)!,
      colors: blendedColors,
      stops: gradient1.stops,
    );
  }

  // ==================== PRESET COMBINATIONS ====================

  /// Vibrant rainbow gradient for special occasions or celebrations
  ///
  /// Use sparingly for maximum impact
  static const LinearGradient rainbowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEF4444), // Red
      Color(0xFFF97316), // Orange
      Color(0xFFF59E0B), // Amber
      Color(0xFF10B981), // Green
      Color(0xFF3B82F6), // Blue
      Color(0xFF6366F1), // Indigo
      Color(0xFF8B5CF6), // Violet
    ],
    stops: [0.0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
  );

  /// Sunset gradient - warm and inviting
  ///
  /// Perfect for evening/night mode or warm accents
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFEF2F2), // Light pink
      Color(0xFFFED7AA), // Peach
      Color(0xFFF97316), // Orange
      Color(0xFFDC2626), // Deep red
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );

  /// Ocean gradient - cool and calming
  ///
  /// Perfect for income-related features or calming sections
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF06B6D4), // Light cyan
      Color(0xFF0EA5E9), // Sky blue
      Color(0xFF3B82F6), // Blue
      Color(0xFF1E40AF), // Deep blue
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
  );
}
