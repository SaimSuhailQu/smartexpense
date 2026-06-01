import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/widgets/glass_container.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/theme/app_colors.dart';

class BudgetProgressCard extends StatelessWidget {
  final Budget budget;

  const BudgetProgressCard({super.key, required this.budget});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      padding: const EdgeInsets.all(20.0),
      borderRadius: BorderRadius.circular(24),
      color: isDark ? AppColors.surfaceDark.withAlpha(100) : Colors.white.withAlpha(160),
      borderColor: AppColors.primary.withAlpha(isDark ? 30 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  budget.category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                currencyService.formatAmount(budget.amount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<Expense>>(
            stream: Provider.of<ExpenseService>(context)
                .getExpensesBetweenDates(budget.startDate, budget.endDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final expenses = snapshot.data ?? [];
              final spentAmount = expenses
                  .where((expense) => expense.category == budget.category)
                  .fold(0.0, (sum, item) => sum + item.amount);
              final progress = (spentAmount / budget.amount).clamp(0.0, 1.0);
              final isOverBudget = spentAmount > budget.amount;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isOverBudget 
                                ? [Colors.redAccent, Colors.red] 
                                : [AppColors.secondary, AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: (isOverBudget ? Colors.red : AppColors.primary).withAlpha(50),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoColumn(
                        context,
                        'Spent',
                        currencyService.formatAmount(spentAmount),
                        isOverBudget ? Colors.red : AppColors.primary,
                      ),
                      _buildInfoColumn(
                        context,
                        'Remaining',
                        currencyService.formatAmount(budget.amount - spentAmount),
                        isOverBudget ? Colors.grey : AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
