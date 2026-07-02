# Theme System Quick Reference

## Quick Import Guide

```dart
// Import gradients
import 'package:smartexpense/theme/gradients.dart';

// Import animations
import 'package:smartexpense/theme/animations.dart';

// Import glass container
import 'package:smartexpense/widgets/glass_container.dart';
```

---

## Gradients Cheat Sheet

### Financial Gradients
```dart
AppGradients.expenseGradient(isDark)           // Red spectrum
AppGradients.incomeGradient(isDark)            // Green spectrum
AppGradients.budgetGradient(0.85, isDark)      // Dynamic (0.0-1.0+)
```

### Background Gradients
```dart
AppGradients.backgroundGradient(isDark)        // Screen backgrounds
AppGradients.cardBackgroundGradient(isDark)    // Card backgrounds (radial)
```

### Accent Gradients (const)
```dart
AppGradients.primaryGradient                   // Cyber-indigo
AppGradients.secondaryGradient                 // Neon cyan
AppGradients.successGradient                   // Emerald green
AppGradients.errorGradient                     // Pink-red
AppGradients.warningGradient                   // Amber-orange
AppGradients.infoGradient                      // Bright blue
```

### Special Effects
```dart
AppGradients.shimmerGradient(isDark)           // Loading states
AppGradients.glassGradient(isDark)             // Glass overlay
AppGradients.glassBorderGradient(isDark)       // Glass borders
AppGradients.rainbowGradient                   // Special occasions
```

### Helpers
```dart
AppGradients.createLinearGradient(colors: [...])
AppGradients.createRadialGradient(colors: [...])
AppGradients.createSweepGradient(colors: [...])
AppGradients.withOpacity(gradient, 0.5)
AppGradients.blendGradients(grad1, grad2, 0.5)
```

---

## GlassContainer Cheat Sheet

### Basic Usage
```dart
GlassContainer(child: Widget())
```

### Blur Strength
```dart
blurStrength: BlurStrength.subtle    // 8.0
blurStrength: BlurStrength.medium    // 16.0 (default)
blurStrength: BlurStrength.strong    // 32.0
```

### With Gradient
```dart
GlassContainer(
  gradient: AppGradients.primaryGradient,
  borderGradient: AppGradients.glassBorderGradient(isDark),
  child: Widget(),
)
```

### Animated Blur
```dart
GlassContainer(
  animatedBlur: true,
  animationDuration: Duration(milliseconds: 300),
  child: Widget(),
)
```

### Elevation (1-4)
```dart
elevation: 1  // Subtle shadow
elevation: 2  // Medium shadow (default)
elevation: 3  // Strong shadow
elevation: 4  // Very strong shadow
```

### Noise Overlay
```dart
noiseOverlay: true
noiseOpacity: 0.03  // 0.0 to 1.0
```

### Specialized Variants
```dart
SubtleGlassContainer(child: Widget())
StrongGlassContainer(child: Widget())
GradientGlassContainer(gradient: grad, child: Widget())
```

---

## Animations Cheat Sheet

### Durations
```dart
AppAnimations.fast        // 200ms
AppAnimations.normal      // 300ms
AppAnimations.slow        // 500ms
AppAnimations.extraSlow   // 800ms
AppAnimations.shimmer     // 1500ms
```

### Curves
```dart
AppAnimations.smooth         // easeInOutCubic
AppAnimations.sharp          // easeInOutQuint
AppAnimations.bouncy         // elasticOut
AppAnimations.gentleBounce   // easeOutBack
AppAnimations.spring         // easeOutCubic
AppAnimations.emphasized     // M3 standard
AppAnimations.decelerate     // easeOut
AppAnimations.accelerate     // easeIn
```

### Transitions
```dart
// In AnimatedSwitcher
transitionBuilder: AppAnimations.fadeTransition
transitionBuilder: (child, anim) => AppAnimations.scaleTransition(child, anim)
transitionBuilder: (child, anim) => AppAnimations.slideTransition(child, anim, AxisDirection.up)
transitionBuilder: (child, anim) => AppAnimations.rotationTransition(child, anim)
transitionBuilder: AppAnimations.fadeScaleTransition
transitionBuilder: (child, anim) => AppAnimations.fadeSlideTransition(child, anim, AxisDirection.up)
```

### Card Animations
```dart
// Press effect
AppAnimations.cardPressAnimation(
  isPressed: _isPressed,
  child: Widget(),
)

// Hover effect
AppAnimations.cardHoverAnimation(
  isHovered: _isHovered,
  child: Widget(),
)
```

### Page Transitions
```dart
Navigator.push(context, AppAnimations.fadePageRoute(page: Screen()))
Navigator.push(context, AppAnimations.scalePageRoute(page: Screen()))
Navigator.push(context, AppAnimations.slidePageRoute(page: Screen(), direction: AxisDirection.left))
```

### Helper Widgets
```dart
// Visibility
AppAnimations.animatedVisibility(
  visible: bool,
  child: Widget(),
)

// Staggered list
AppAnimations.staggeredListItem(
  index: index,
  child: Widget(),
)

// Pulse
AppAnimations.pulseAnimation(
  child: Widget(),
)

// Loading dots
AppAnimations.loadingDots()

// Animated number
AppAnimations.animatedNumber(
  value: 1234.56,
  prefix: '\$',
)
```

### Controllers
```dart
// Theme switch
_controller = AppAnimations.createThemeSwitchController(this);
_animation = AppAnimations.createThemeTransition(_controller);

// Shimmer
_controller = AppAnimations.createShimmerController(this);
_animation = AppAnimations.createShimmerAnimation(_controller);
_controller.repeat();
```

---

## Common Patterns

### Expense Card
```dart
GlassContainer(
  blurStrength: BlurStrength.medium,
  gradient: AppGradients.expenseGradient(isDark),
  borderGradient: AppGradients.glassBorderGradient(isDark),
  child: Column(
    children: [
      Text('Food'),
      AppAnimations.animatedNumber(value: 45.67, prefix: '\$'),
    ],
  ),
)
```

### Budget Progress Bar
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppGradients.budgetGradient(percentage, isDark),
  ),
)
```

### Loading Skeleton
```dart
class LoadingSkeleton extends StatefulWidget {
  @override
  _LoadingSkeletonState createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppAnimations.createShimmerController(this);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: AppGradients.shimmerGradient(isDark),
          ),
        );
      },
    );
  }
}
```

### Interactive Card
```dart
class InteractiveCard extends StatefulWidget {
  @override
  _InteractiveCardState createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AppAnimations.cardHoverAnimation(
          isHovered: _isHovered,
          child: AppAnimations.cardPressAnimation(
            isPressed: _isPressed,
            child: GlassContainer(
              blurStrength: BlurStrength.medium,
              gradient: AppGradients.primaryGradient,
              borderGradient: AppGradients.glassBorderGradient(isDark),
              animatedBlur: true,
              child: YourContent(),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Color Compatibility

### Text Colors on Gradients

**Expense Gradient** → `Colors.white` or `AppColors.textPrimaryDark`

**Income Gradient** → `Colors.white` or `AppColors.textPrimaryDark`

**Primary Gradient** → `Colors.white` (guaranteed WCAG AAA)

**Success Gradient** → `Colors.white` or `AppColors.textPrimaryDark`

**Error Gradient** → `Colors.white` or `AppColors.textPrimaryDark`

**Warning Gradient** → `AppColors.textPrimaryLight` (light mode) or `Colors.white` (dark mode)

---

## Performance Tips

1. **Use const gradients** when possible
   ```dart
   const gradient = AppGradients.primaryGradient; // ✅ Good
   ```

2. **Dispose controllers**
   ```dart
   @override
   void dispose() {
     _controller.dispose();
     super.dispose();
   }
   ```

3. **Limit blur on low-end devices**
   ```dart
   blurStrength: isLowEndDevice ? BlurStrength.subtle : BlurStrength.strong
   ```

4. **Cache gradient instances**
   ```dart
   late final _expenseGradient = AppGradients.expenseGradient(isDark);
   ```

5. **Use RepaintBoundary for complex animations**
   ```dart
   RepaintBoundary(
     child: AnimatedWidget(),
   )
   ```

---

## Accessibility

### Reduce Motion
```dart
final reduceMotion = MediaQuery.of(context).disableAnimations;
final duration = reduceMotion ? Duration.zero : AppAnimations.normal;
```

### High Contrast
All gradients maintain WCAG AA compliance. For AAA:
```dart
final useHighContrast = MediaQuery.of(context).highContrast;
final textColor = useHighContrast ? Colors.white : AppColors.textPrimaryDark;
```

---

## Testing

### Unit Test Gradient Creation
```dart
test('expense gradient creates correct colors', () {
  final gradient = AppGradients.expenseGradient(false);
  expect(gradient.colors.length, 3);
  expect(gradient.colors[0], isA<Color>());
});
```

### Widget Test Glass Container
```dart
testWidgets('GlassContainer renders correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GlassContainer(child: Text('Test')),
    ),
  );
  expect(find.text('Test'), findsOneWidget);
});
```

### Animation Test
```dart
testWidgets('card press animation scales correctly', (tester) async {
  bool isPressed = false;
  await tester.pumpWidget(
    MaterialApp(
      home: AppAnimations.cardPressAnimation(
        isPressed: isPressed,
        child: Container(),
      ),
    ),
  );
  // Test scale transformation
});
```
