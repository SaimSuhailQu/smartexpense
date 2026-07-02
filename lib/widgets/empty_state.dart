import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';

/// Reusable empty state widget for various empty scenarios
///
/// Design Philosophy:
/// - Clear visual hierarchy with icon, title, and description
/// - Optional call-to-action button for actionable states
/// - Consistent spacing and typography
/// - Themed for both light and dark modes
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    this.iconColor,
  });

  /// Factory: No expenses empty state
  factory EmptyState.noExpenses({
    VoidCallback? onAddExpense,
  }) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Expenses Yet',
      description: 'Start tracking your expenses by adding your first transaction.',
      actionLabel: onAddExpense != null ? 'Add Expense' : null,
      onActionPressed: onAddExpense,
      iconColor: AppColors.expenseNormal,
    );
  }

  /// Factory: No income empty state
  factory EmptyState.noIncome({
    VoidCallback? onAddIncome,
  }) {
    return EmptyState(
      icon: Icons.trending_up_outlined,
      title: 'No Income Recorded',
      description: 'Track your income sources to get a complete financial picture.',
      actionLabel: onAddIncome != null ? 'Add Income' : null,
      onActionPressed: onAddIncome,
      iconColor: AppColors.incomePositive,
    );
  }

  /// Factory: No budgets empty state
  factory EmptyState.noBudgets({
    VoidCallback? onAddBudget,
  }) {
    return EmptyState(
      icon: Icons.account_balance_wallet_outlined,
      title: 'No Budgets Set',
      description: 'Create budgets to manage your spending and stay on track.',
      actionLabel: onAddBudget != null ? 'Create Budget' : null,
      onActionPressed: onAddBudget,
      iconColor: AppColors.primary,
    );
  }

  /// Factory: No loans empty state
  factory EmptyState.noLoans({
    VoidCallback? onAddLoan,
  }) {
    return EmptyState(
      icon: Icons.credit_card_outlined,
      title: 'No Loans Tracked',
      description: 'Keep track of your loans and payment schedules in one place.',
      actionLabel: onAddLoan != null ? 'Add Loan' : null,
      onActionPressed: onAddLoan,
      iconColor: AppColors.warning,
    );
  }

  /// Factory: No transactions in period
  factory EmptyState.noTransactions({
    String? period,
  }) {
    return EmptyState(
      icon: Icons.calendar_today_outlined,
      title: 'No Transactions Found',
      description: period != null
          ? 'No transactions found for $period.'
          : 'No transactions match your current filters.',
      iconColor: AppColors.neutralGray,
    );
  }

  /// Factory: Search results empty state
  factory EmptyState.noSearchResults({
    String? query,
  }) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No Results Found',
      description: query != null
          ? 'No results found for "$query". Try adjusting your search.'
          : 'No results found. Try a different search term.',
      iconColor: AppColors.neutralGray,
    );
  }

  /// Factory: Filtered results empty state
  factory EmptyState.noFilteredResults({
    VoidCallback? onClearFilters,
  }) {
    return EmptyState(
      icon: Icons.filter_alt_off_outlined,
      title: 'No Matching Results',
      description: 'No items match your current filters. Try adjusting them.',
      actionLabel: onClearFilters != null ? 'Clear Filters' : null,
      onActionPressed: onClearFilters,
      iconColor: AppColors.neutralGray,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.pageMarginHorizontal * 2,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container with background
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: effectiveIconColor,
              ),
            ),

            AppSpacing.verticalSpaceXXL,

            // Title
            Text(
              title,
              style: AppTypography.headingMedium(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),

            AppSpacing.verticalSpaceMD,

            // Description
            Text(
              description,
              style: AppTypography.bodyMedium(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),

            // Optional action button
            if (actionLabel != null && onActionPressed != null) ...[
              AppSpacing.verticalSpaceXXL,
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveIconColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
