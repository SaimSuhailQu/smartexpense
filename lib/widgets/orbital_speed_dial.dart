import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartexpense/theme/app_colors.dart';

class OrbitalSpeedDialOverlay extends StatefulWidget {
  final VoidCallback onAddIncome;
  final VoidCallback onAddExpense;
  final VoidCallback onAddLoan;

  const OrbitalSpeedDialOverlay({
    super.key,
    required this.onAddIncome,
    required this.onAddExpense,
    required this.onAddLoan,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onAddIncome,
    required VoidCallback onAddExpense,
    required VoidCallback onAddLoan,
  }) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return OrbitalSpeedDialOverlay(
            onAddIncome: onAddIncome,
            onAddExpense: onAddExpense,
            onAddLoan: onAddLoan,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<OrbitalSpeedDialOverlay> createState() => _OrbitalSpeedDialOverlayState();
}

class _OrbitalSpeedDialOverlayState extends State<OrbitalSpeedDialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Full Screen Frosted Glass Blur Background
          GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.translucent,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return ClipRect(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: 16 * _controller.value,
                      sigmaY: 16 * _controller.value,
                    ),
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: isDark
                          ? Colors.black.withAlpha((130 * _controller.value).toInt())
                          : Colors.white.withAlpha((90 * _controller.value).toInt()),
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Orbital Action Buttons (Income, Expense, Loan) fanning out from bottom center
          _buildOrbitalItem(
            angle: -140, // Top-Left direction
            label: 'Add Income',
            icon: Icons.add_chart_rounded,
            color: AppColors.success,
            onPressed: () {
              _controller.reverse().then((_) {
                Navigator.of(context).pop();
                widget.onAddIncome();
              });
            },
          ),
          _buildOrbitalItem(
            angle: -90, // Direct Up direction
            label: 'Add Expense',
            icon: Icons.analytics_outlined,
            color: AppColors.error,
            onPressed: () {
              _controller.reverse().then((_) {
                Navigator.of(context).pop();
                widget.onAddExpense();
              });
            },
          ),
          _buildOrbitalItem(
            angle: -40, // Top-Right direction
            label: 'Add Loan',
            icon: Icons.account_balance_wallet_rounded,
            color: AppColors.info,
            onPressed: () {
              _controller.reverse().then((_) {
                Navigator.of(context).pop();
                widget.onAddLoan();
              });
            },
          ),

          // 3. Floating Close Trigger aligned with original FAB
          Positioned(
            bottom: 30,
            child: GestureDetector(
              onTap: _close,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final rotation = _controller.value * 0.75 * math.pi; // Rotate 135 degrees to form "x"
                  return Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(120),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitalItem({
    required double angle,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final double rad = angle * math.pi / 180;
    const double radius = 110.0; // Expansion distance

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final double currentRadius = radius * _expandAnimation.value;
        final double x = currentRadius * math.cos(rad);
        final double y = currentRadius * math.sin(rad);

        return Positioned(
          // Pivot around the FAB center: y offset of FAB is bottom: 30 + 30px half-height = 60px from bottom edge
          bottom: 60 - y - 40, 
          left: (MediaQuery.of(context).size.width / 2) + x - 40,
          child: Opacity(
            opacity: _expandAnimation.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: _expandAnimation.value,
              child: SizedBox(
                width: 80,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onPressed,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withAlpha(35),
                          border: Border.all(
                            color: color.withAlpha(140),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withAlpha(50),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withAlpha(25),
                          width: 0.5,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
