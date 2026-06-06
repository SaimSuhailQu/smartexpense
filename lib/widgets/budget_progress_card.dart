import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' show FontFeature;
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/widgets/glass_container.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/theme/typography.dart';
import 'package:smartexpense/theme/spacing.dart';

/// Enhanced budget progress card with semantic color progression
///
/// Improvements:
/// - Semantic color progression (safe → warning → critical → overspent)
/// - Tabular figures for all financial amounts
/// - Improved spacing and visual hierarchy
/// - WCAG AA compliant colors
/// - Better progress indicator design
class BudgetProgressCard extends StatelessWidget {
  final Budget budget;

  const BudgetProgressCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context);

    return GlassContainer(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.pageMarginHorizontal,
        vertical: AppSpacing.cardGap / 2,
      ),
      padding: EdgeInsets.all(AppSpacing.cardPadding),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
      color: isDark
          ? AppColors.surfaceDark.withOpacity(0.6)
          : AppColors.surfaceLight.withOpacity(0.9),
      borderColor: AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
      shadows: AppColors.getShadow(theme.brightness, 2),
      child: StreamBuilder<List<Expense>>(
        stream: Provider.of<ExpenseService>(context)
            .getExpensesBetweenDates(budget.startDate, budget.endDate),
        builder: (context, snapshot) {
          // Calculate spent amount
          final expenses = snapshot.data ?? [];
          final spentAmount = expenses
              .where((expense) => expense.category == budget.category)
              .fold(0.0, (sum, item) => sum + item.amount);

          // Calculate progress and determine status
          final progress = (spentAmount / budget.amount).clamp(0.0, 1.0);
          final percentage = progress * 100;
          final isOverBudget = spentAmount > budget.amount;
          final remaining = budget.amount - spentAmount;

          // Get semantic color based on budget status
          final statusColor = AppColors.getBudgetStatusColor(progress);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category and Budget Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                    ),
                    child: Text(
                      budget.category,
                      style: AppTypography.labelLarge(
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  // Budget amount with tabular figures
                  Text(
                    currencyService.formatAmount(budget.amount),
                    style: AppTypography.financialMedium(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalSpaceXL,

              // Progress bar with semantic colors
              Stack(
                children: [
                  // Background track
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark2
                          : AppColors.surfaceLight2,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  // Progress indicator with gradient
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOverBudget
                              ? [AppColors.budgetOverspent, AppColors.budgetCritical]
                              : progress >= 0.90
                                  ? [AppColors.budgetCritical, AppColors.budgetWarning]
                                  : progress >= 0.70
                                      ? [AppColors.budgetWarning, AppColors.budgetSafe]
                                      : [AppColors.budgetSafe, AppColors.incomePositive],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              AppSpacing.verticalSpaceMD,

              // Progress percentage indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}% spent',
                    style: AppTypography.labelMedium(
                      color: statusColor,
                    ),
                  ),
                  if (isOverBudget)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.budgetOverspent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: AppColors.budgetOverspent,
                          ),
                          AppSpacing.horizontalSpaceXS,
                          Text(
                            'Over budget',
                            style: AppTypography.labelSmall(
                              color: AppColors.budgetOverspent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              AppSpacing.verticalSpaceLG,

              // Financial summary: Spent and Remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinancialColumn(
                    context: context,
                    label: 'Spent',
                    amount: currencyService.formatAmount(spentAmount),
                    color: statusColor,
                    isDark: isDark,
                  ),
                  _buildFinancialColumn(
                    context: context,
                    label: isOverBudget ? 'Over by' : 'Remaining',
                    amount: currencyService.formatAmount(remaining.abs()),
                    color: isOverBudget
                        ? AppColors.budgetOverspent
                        : AppColors.incomePositive,
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a financial information column with label and amount
  Widget _buildFinancialColumn({
    required BuildContext context,
    required String label,
    required String amount,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: AppTypography.labelSmall(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),

        AppSpacing.verticalSpaceXS,

        // Amount with tabular figures
        Text(
          amount,
          style: AppTypography.financialSmall(
            color: color,
          ),
        ),
      ],
    );
  }
}
