import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/gradients.dart';

/// Enhanced glass morphism container with advanced visual effects
///
/// Features:
/// - Adjustable blur strength (subtle, medium, strong)
/// - Gradient overlay support
/// - Gradient border support
/// - Animated blur transitions
/// - Multiple elevation levels
/// - Optional noise texture overlay
/// - WCAG AA compliant in both light and dark modes
///
/// Usage:
/// ```dart
/// GlassContainer(
///   blurStrength: BlurStrength.medium,
///   gradient: AppGradients.primaryGradient,
///   borderGradient: AppGradients.glassBorderGradient(isDark),
///   animatedBlur: true,
///   noiseOverlay: true,
///   child: YourWidget(),
/// )
/// ```
class GlassContainer extends StatefulWidget {
  /// Child widget to be displayed inside the glass container
  final Widget child;

  /// Border radius for the container
  final BorderRadius? borderRadius;

  /// Blur strength preset (subtle, medium, strong)
  /// Overrides [blurX] and [blurY] if provided
  final BlurStrength? blurStrength;

  /// Custom horizontal blur intensity (used if [blurStrength] is null)
  final double blurX;

  /// Custom vertical blur intensity (used if [blurStrength] is null)
  final double blurY;

  /// Border width
  final double borderWidth;

  /// Padding inside the container
  final EdgeInsetsGeometry padding;

  /// Margin outside the container
  final EdgeInsetsGeometry? margin;

  /// Custom gradient overlay (overrides default glass gradient)
  final Gradient? gradient;

  /// Custom border gradient (creates gradient border effect)
  final Gradient? borderGradient;

  /// Base color for the glass effect (used if gradient is null)
  final Color? color;

  /// Custom box shadows
  final List<BoxShadow>? shadows;

  /// Border color (used if borderGradient is null)
  final Color? borderColor;

  /// Enable animated blur transitions
  /// Smoothly animates blur changes on hover or interaction
  final bool animatedBlur;

  /// Duration for animated blur transitions
  final Duration animationDuration;

  /// Enable noise texture overlay for enhanced glass effect
  /// Adds subtle grain for more realistic glass appearance
  final bool noiseOverlay;

  /// Noise overlay opacity (0.0 to 1.0)
  final double noiseOpacity;

  /// Elevation level for shadow and depth (1-4)
  /// Higher values create stronger shadows
  final int elevation;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurStrength,
    this.blurX = 16.0,
    this.blurY = 16.0,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.gradient,
    this.borderGradient,
    this.color,
    this.shadows,
    this.borderColor,
    this.animatedBlur = false,
    this.animationDuration = const Duration(milliseconds: 300),
    this.noiseOverlay = false,
    this.noiseOpacity = 0.03,
    this.elevation = 2,
  }) : assert(elevation >= 1 && elevation <= 4, 'Elevation must be between 1 and 4');

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _blurAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for animated blur
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _blurAnimation = Tween<double>(
      begin: 1.0,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get blur values based on strength preset or custom values
  (double, double) _getBlurValues() {
    if (widget.blurStrength != null) {
      switch (widget.blurStrength!) {
        case BlurStrength.subtle:
          return (8.0, 8.0);
        case BlurStrength.medium:
          return (16.0, 16.0);
        case BlurStrength.strong:
          return (32.0, 32.0);
      }
    }
    return (widget.blurX, widget.blurY);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultBorderRadius = widget.borderRadius ?? BorderRadius.circular(24.0);

    // Get blur values
    final (blurX, blurY) = _getBlurValues();

    // Apply animation multiplier if animated blur is enabled
    final effectiveBlurX = widget.animatedBlur
        ? blurX * _blurAnimation.value
        : blurX;
    final effectiveBlurY = widget.animatedBlur
        ? blurY * _blurAnimation.value
        : blurY;

    // Dynamic HSL-tailored colors for glass morphism effect
    final Color glassColor = widget.color ??
        (isDark
            ? Colors.black.withValues(alpha: 0.25) // Enhanced translucent black
            : Colors.white.withValues(alpha: 0.60)); // Enhanced translucent white

    final Color glassBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15) // Enhanced white edge
            : Colors.black.withValues(alpha: 0.10)); // Enhanced dark edge

    // Determine gradient overlay
    final effectiveGradient = widget.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  glassColor,
                  glassColor.withValues(alpha: 0.15),
                  glassColor.withValues(alpha: 0.10),
                ]
              : [
                  glassColor,
                  glassColor.withValues(alpha: 0.50),
                  glassColor.withValues(alpha: 0.40),
                ],
          stops: const [0.0, 0.5, 1.0],
        );

    // Calculate elevation-based shadows
    final effectiveShadows = widget.shadows ?? _getElevationShadows(isDark);

    return MouseRegion(
      onEnter: widget.animatedBlur ? (_) => _handleHoverChange(true) : null,
      onExit: widget.animatedBlur ? (_) => _handleHoverChange(false) : null,
      child: AnimatedBuilder(
        animation: _blurAnimation,
        builder: (context, child) {
          return Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: defaultBorderRadius,
              boxShadow: effectiveShadows,
            ),
            child: ClipRRect(
              borderRadius: defaultBorderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: effectiveBlurX,
                  sigmaY: effectiveBlurY,
                ),
                child: Stack(
                  children: [
                    // Main glass container
                    Container(
                      padding: widget.padding,
                      decoration: BoxDecoration(
                        borderRadius: defaultBorderRadius,
                        gradient: effectiveGradient,
                      ),
                      child: widget.child,
                    ),

                    // Gradient border overlay (if provided)
                    if (widget.borderGradient != null)
                      _GradientBorder(
                        borderRadius: defaultBorderRadius,
                        borderWidth: widget.borderWidth,
                        gradient: widget.borderGradient!,
                      )
                    else
                      // Standard border
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: defaultBorderRadius,
                          border: Border.all(
                            color: glassBorderColor,
                            width: widget.borderWidth,
                          ),
                        ),
                      ),

                    // Noise texture overlay (if enabled)
                    if (widget.noiseOverlay)
                      _NoiseOverlay(
                        borderRadius: defaultBorderRadius,
                        opacity: widget.noiseOpacity,
                        isDark: isDark,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handle hover state changes for animated blur
  void _handleHoverChange(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });

    if (_isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  /// Get elevation-based shadows
  List<BoxShadow> _getElevationShadows(bool isDark) {
    final baseColor = isDark ? Colors.black : Colors.black;
    final baseOpacity = isDark ? 0.50 : 0.08;

    switch (widget.elevation) {
      case 1:
        return [
          BoxShadow(
            color: baseColor.withValues(alpha: baseOpacity * 0.5),
            blurRadius: 8,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: baseColor.withValues(alpha: baseOpacity),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ];
      case 3:
        return [
          BoxShadow(
            color: baseColor.withValues(alpha: baseOpacity * 1.5),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: baseColor.withValues(alpha: baseOpacity * 2),
            blurRadius: 32,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ];
      default:
        return [
          BoxShadow(
            color: baseColor.withValues(alpha: baseOpacity),
            blurRadius: 16,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ];
    }
  }
}

/// Blur strength presets for GlassContainer
enum BlurStrength {
  /// Subtle blur (8.0) - for minimal glass effect
  subtle,

  /// Medium blur (16.0) - balanced glass effect (default)
  medium,

  /// Strong blur (32.0) - intense glass effect
  strong,
}

/// Widget to create gradient border effect
class _GradientBorder extends StatelessWidget {
  final BorderRadius borderRadius;
  final double borderWidth;
  final Gradient gradient;

  const _GradientBorder({
    required this.borderRadius,
    required this.borderWidth,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: gradient,
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius.topLeft.x - borderWidth),
            topRight: Radius.circular(borderRadius.topRight.x - borderWidth),
            bottomLeft: Radius.circular(borderRadius.bottomLeft.x - borderWidth),
            bottomRight: Radius.circular(borderRadius.bottomRight.x - borderWidth),
          ),
          color: Colors.transparent,
        ),
      ),
    );
  }
}

/// Widget to create noise texture overlay
class _NoiseOverlay extends StatelessWidget {
  final BorderRadius borderRadius;
  final double opacity;
  final bool isDark;

  const _NoiseOverlay({
    required this.borderRadius,
    required this.opacity,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        // Create subtle grain effect using a repeating pattern
        color: isDark
            ? Colors.white.withValues(alpha: opacity)
            : Colors.black.withValues(alpha: opacity),
        // Note: For true noise texture, consider using a shader or custom painter
        // This is a simplified version using opacity for performance
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        backgroundBlendMode: BlendMode.overlay,
      ),
    );
  }
}

/// Specialized glass container with subtle blur for light overlays
class SubtleGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;

  const SubtleGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blurStrength: BlurStrength.subtle,
      elevation: 1,
      padding: padding ?? const EdgeInsets.all(16.0),
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Specialized glass container with strong blur for prominent sections
class StrongGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool animatedBlur;

  const StrongGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.animatedBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      blurStrength: BlurStrength.strong,
      elevation: 3,
      padding: padding ?? const EdgeInsets.all(24.0),
      margin: margin,
      borderRadius: borderRadius,
      borderGradient: AppGradients.glassBorderGradient(isDark),
      animatedBlur: animatedBlur,
      noiseOverlay: true,
      child: child,
    );
  }
}

/// Specialized glass container with gradient overlay
class GradientGlassContainer extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final BlurStrength blurStrength;

  const GradientGlassContainer({
    super.key,
    required this.child,
    required this.gradient,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blurStrength = BlurStrength.medium,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      blurStrength: blurStrength,
      gradient: gradient,
      borderGradient: AppGradients.glassBorderGradient(isDark),
      padding: padding ?? const EdgeInsets.all(20.0),
      margin: margin,
      borderRadius: borderRadius,
      elevation: 2,
      child: child,
    );
  }
}
