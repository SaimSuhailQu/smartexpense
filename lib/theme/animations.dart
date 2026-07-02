import 'package:flutter/material.dart';

/// Centralized animation system for Smart Expense Application
///
/// Features:
/// - Duration constants (fast, normal, slow)
/// - Curve presets (smooth, bouncy, elastic)
/// - Transition builders (fade, scale, slide, rotation)
/// - Theme switch animation controller
/// - Card hover/press animations
/// - Shimmer animation curves
/// - Page transition builders
///
/// Design Philosophy:
/// - 60fps smooth animations
/// - Consistent timing across the app
/// - Performance-optimized transitions
/// - Accessibility-friendly motion
class AppAnimations {
  // ==================== DURATION CONSTANTS ====================

  /// Fast animation duration - 200ms
  ///
  /// Use for:
  /// - Button state changes
  /// - Icon transformations
  /// - Quick feedback interactions
  static const Duration fast = Duration(milliseconds: 200);

  /// Normal animation duration - 300ms
  ///
  /// Use for:
  /// - Standard transitions
  /// - Card animations
  /// - Modal appearances
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow animation duration - 500ms
  ///
  /// Use for:
  /// - Page transitions
  /// - Theme switches
  /// - Complex animations
  static const Duration slow = Duration(milliseconds: 500);

  /// Extra slow animation duration - 800ms
  ///
  /// Use for:
  /// - Dramatic reveals
  /// - Complex multi-step animations
  static const Duration extraSlow = Duration(milliseconds: 800);

  /// Shimmer animation duration - 1500ms
  ///
  /// Use for:
  /// - Loading skeleton screens
  /// - Shimmer effects
  static const Duration shimmer = Duration(milliseconds: 1500);

  // ==================== CURVE PRESETS ====================

  /// Smooth curve - Ease in out cubic
  ///
  /// Best for: General purpose animations
  /// Feel: Natural, smooth
  static const Curve smooth = Curves.easeInOutCubic;

  /// Sharp curve - Ease in out quint
  ///
  /// Best for: Snappy, responsive animations
  /// Feel: Quick, decisive
  static const Curve sharp = Curves.easeInOutQuint;

  /// Bouncy curve - Elastic out
  ///
  /// Best for: Playful interactions
  /// Feel: Energetic, fun
  static const Curve bouncy = Curves.elasticOut;

  /// Gentle bounce - Ease out back
  ///
  /// Best for: Subtle emphasis
  /// Feel: Soft landing
  static const Curve gentleBounce = Curves.easeOutBack;

  /// Spring curve - Custom cubic
  ///
  /// Best for: Natural motion
  /// Feel: Physics-based
  static const Curve spring = Curves.easeOutCubic;

  /// Emphasized curve - Material emphasized
  ///
  /// Best for: Material Design 3 standard
  /// Feel: Professional, polished
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Decelerate curve - Ease out
  ///
  /// Best for: Entering animations
  /// Feel: Slowing down, settling
  static const Curve decelerate = Curves.easeOut;

  /// Accelerate curve - Ease in
  ///
  /// Best for: Exiting animations
  /// Feel: Speeding up, leaving
  static const Curve accelerate = Curves.easeIn;

  // ==================== TRANSITION BUILDERS ====================

  /// Fade transition builder
  ///
  /// Creates smooth opacity transition
  ///
  /// Example:
  /// ```dart
  /// AnimatedSwitcher(
  ///   duration: AppAnimations.normal,
  ///   transitionBuilder: AppAnimations.fadeTransition,
  ///   child: widget,
  /// )
  /// ```
  static Widget fadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

  /// Scale transition builder
  ///
  /// Creates smooth scale transition from center
  ///
  /// Parameters:
  /// - [alignment] - Origin point for scaling (default: center)
  static Widget scaleTransition(
    Widget child,
    Animation<double> animation, {
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: animation,
      alignment: alignment,
      child: child,
    );
  }

  /// Slide transition builder
  ///
  /// Creates smooth slide transition
  ///
  /// Parameters:
  /// - [direction] - Direction of slide animation
  static Widget slideTransition(
    Widget child,
    Animation<double> animation,
    AxisDirection direction,
  ) {
    Offset begin;
    switch (direction) {
      case AxisDirection.up:
        begin = const Offset(0.0, 1.0);
        break;
      case AxisDirection.down:
        begin = const Offset(0.0, -1.0);
        break;
      case AxisDirection.left:
        begin = const Offset(1.0, 0.0);
        break;
      case AxisDirection.right:
        begin = const Offset(-1.0, 0.0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  /// Rotation transition builder
  ///
  /// Creates smooth rotation transition
  ///
  /// Parameters:
  /// - [turns] - Number of full rotations (0.25 = 90°, 0.5 = 180°, 1.0 = 360°)
  static Widget rotationTransition(
    Widget child,
    Animation<double> animation, {
    double turns = 0.25,
  }) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.0,
        end: turns,
      ).animate(animation),
      child: child,
    );
  }

  /// Combined fade and scale transition
  ///
  /// Creates smooth fade + scale effect (common pattern)
  static Widget fadeScaleTransition(
    Widget child,
    Animation<double> animation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: smooth,
        )),
        child: child,
      ),
    );
  }

  /// Combined fade and slide transition
  ///
  /// Creates smooth fade + slide effect
  static Widget fadeSlideTransition(
    Widget child,
    Animation<double> animation,
    AxisDirection direction,
  ) {
    return FadeTransition(
      opacity: animation,
      child: slideTransition(child, animation, direction),
    );
  }

  // ==================== THEME SWITCH ANIMATION ====================

  /// Creates animation controller for theme switching
  ///
  /// Example:
  /// ```dart
  /// class _MyWidgetState extends State<MyWidget> with TickerProviderStateMixin {
  ///   late AnimationController _controller;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     _controller = AppAnimations.createThemeSwitchController(this);
  ///   }
  ///
  ///   void toggleTheme() {
  ///     if (_controller.isCompleted) {
  ///       _controller.reverse();
  ///     } else {
  ///       _controller.forward();
  ///     }
  ///   }
  /// }
  /// ```
  static AnimationController createThemeSwitchController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: slow,
    );
  }

  /// Creates a theme transition animation
  ///
  /// Returns an animation that can be used with AnimatedBuilder
  static Animation<double> createThemeTransition(AnimationController controller) {
    return CurvedAnimation(
      parent: controller,
      curve: emphasized,
    );
  }

  // ==================== CARD ANIMATIONS ====================

  /// Creates a card press animation (scale down on press)
  ///
  /// Example:
  /// ```dart
  /// GestureDetector(
  ///   onTapDown: (_) => setState(() => _isPressed = true),
  ///   onTapUp: (_) => setState(() => _isPressed = false),
  ///   onTapCancel: () => setState(() => _isPressed = false),
  ///   child: AppAnimations.cardPressAnimation(
  ///     isPressed: _isPressed,
  ///     child: YourCard(),
  ///   ),
  /// )
  /// ```
  static Widget cardPressAnimation({
    required bool isPressed,
    required Widget child,
    Duration duration = fast,
    Curve curve = smooth,
  }) {
    return AnimatedScale(
      scale: isPressed ? 0.95 : 1.0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  /// Creates a card hover animation (scale up on hover)
  ///
  /// Example:
  /// ```dart
  /// MouseRegion(
  ///   onEnter: (_) => setState(() => _isHovered = true),
  ///   onExit: (_) => setState(() => _isHovered = false),
  ///   child: AppAnimations.cardHoverAnimation(
  ///     isHovered: _isHovered,
  ///     child: YourCard(),
  ///   ),
  /// )
  /// ```
  static Widget cardHoverAnimation({
    required bool isHovered,
    required Widget child,
    Duration duration = fast,
    Curve curve = smooth,
  }) {
    return AnimatedScale(
      scale: isHovered ? 1.02 : 1.0,
      duration: duration,
      curve: curve,
      child: AnimatedContainer(
        duration: duration,
        curve: curve,
        decoration: BoxDecoration(
          boxShadow: isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    spreadRadius: -4,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: child,
      ),
    );
  }

  // ==================== SHIMMER ANIMATION ====================

  /// Creates a shimmer animation controller
  ///
  /// Example:
  /// ```dart
  /// class _LoadingState extends State<Loading> with TickerProviderStateMixin {
  ///   late AnimationController _shimmerController;
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     _shimmerController = AppAnimations.createShimmerController(this);
  ///     _shimmerController.repeat();
  ///   }
  /// }
  /// ```
  static AnimationController createShimmerController(TickerProvider vsync) {
    return AnimationController(
      vsync: vsync,
      duration: shimmer,
    );
  }

  /// Creates a shimmer animation gradient offset
  ///
  /// Returns an animation for use with gradient transforms
  static Animation<double> createShimmerAnimation(AnimationController controller) {
    return Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));
  }

  // ==================== PAGE TRANSITION BUILDERS ====================

  /// Fade page transition builder
  ///
  /// Use with Navigator.push or PageRouteBuilder
  static PageRouteBuilder<T> fadePageRoute<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = smooth,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: curve,
          ),
          child: child,
        );
      },
      transitionDuration: duration,
      settings: settings,
    );
  }

  /// Scale page transition builder
  ///
  /// Use with Navigator.push or PageRouteBuilder
  static PageRouteBuilder<T> scalePageRoute<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = emphasized,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      settings: settings,
    );
  }

  /// Slide page transition builder
  ///
  /// Use with Navigator.push or PageRouteBuilder
  static PageRouteBuilder<T> slidePageRoute<T>({
    required Widget page,
    Duration duration = normal,
    Curve curve = emphasized,
    AxisDirection direction = AxisDirection.left,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case AxisDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          case AxisDirection.down:
            begin = const Offset(0.0, -1.0);
            break;
          case AxisDirection.left:
            begin = const Offset(1.0, 0.0);
            break;
          case AxisDirection.right:
            begin = const Offset(-1.0, 0.0);
            break;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: child,
        );
      },
      transitionDuration: duration,
      settings: settings,
    );
  }

  /// Rotation page transition builder (creative transition)
  ///
  /// Use with Navigator.push or PageRouteBuilder
  static PageRouteBuilder<T> rotationPageRoute<T>({
    required Widget page,
    Duration duration = slow,
    Curve curve = emphasized,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: curve,
          )),
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: duration,
      settings: settings,
    );
  }

  // ==================== HELPER WIDGETS ====================

  /// Animated visibility widget with fade transition
  ///
  /// Convenience wrapper for showing/hiding widgets smoothly
  ///
  /// Example:
  /// ```dart
  /// AppAnimations.animatedVisibility(
  ///   visible: _showDetails,
  ///   child: DetailsWidget(),
  /// )
  /// ```
  static Widget animatedVisibility({
    required bool visible,
    required Widget child,
    Duration duration = normal,
    Curve curve = smooth,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: AnimatedSize(
        duration: duration,
        curve: curve,
        child: visible ? child : const SizedBox.shrink(),
      ),
    );
  }

  /// Staggered animation helper
  ///
  /// Creates staggered entrance animations for lists
  ///
  /// Example:
  /// ```dart
  /// ListView.builder(
  ///   itemBuilder: (context, index) {
  ///     return AppAnimations.staggeredListItem(
  ///       index: index,
  ///       child: ListTile(...),
  ///     );
  ///   },
  /// )
  /// ```
  static Widget staggeredListItem({
    required int index,
    required Widget child,
    Duration duration = normal,
    int staggerDelayMs = 50,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: index * staggerDelayMs),
      curve: emphasized,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  /// Pulse animation widget
  ///
  /// Creates infinite pulsing scale effect
  ///
  /// Example:
  /// ```dart
  /// AppAnimations.pulseAnimation(
  ///   child: Icon(Icons.notification),
  /// )
  /// ```
  static Widget pulseAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1000),
    double minScale = 0.95,
    double maxScale = 1.05,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: maxScale),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, scale, _) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      onEnd: () {
        // This will restart the animation by rebuilding
      },
    );
  }

  /// Loading dots animation
  ///
  /// Creates animated loading indicator with bouncing dots
  ///
  /// Example:
  /// ```dart
  /// AppAnimations.loadingDots()
  /// ```
  static Widget loadingDots({
    Color? color,
    double size = 8.0,
    Duration duration = const Duration(milliseconds: 1400),
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration,
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            final delay = index * 0.2;
            final animValue = (value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (animValue - 0.5).abs() * 2));

            return Container(
              margin: EdgeInsets.symmetric(horizontal: size / 4),
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color ?? Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            );
          },
        );
      }),
    );
  }

  // ==================== NUMBER ANIMATION ====================

  /// Animated number counter
  ///
  /// Creates smooth number transitions for financial values
  ///
  /// Example:
  /// ```dart
  /// AppAnimations.animatedNumber(
  ///   value: 1234.56,
  ///   style: Theme.of(context).textTheme.headlineMedium,
  ///   prefix: '\$',
  /// )
  /// ```
  static Widget animatedNumber({
    required double value,
    TextStyle? style,
    String prefix = '',
    String suffix = '',
    int decimalPlaces = 2,
    Duration duration = normal,
    Curve curve = smooth,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, _) {
        final formattedValue = animatedValue.toStringAsFixed(decimalPlaces);
        return Text(
          '$prefix$formattedValue$suffix',
          style: style,
        );
      },
    );
  }
}

/// Extension on AnimationController for common patterns
extension AnimationControllerExtensions on AnimationController {
  /// Repeats the animation with a delay between iterations
  ///
  /// Example:
  /// ```dart
  /// controller.repeatWithDelay(
  ///   delay: Duration(milliseconds: 500),
  /// );
  /// ```
  Future<void> repeatWithDelay({
    required Duration delay,
    double? min,
    double? max,
    bool reverse = false,
  }) async {
    while (true) {
      await forward(from: min);
      if (reverse) await this.reverse(from: max);
      await Future.delayed(delay);
    }
  }
}

/// Extension on Animation for value mapping
extension AnimationExtensions on Animation<double> {
  /// Maps animation value to a custom range
  ///
  /// Example:
  /// ```dart
  /// final scaledValue = animation.mapTo(min: 0.8, max: 1.2);
  /// ```
  double mapTo({required double min, required double max}) {
    return min + (max - min) * value;
  }
}
