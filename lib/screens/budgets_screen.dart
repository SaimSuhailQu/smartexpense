import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/services/budget_service.dart';
import 'package:smartexpense/screens/add_budget_screen.dart';
import 'package:smartexpense/widgets/empty_state.dart';
import 'package:smartexpense/widgets/shimmer_loading.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/theme/typography.dart';
import 'package:smartexpense/theme/spacing.dart';
import 'package:intl/intl.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
        stream: context.watch<BudgetService>().getBudgetsStream(),
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
              // Calculate budget usage percentage (mock - you may need actual spent amount)
              final percentage = 0.5; // Replace with actual calculation from budget service
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
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.06),
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
                                        color: budgetColor.withOpacity(isDark ? 0.15 : 0.1),
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
                                NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(budget.amount),
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

                          // Progress indicator (if you have spent amount tracking)
                          // Uncomment and implement when spent tracking is available
                          /*
                          LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: isDark
                                ? AppColors.surfaceDark2
                                : AppColors.surfaceLight2,
                            valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                          ),

                          AppSpacing.verticalSpaceMD,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: ${NumberFormat.currency(locale: 'en_IN', symbol: '₹').format(budget.amount * percentage)}',
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
                          */
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
