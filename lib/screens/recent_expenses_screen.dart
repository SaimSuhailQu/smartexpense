import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/widgets/expense_card.dart';
import 'package:smartexpense/widgets/empty_state.dart';
import 'package:smartexpense/widgets/shimmer_loading.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/theme/typography.dart';
import 'package:smartexpense/theme/spacing.dart';

class RecentExpensesScreen extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeRange? selectedRange;

  const RecentExpensesScreen({
    super.key,
    this.selectedDate,
    this.selectedRange,
  });

  String _getTitle(TimeRange range, DateTime date) {
    switch (range) {
      case TimeRange.daily:
        return 'Expenses: ${DateFormat.yMMMd().format(date)}';
      case TimeRange.weekly:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return 'Expenses: ${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}';
      case TimeRange.monthly:
        return 'Expenses: ${DateFormat.yMMM().format(date)}';
      case TimeRange.yearly:
        return 'Expenses: ${DateFormat.y().format(date)}';
      default:
        return 'Recent Expenses';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = selectedDate ?? DateTime.now();
    final range = selectedRange ?? TimeRange.monthly;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background color using theme-aware surface color
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        // App bar title using heading typography
        title: Text(
          _getTitle(range, date),
          style: AppTypography.headingMedium(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        // Icon theme for back button
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseService>().getExpensesStream(range, date),
        builder: (context, snapshot) {
          // Loading state with shimmer effect
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ShimmerLoading.list(isDark: isDark, itemCount: 6);
          }

          // Error state with descriptive message
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: AppSpacing.pageMarginInsets,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    AppSpacing.verticalSpaceXXL,
                    Text(
                      'Error Loading Expenses',
                      style: AppTypography.headingMedium(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.verticalSpaceMD,
                    Text(
                      '${snapshot.error}',
                      style: AppTypography.bodyMedium(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final expenses = snapshot.data ?? [];

          // Empty state with call-to-action
          if (expenses.isEmpty) {
            String? period;
            if (range == TimeRange.monthly) {
              period = 'this month';
            } else if (range == TimeRange.yearly) {
              period = 'this year';
            } else if (range == TimeRange.daily) {
              period = 'this day';
            } else if (range == TimeRange.weekly) {
              period = 'this week';
            }
            return EmptyState.noTransactions(period: period);
          }

          // Expense list with theme-aware styling
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageMarginHorizontal,
              vertical: AppSpacing.listItemGap,
            ),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.listItemGap),
                child: Slidable(
                  key: ValueKey(expense.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          context.read<ExpenseService>().deleteExpense(expense.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${expense.title} deleted.',
                                style: AppTypography.bodyMedium(color: Colors.white),
                              ),
                              // Using semantic expense color for delete action
                              backgroundColor: AppColors.expenseNormal,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                              ),
                            ),
                          );
                        },
                        // Expense color for delete action (semantic consistency)
                        backgroundColor: AppColors.expenseNormal,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                      ),
                    ],
                  ),
                  child: ExpenseCard(expense: expense),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
