import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' show FontFeature;
import '../models/expense.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import 'glass_container.dart';

/// Enhanced expense card with semantic colors and tabular figures
///
/// Improvements:
/// - Semantic expense colors (WCAG AA compliant)
/// - Tabular figures for aligned amount display
/// - Improved spacing and visual hierarchy
/// - Better contrast ratios for accessibility
class ExpenseCard extends StatelessWidget {
  final Expense expense;
  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final formattedAmount = currencyService.formatAmount(expense.amount);

    // Use semantic expense color
    final expenseColor = AppColors.expenseNormal;

    return GlassContainer(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageMarginHorizontal,
        vertical: AppSpacing.cardGap / 2,
      ),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
      color: isDark
          ? AppColors.surfaceDark.withOpacity(0.6)
          : AppColors.surfaceLight.withOpacity(0.9),
      borderColor: expenseColor.withOpacity(isDark ? 0.12 : 0.06),
      shadows: AppColors.getShadow(theme.brightness, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leading accent bar with expense color
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      expenseColor,
                      expenseColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Card content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.iconPadding),
                        decoration: BoxDecoration(
                          color: expenseColor.withOpacity(isDark ? 0.15 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(expense.category),
                          color: expenseColor,
                          size: 22,
                        ),
                      ),

                      AppSpacing.horizontalSpaceLG,

                      // Title and metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Expense title
                            Text(
                              expense.title,
                              style: AppTypography.headingSmall(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                            AppSpacing.verticalSpaceXS,

                            // Category and date
                            Text(
                              '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                              style: AppTypography.labelMedium(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      AppSpacing.horizontalSpaceMD,

                      // Amount with tabular figures
                      Text(
                        '- $formattedAmount',
                        style: AppTypography.financialMedium(
                          color: expenseColor,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns appropriate icon for expense category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'travel':
        return Icons.directions_car_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'health':
        return Icons.medical_services_outlined;
      case 'bills':
      case 'utilities':
        return Icons.receipt_long_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'groceries':
        return Icons.local_grocery_store_outlined;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'insurance':
        return Icons.security_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}
