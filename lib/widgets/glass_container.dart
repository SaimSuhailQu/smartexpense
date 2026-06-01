import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final double blurX;
  final double blurY;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? color;
  final List<BoxShadow>? shadows;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.blurX = 16.0,
    this.blurY = 16.0,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.gradient,
    this.color,
    this.shadows,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBorderRadius = borderRadius ?? BorderRadius.circular(24.0);

    // Dynamic HSL-tailored colors for glass glassmorphism effect
    final Color glassColor = color ??
        (isDark
            ? Colors.black.withAlpha(64) // Translucent deep black-grey
            : Colors.white.withAlpha(153)); // Translucent clean white

    final Color glassBorderColor = borderColor ??
        (isDark
            ? Colors.white.withAlpha(20) // Subtle white edge highlight
            : Colors.black.withAlpha(15)); // Soft dark edge shadow

    final defaultGradient = gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  glassColor,
                  glassColor.withAlpha(30),
                ]
              : [
                  glassColor,
                  glassColor.withAlpha(100),
                ],
        );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: defaultBorderRadius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(80)
                    : Colors.black.withAlpha(10),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: defaultBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: defaultBorderRadius,
              gradient: defaultGradient,
              border: Border.all(
                color: glassBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
