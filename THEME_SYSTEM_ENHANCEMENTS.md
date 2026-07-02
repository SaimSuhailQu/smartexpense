# Smart Expense Theme System Enhancements

This document provides comprehensive documentation for the three major enhancements to the Smart Expense Application theme system.

## Table of Contents

1. [Gradient System](#gradient-system)
2. [Enhanced Glass Morphism](#enhanced-glass-morphism)
3. [Animation System](#animation-system)
4. [Usage Examples](#usage-examples)
5. [Migration Guide](#migration-guide)

---

## Gradient System

**File:** `lib/theme/gradients.dart`

The gradient system provides a comprehensive collection of pre-defined, WCAG AA compliant gradients for various use cases throughout the application.

### Features

- **Financial Gradients**: Expense, income, and budget-aware gradients
- **Background Gradients**: Subtle depth for screens and cards
- **Accent Gradients**: Primary, secondary, success, error, warning, info
- **Glass Morphism Gradients**: For enhanced glass effects
- **Shimmer Gradients**: For loading states
- **Helper Methods**: Create custom gradients easily

### Key Components

#### Financial Gradients

```dart
// Expense gradient - Red spectrum for outgoing money
final expenseGrad = AppGradients.expenseGradient(isDark);

// Income gradient - Green spectrum for incoming money
final incomeGrad = AppGradients.incomeGradient(isDark);

// Budget gradient - Dynamic based on spending percentage
final budgetGrad = AppGradients.budgetGradient(0.85, isDark); // 85% spent
```

**Budget Gradient Behavior:**
- 0-70%: Green (safe)
- 70-90%: Amber (warning)
- 90-100%: Orange-red (critical)
- >100%: Deep red (overspent)

#### Background Gradients

```dart
// Main background gradient for app screens
final bgGrad = AppGradients.backgroundGradient(isDark);

// Radial gradient for card backgrounds
final cardBgGrad = AppGradients.cardBackgroundGradient(isDark);
```

#### Accent Gradients

```dart
// Primary brand gradient (const - no theme required)
Container(
  decoration: BoxDecoration(
    gradient: AppGradients.primaryGradient,
  ),
);

// Other accent gradients
AppGradients.secondaryGradient
AppGradients.successGradient
AppGradients.errorGradient
AppGradients.warningGradient
AppGradients.infoGradient
```

#### Glass Morphism Gradients

```dart
// Glass overlay gradient
final glassGrad = AppGradients.glassGradient(isDark);

// Glass border gradient
final glassBorderGrad = AppGradients.glassBorderGradient(isDark);
```

#### Shimmer Gradient

```dart
// For loading skeleton screens
AnimatedBuilder(
  animation: _shimmerController,
  builder: (context, child) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.shimmerGradient(isDark),
      ),
    );
  },
)
```

#### Helper Methods

```dart
// Create custom linear gradient
final customGrad = AppGradients.createLinearGradient(
  colors: [Colors.blue, Colors.purple, Colors.pink],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.5, 1.0],
);

// Create custom radial gradient
final radialGrad = AppGradients.createRadialGradient(
  colors: [Colors.white, Colors.blue],
  center: Alignment.topLeft,
  radius: 1.5,
);

// Create sweep gradient (circular)
final sweepGrad = AppGradients.createSweepGradient(
  colors: [Colors.red, Colors.yellow, Colors.green, Colors.blue],
);

// Apply opacity to gradient
final transparentGrad = AppGradients.withOpacity(
  AppGradients.primaryGradient,
  0.5,
);

// Blend two gradients
final blended = AppGradients.blendGradients(
  AppGradients.primaryGradient,
  AppGradients.secondaryGradient,
  0.5, // 50% blend
);
```

#### Preset Combinations

```dart
// Rainbow gradient for special occasions
AppGradients.rainbowGradient

// Sunset gradient - warm and inviting
AppGradients.sunsetGradient

// Ocean gradient - cool and calming
AppGradients.oceanGradient
```

### WCAG AA Compliance

All gradients are designed to maintain WCAG AA contrast ratios (4.5:1 for normal text, 3:1 for large text) when used with appropriate text colors from the AppColors system.

---

## Enhanced Glass Morphism

**File:** `lib/widgets/glass_container.dart`

The enhanced GlassContainer widget provides advanced glass morphism effects with multiple customization options.

### Features

- **Adjustable Blur Strength**: Subtle, medium, strong presets
- **Gradient Overlay Support**: Custom gradient backgrounds
- **Gradient Border Support**: Gradient-based borders
- **Animated Blur Transitions**: Smooth hover effects
- **Multiple Elevation Levels**: 1-4 for depth perception
- **Noise Texture Overlay**: Optional grain for realism
- **WCAG AA Compliant**: Works in both light and dark modes

### Basic Usage

```dart
GlassContainer(
  child: Text('Glassmorphism'),
)
```

### Advanced Usage

```dart
GlassContainer(
  // Blur strength preset
  blurStrength: BlurStrength.medium, // subtle, medium, or strong

  // Or custom blur values
  blurX: 24.0,
  blurY: 24.0,

  // Gradient overlay
  gradient: AppGradients.primaryGradient,

  // Gradient border
  borderGradient: AppGradients.glassBorderGradient(isDark),

  // Animated blur on hover
  animatedBlur: true,
  animationDuration: Duration(milliseconds: 300),

  // Noise texture overlay
  noiseOverlay: true,
  noiseOpacity: 0.03,

  // Elevation (1-4)
  elevation: 3,

  // Standard properties
  padding: EdgeInsets.all(24.0),
  margin: EdgeInsets.all(16.0),
  borderRadius: BorderRadius.circular(24.0),
  borderWidth: 1.0,

  child: YourWidget(),
)
```

### Blur Strength Presets

```dart
enum BlurStrength {
  subtle,  // 8.0 - minimal glass effect
  medium,  // 16.0 - balanced glass effect (default)
  strong,  // 32.0 - intense glass effect
}
```

### Specialized Variants

#### Subtle Glass Container

```dart
SubtleGlassContainer(
  padding: EdgeInsets.all(16.0),
  child: YourWidget(),
)
```

#### Strong Glass Container

```dart
StrongGlassContainer(
  padding: EdgeInsets.all(24.0),
  animatedBlur: true,
  child: YourWidget(),
)
```

#### Gradient Glass Container

```dart
GradientGlassContainer(
  gradient: AppGradients.primaryGradient,
  blurStrength: BlurStrength.medium,
  child: YourWidget(),
)
```

### Gradient Border Effect

The gradient border creates a beautiful shimmer effect on the container edges:

```dart
GlassContainer(
  borderGradient: AppGradients.glassBorderGradient(isDark),
  borderWidth: 2.0,
  child: YourWidget(),
)
```

### Animated Blur Example

```dart
class MyCard extends StatefulWidget {
  @override
  _MyCardState createState() => _MyCardState();
}

class _MyCardState extends State<MyCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GlassContainer(
        animatedBlur: true,
        blurStrength: _isHovered
          ? BlurStrength.strong
          : BlurStrength.medium,
        child: YourContent(),
      ),
    );
  }
}
```

---

## Animation System

**File:** `lib/theme/animations.dart`

A centralized animation system providing consistent timing, curves, and transition builders across the application.

### Features

- **Duration Constants**: fast, normal, slow, extraSlow, shimmer
- **Curve Presets**: smooth, sharp, bouncy, emphasized, etc.
- **Transition Builders**: fade, scale, slide, rotation
- **Page Transitions**: Custom route builders
- **Helper Widgets**: Animated visibility, staggered lists, pulse effects
- **60fps Performance**: Optimized for smooth animations

### Duration Constants

```dart
AppAnimations.fast       // 200ms - button states, icons
AppAnimations.normal     // 300ms - standard transitions
AppAnimations.slow       // 500ms - page transitions, theme switches
AppAnimations.extraSlow  // 800ms - dramatic reveals
AppAnimations.shimmer    // 1500ms - loading skeleton screens
```

### Curve Presets

```dart
AppAnimations.smooth         // easeInOutCubic - general purpose
AppAnimations.sharp          // easeInOutQuint - snappy, responsive
AppAnimations.bouncy         // elasticOut - playful interactions
AppAnimations.gentleBounce   // easeOutBack - subtle emphasis
AppAnimations.spring         // easeOutCubic - natural motion
AppAnimations.emphasized     // Material Design 3 standard
AppAnimations.decelerate     // easeOut - entering animations
AppAnimations.accelerate     // easeIn - exiting animations
```

### Transition Builders

#### Fade Transition

```dart
AnimatedSwitcher(
  duration: AppAnimations.normal,
  transitionBuilder: AppAnimations.fadeTransition,
  child: widget,
)
```

#### Scale Transition

```dart
AnimatedSwitcher(
  duration: AppAnimations.normal,
  transitionBuilder: (child, animation) {
    return AppAnimations.scaleTransition(
      child,
      animation,
      alignment: Alignment.center,
    );
  },
  child: widget,
)
```

#### Slide Transition

```dart
AnimatedSwitcher(
  duration: AppAnimations.normal,
  transitionBuilder: (child, animation) {
    return AppAnimations.slideTransition(
      child,
      animation,
      AxisDirection.up, // up, down, left, right
    );
  },
  child: widget,
)
```

#### Combined Transitions

```dart
// Fade + Scale
AppAnimations.fadeScaleTransition(child, animation)

// Fade + Slide
AppAnimations.fadeSlideTransition(child, animation, AxisDirection.up)
```

### Theme Switch Animation

```dart
class _MyWidgetState extends State<MyWidget> with TickerProviderStateMixin {
  late AnimationController _themeController;
  late Animation<double> _themeAnimation;

  @override
  void initState() {
    super.initState();
    _themeController = AppAnimations.createThemeSwitchController(this);
    _themeAnimation = AppAnimations.createThemeTransition(_themeController);
  }

  void toggleTheme() {
    if (_themeController.isCompleted) {
      _themeController.reverse();
    } else {
      _themeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeAnimation,
      builder: (context, child) {
        // Use animation value for theme transitions
        return YourWidget();
      },
    );
  }
}
```

### Card Animations

#### Press Animation

```dart
class _CardState extends State<Card> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AppAnimations.cardPressAnimation(
        isPressed: _isPressed,
        duration: AppAnimations.fast,
        curve: AppAnimations.smooth,
        child: YourCard(),
      ),
    );
  }
}
```

#### Hover Animation

```dart
class _CardState extends State<Card> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AppAnimations.cardHoverAnimation(
        isHovered: _isHovered,
        duration: AppAnimations.fast,
        curve: AppAnimations.smooth,
        child: YourCard(),
      ),
    );
  }
}
```

### Shimmer Animation

```dart
class _LoadingState extends State<Loading> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AppAnimations.createShimmerController(this);
    _shimmerAnimation = AppAnimations.createShimmerAnimation(_shimmerController);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
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

### Page Transitions

#### Fade Page Route

```dart
Navigator.push(
  context,
  AppAnimations.fadePageRoute(
    page: DetailsScreen(),
    duration: AppAnimations.normal,
    curve: AppAnimations.smooth,
  ),
);
```

#### Scale Page Route

```dart
Navigator.push(
  context,
  AppAnimations.scalePageRoute(
    page: DetailsScreen(),
    duration: AppAnimations.normal,
    curve: AppAnimations.emphasized,
  ),
);
```

#### Slide Page Route

```dart
Navigator.push(
  context,
  AppAnimations.slidePageRoute(
    page: DetailsScreen(),
    direction: AxisDirection.left,
    duration: AppAnimations.normal,
  ),
);
```

### Helper Widgets

#### Animated Visibility

```dart
AppAnimations.animatedVisibility(
  visible: _showDetails,
  duration: AppAnimations.normal,
  curve: AppAnimations.smooth,
  child: DetailsWidget(),
)
```

#### Staggered List Items

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return AppAnimations.staggeredListItem(
      index: index,
      duration: AppAnimations.normal,
      staggerDelayMs: 50,
      child: ListTile(title: Text(items[index])),
    );
  },
)
```

#### Pulse Animation

```dart
AppAnimations.pulseAnimation(
  duration: Duration(milliseconds: 1000),
  minScale: 0.95,
  maxScale: 1.05,
  child: Icon(Icons.notifications, size: 32),
)
```

#### Loading Dots

```dart
AppAnimations.loadingDots(
  color: Theme.of(context).primaryColor,
  size: 8.0,
  duration: Duration(milliseconds: 1400),
)
```

#### Animated Number Counter

```dart
AppAnimations.animatedNumber(
  value: 1234.56,
  style: Theme.of(context).textTheme.headlineMedium,
  prefix: '\$',
  suffix: ' USD',
  decimalPlaces: 2,
  duration: AppAnimations.slow,
  curve: AppAnimations.smooth,
)
```

### Extension Methods

#### Animation Controller Extensions

```dart
// Repeat animation with delay
_controller.repeatWithDelay(
  delay: Duration(milliseconds: 500),
  reverse: true,
);
```

#### Animation Extensions

```dart
// Map animation value to custom range
final scaledValue = animation.mapTo(min: 0.8, max: 1.2);
```

---

## Usage Examples

### Example 1: Expense Card with Glass Effect and Gradient

```dart
class ExpenseCard extends StatelessWidget {
  final double amount;
  final String category;
  final bool isDark;

  const ExpenseCard({
    required this.amount,
    required this.category,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blurStrength: BlurStrength.medium,
      gradient: AppGradients.expenseGradient(isDark),
      borderGradient: AppGradients.glassBorderGradient(isDark),
      elevation: 2,
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category, style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          AppAnimations.animatedNumber(
            value: amount,
            prefix: '\$',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
```

### Example 2: Budget Progress with Dynamic Gradient

```dart
class BudgetProgress extends StatelessWidget {
  final double spent;
  final double total;
  final bool isDark;

  const BudgetProgress({
    required this.spent,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = spent / total;

    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: AppGradients.budgetGradient(percentage, isDark),
      ),
      child: FractionallySizedBox(
        widthFactor: percentage.clamp(0.0, 1.0),
        child: Container(),
      ),
    );
  }
}
```

### Example 3: Loading Skeleton with Shimmer

```dart
class LoadingSkeleton extends StatefulWidget {
  @override
  _LoadingSkeletonState createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AppAnimations.createShimmerController(this);
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppGradients.shimmerGradient(isDark),
          ),
        );
      },
    );
  }
}
```

### Example 4: Animated Theme Toggle

```dart
class ThemeToggle extends StatefulWidget {
  @override
  _ThemeToggleState createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _controller = AppAnimations.createThemeSwitchController(this);
    _animation = AppAnimations.createThemeTransition(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDark = !_isDark;
    });

    if (_isDark) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return IconButton(
          icon: Icon(_isDark ? Icons.dark_mode : Icons.light_mode),
          onPressed: _toggleTheme,
        );
      },
    );
  }
}
```

---

## Migration Guide

### From Old GlassContainer to Enhanced Version

**Before:**
```dart
GlassContainer(
  blurX: 16.0,
  blurY: 16.0,
  child: MyWidget(),
)
```

**After (with same behavior):**
```dart
GlassContainer(
  blurStrength: BlurStrength.medium, // or keep blurX/blurY
  child: MyWidget(),
)
```

**After (with enhancements):**
```dart
GlassContainer(
  blurStrength: BlurStrength.medium,
  gradient: AppGradients.primaryGradient,
  borderGradient: AppGradients.glassBorderGradient(isDark),
  animatedBlur: true,
  elevation: 2,
  child: MyWidget(),
)
```

### Adding Gradients to Existing Widgets

**Before:**
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(16),
  ),
  child: ExpenseInfo(),
)
```

**After:**
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppGradients.expenseGradient(isDark),
    borderRadius: BorderRadius.circular(16),
  ),
  child: ExpenseInfo(),
)
```

### Replacing Custom Animations with System

**Before:**
```dart
AnimatedOpacity(
  opacity: _visible ? 1.0 : 0.0,
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  child: MyWidget(),
)
```

**After:**
```dart
AppAnimations.animatedVisibility(
  visible: _visible,
  duration: AppAnimations.normal,
  curve: AppAnimations.smooth,
  child: MyWidget(),
)
```

---

## Performance Considerations

1. **Gradients**: Use const gradients where possible (e.g., `AppGradients.primaryGradient`)
2. **Animations**: Always dispose controllers in `dispose()` method
3. **Blur Effects**: Strong blur may impact performance on low-end devices
4. **Shimmer**: Use `controller.repeat()` instead of rebuilding widgets
5. **Staggered Lists**: Limit stagger delay to maintain smooth scrolling

---

## Accessibility

- All gradients maintain WCAG AA contrast ratios
- Animations respect user's `Reduce Motion` preferences (implement with MediaQuery)
- Glass effects work in both light and dark modes
- Clear visual hierarchy with elevation system

---

## Browser/Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web (with backdrop-filter support)
- ✅ macOS
- ✅ Windows
- ✅ Linux

**Note**: Blur effects may have limited support on older web browsers.

---

## Contributing

When adding new gradients, animations, or glass effects:

1. Ensure WCAG AA compliance
2. Test in both light and dark modes
3. Add comprehensive documentation
4. Include usage examples
5. Test on multiple devices/platforms

---

## License

Part of the Smart Expense Application - All rights reserved.
