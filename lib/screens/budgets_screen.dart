import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/budget_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/screens/add_budget_screen.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/widgets/empty_state.dart';
import 'package:smartexpense/widgets/shimmer_loading.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/theme/typography.dart';
import 'package:smartexpense/theme/spacing.dart';
import 'package:intl/intl.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  late final Stream<List<Budget>> _budgetsStream;
  StreamSubscription<List<Expense>>? _expensesSub;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    final budgetService = context.read<BudgetService>();
    final expenseService = context.read<ExpenseService>();
    // Hoisted so rebuilds don't resubscribe (new stream instance per build
    // would restart the Firestore subscription every setState).
    _budgetsStream = budgetService.getBudgetsStream();
    // All expenses, filtered client-side per budget. A server-side
    // where(category) + orderBy(date) would need a composite index and
    // whereIn caps at 10 categories; client-side filtering avoids both.
    _expensesSub = expenseService
        .getExpensesStream(TimeRange.custom, DateTime.now(), filters: {
      'startDate': DateTime(2000),
      'endDate': DateTime(2100),
    }).listen((expenses) {
      if (mounted) setState(() => _expenses = expenses);
    });
  }

  @override
  void dispose() {
    _expensesSub?.cancel();
    super.dispose();
  }

  /// Real spend for a budget: expenses in its category inside its date range.
  double _spentFor(Budget budget) {
    return _expenses
        .where((e) =>
            e.category == budget.category &&
            !e.date.isBefore(budget.startDate) &&
            !e.date.isAfter(budget.endDate))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = context.watch<CurrencyService>();

    return Scaffold(
      // Background color using theme-aware surface color
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        // App bar title using heading typography
        title: Text(
          'Budgets',
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
      body: StreamBuilder<List<Budget>>(
        stream: _budgetsStream,
        builder: (context, snapshot) {
          // Loading state with shimmer effect
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.pageMarginHorizontal,
                vertical: AppSpacing.listItemGap,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.cardGap),
                child: ShimmerLoading.budgetCard(isDark: isDark),
              ),
            );
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
                      'Error Loading Budgets',
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

          final budgets = snapshot.data ?? [];

          // Empty state with call-to-action
          if (budgets.isEmpty) {
            return EmptyState.noBudgets(
              onAddBudget: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
                );
              },
            );
          }

          // Budget list with enhanced styling
          return ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.pageMarginHorizontal,
              vertical: AppSpacing.listItemGap,
            ),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              // Real usage: spent in this budget's category and date range.
              final spent = _spentFor(budget);
              final percentage =
                  budget.amount > 0 ? spent / budget.amount : 0.0;
              final budgetColor = AppColors.getBudgetStatusColor(percentage);

              return Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.cardGap),
                child: Card(
                  elevation: 0,
                  // Using theme-aware surface color with elevation
                  color: AppColors.getSurfaceColor(theme.brightness, 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                    // Subtle border for depth perception
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddBudgetScreen(budget: budget),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with category and amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Category with icon
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: budgetColor.withValues(alpha: isDark ? 0.15 : 0.1),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        size: 20,
                                        color: budgetColor,
                                      ),
                                    ),
                                    AppSpacing.horizontalSpaceMD,
                                    Expanded(
                                      child: Text(
                                        budget.category,
                                        style: AppTypography.headingSmall(
                                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppSpacing.horizontalSpaceMD,
                              // Budget amount
                              Text(
                                currencyService.formatAmount(budget.amount),
                                style: AppTypography.financialMedium(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),

                          AppSpacing.verticalSpaceLG,

                          // Date range
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                              AppSpacing.horizontalSpaceXS,
                              Text(
                                '${DateFormat.yMd().format(budget.startDate)} - ${DateFormat.yMd().format(budget.endDate)}',
                                style: AppTypography.labelMedium(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),

                          AppSpacing.verticalSpaceMD,

                          // Progress indicator with real spent tracking
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                            child: LinearProgressIndicator(
                              value: percentage.clamp(0.0, 1.0),
                              backgroundColor: isDark
                                  ? AppColors.surfaceDark2
                                  : AppColors.surfaceLight2,
                              valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                              minHeight: 8,
                            ),
                          ),

                          AppSpacing.verticalSpaceMD,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: ${currencyService.formatAmount(spent)}',
                                style: AppTypography.labelMedium(
                                  color: budgetColor,
                                ),
                              ),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: AppTypography.labelMedium(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
