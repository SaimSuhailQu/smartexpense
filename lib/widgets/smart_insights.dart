import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/theme/app_colors.dart';

class SmartInsights extends StatelessWidget {
  final TimeRange selectedRange;
  final DateTime selectedDate;

  const SmartInsights({
    super.key,
    required this.selectedRange,
    required this.selectedDate,
  });

  String _getRangeTitle() {
    switch (selectedRange) {
      case TimeRange.daily: return 'Daily';
      case TimeRange.weekly: return 'Weekly';
      case TimeRange.monthly: return 'Monthly';
      case TimeRange.yearly: return 'Yearly';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final expenseService = context.watch<ExpenseService>();
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;

    return StreamBuilder<List<Expense>>(
      stream: expenseService.getExpensesStream(selectedRange, selectedDate),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildContainer(
            cardColor,
            isDark,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, isDark),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Add expenses to see insights',
                    style: TextStyle(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),
          );
        }

        final expenses = snapshot.data!;
        final totalExpenses = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
        
        Map<String, double> categoryTotals = {};
        for (var expense in expenses) {
          categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
        }
        
        String topCategory = '';
        double topCategoryAmount = 0;
        categoryTotals.forEach((category, amount) {
          if (amount > topCategoryAmount) {
            topCategory = category;
            topCategoryAmount = amount;
          }
        });
        
        double topCategoryPercentage = totalExpenses > 0 ? (topCategoryAmount / totalExpenses * 100) : 0;
        final incomeService = context.watch<IncomeService>();
        
        return StreamBuilder<List<Income>>(
          stream: incomeService.getIncomesStream(selectedRange, selectedDate),
          builder: (context, incomeSnapshot) {
            final incomes = incomeSnapshot.data ?? [];
            final totalIncome = incomes.fold(0.0, (sum, income) => sum + income.amount);
            
            String budgetStatus;
            Color budgetColor;
            IconData budgetIcon;
            
            if (totalIncome > 0) {
              final spentPercentage = (totalExpenses / totalIncome * 100);
              if (spentPercentage < 80) {
                budgetStatus = "You're on track this ${_getRangeTitle().toLowerCase()}";
                budgetColor = Colors.green;
                budgetIcon = Icons.trending_up;
              } else if (spentPercentage < 100) {
                budgetStatus = "Approaching budget limit (${spentPercentage.toStringAsFixed(0)}% spent)";
                budgetColor = Colors.orange;
                budgetIcon = Icons.warning;
              } else {
                budgetStatus = "Over budget by ${(spentPercentage - 100).toStringAsFixed(0)}%";
                budgetColor = Colors.red;
                budgetIcon = Icons.trending_down;
              }
            } else {
              budgetStatus = "Set up income to track budget";
              budgetColor = AppColors.primary;
              budgetIcon = Icons.info_outline;
            }

            String savingOpportunity = "Track more expenses for insights";
            if (categoryTotals.length >= 3) {
              var sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              if (sortedCategories.length > 1) {
                savingOpportunity = "Consider reducing ${sortedCategories[1].key} expenses";
              }
            }

            return _buildContainer(
              cardColor,
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isDark),
                  const SizedBox(height: 20),
                  _buildInsightTile(
                    context,
                    'Budget Status',
                    budgetStatus,
                    budgetIcon,
                    budgetColor,
                  ),
                  if (topCategory.isNotEmpty)
                    _buildInsightTile(
                      context,
                      'Top Category',
                      '$topCategory (${topCategoryPercentage.toStringAsFixed(0)}% of expenses)',
                      Icons.insights_outlined,
                      Colors.orange,
                    ),
                  _buildInsightTile(
                    context,
                    'Saving Opportunity',
                    savingOpportunity,
                    Icons.savings_outlined,
                    AppColors.secondary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContainer(Color color, bool isDark, Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Smart Insights',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Icon(Icons.chevron_right, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
      ],
    );
  }

  Widget _buildInsightTile(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
