import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/theme/app_colors.dart';

class FinancialRadialShield extends StatefulWidget {
  final double totalIncome;
  final double totalExpenses;
  final double totalBudget;

  const FinancialRadialShield({
    super.key,
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalBudget,
  });

  @override
  State<FinancialRadialShield> createState() => _FinancialRadialShieldState();
}

class _FinancialRadialShieldState extends State<FinancialRadialShield>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant FinancialRadialShield oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalIncome != widget.totalIncome ||
        oldWidget.totalExpenses != widget.totalExpenses ||
        oldWidget.totalBudget != widget.totalBudget) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context);

    final netSavings = widget.totalIncome - widget.totalExpenses;
    final savingsRate = widget.totalIncome > 0
        ? (netSavings / widget.totalIncome * 100).clamp(0.0, 100.0)
        : 0.0;

    final formattedNet = currencyService.formatAmountWithDecimal(netSavings);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: isDark ? const Color(0xFF0C0D16) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(15) : Colors.black.withAlpha(10),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(100)
                    : Colors.black.withAlpha(15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Financial Command Center',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 200,
                width: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _RadialShieldPainter(
                        income: widget.totalIncome,
                        expenses: widget.totalExpenses,
                        budget: widget.totalBudget,
                        progress: _animation.value,
                        isDark: isDark,
                      ),
                    ),
                    // Centered Metrics
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NET BALANCE',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              formattedNet,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: netSavings >= 0
                                    ? AppColors.success
                                    : AppColors.error,
                                shadows: [
                                  Shadow(
                                    color: (netSavings >= 0 ? AppColors.success : AppColors.error).withAlpha(60),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(60),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${savingsRate.toStringAsFixed(0)}% Saved',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Legend row with dynamic percentages
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(
                    'Income Flow',
                    widget.totalIncome > 0 ? '100%' : '0%',
                    AppColors.success,
                    isDark,
                  ),
                  _buildLegendItem(
                    'Expenses',
                    widget.totalIncome > 0
                        ? '${(widget.totalExpenses / widget.totalIncome * 100).clamp(0, 100).toStringAsFixed(0)}%'
                        : '0%',
                    AppColors.error,
                    isDark,
                  ),
                  _buildLegendItem(
                    'Budget Limit',
                    widget.totalBudget > 0
                        ? '${(widget.totalExpenses / widget.totalBudget * 100).clamp(0, 999).toStringAsFixed(0)}%'
                        : '0%',
                    AppColors.primary,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(120),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _RadialShieldPainter extends CustomPainter {
  final double income;
  final double expenses;
  final double budget;
  final double progress;
  final bool isDark;

  _RadialShieldPainter({
    required this.income,
    required this.expenses,
    required this.budget,
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2;

    // Stroke styles
    const double outerRingWidth = 10.0;
    const double innerRingWidth = 8.0;
    final double outerRadius = maxRadius - outerRingWidth / 2 - 4;
    final double innerRadius = outerRadius - outerRingWidth - 12;

    // --- 1. Draw Background Track Rings ---
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8)
      ..strokeWidth = outerRingWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, outerRadius, trackPaint);

    final innerTrackPaint = Paint()
      ..color = isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)
      ..strokeWidth = innerRingWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, innerRadius, innerTrackPaint);

    // --- 2. Calculate Sweep Angles ---
    final double expenseRatio = income > 0 ? (expenses / income).clamp(0.0, 1.0) : 0.0;
    final double budgetRatio = budget > 0 ? (expenses / budget).clamp(0.0, 1.0) : 0.0;

    final double outerSweepAngle = 2 * math.pi * expenseRatio * progress;
    final double innerSweepAngle = 2 * math.pi * budgetRatio * progress;

    // --- 3. Draw Outer Ring (Expense Ratio Flow) ---
    if (outerSweepAngle > 0) {
      final outerGradient = ui.Gradient.sweep(
        center,
        [
          AppColors.success.withAlpha(120),
          AppColors.error,
          AppColors.error.withAlpha(120),
          AppColors.success.withAlpha(120),
        ],
        [0.0, 0.45, 0.9, 1.0],
        TileMode.clamp,
        -math.pi / 2,
        math.pi * 3 / 2,
      );

      final outerPaint = Paint()
        ..shader = outerGradient
        ..strokeWidth = outerRingWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Rotate canvas or adjust starting angle to -90 degrees (top center)
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        outerSweepAngle,
        false,
        outerPaint,
      );

      // Add soft neon outer glow
      final outerGlowPaint = Paint()
        ..shader = outerGradient
        ..strokeWidth = outerRingWidth + 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        -math.pi / 2,
        outerSweepAngle,
        false,
        outerGlowPaint,
      );
    }

    // --- 4. Draw Inner Ring (Budget Limit Progress) ---
    if (innerSweepAngle > 0) {
      final innerGradient = ui.Gradient.sweep(
        center,
        [
          AppColors.primary.withAlpha(120),
          AppColors.secondary,
          AppColors.secondary.withAlpha(120),
          AppColors.primary.withAlpha(120),
        ],
        [0.0, 0.5, 0.9, 1.0],
        TileMode.clamp,
        -math.pi / 2,
        math.pi * 3 / 2,
      );

      final innerPaint = Paint()
        ..shader = innerGradient
        ..strokeWidth = innerRingWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -math.pi / 2,
        innerSweepAngle,
        false,
        innerPaint,
      );

      // Soft glow for inner ring
      final innerGlowPaint = Paint()
        ..shader = innerGradient
        ..strokeWidth = innerRingWidth + 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..imageFilter = ui.ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        -math.pi / 2,
        innerSweepAngle,
        false,
        innerGlowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialShieldPainter oldDelegate) {
    return oldDelegate.income != income ||
        oldDelegate.expenses != expenses ||
        oldDelegate.budget != budget ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark;
  }
}
