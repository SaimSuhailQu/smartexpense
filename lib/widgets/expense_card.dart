import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';

import 'glass_container.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final formattedAmount = currencyService.formatAmount(expense.amount);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      color: isDark ? AppColors.surfaceDark.withAlpha(100) : Colors.white.withAlpha(160),
      borderColor: Colors.red.withAlpha(isDark ? 31 : 15),
      shadows: [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 30 : 10),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.redAccent, Colors.orangeAccent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(16, 8, 20, 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    expense.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  subtitle: Text(
                    '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Text(
                    '- $formattedAmount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      default:
        return Icons.payments_outlined;
    }
  }
}
