import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';

import 'glass_container.dart';

class IncomeCard extends StatelessWidget {
  final Income income;
  const IncomeCard({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final formattedAmount = currencyService.formatAmount(income.amount);

    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(20),
      color: isDark ? AppColors.surfaceDark.withAlpha(100) : Colors.white.withAlpha(160),
      borderColor: Colors.green.withAlpha(isDark ? 31 : 15),
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
                    colors: [Colors.greenAccent, Colors.tealAccent],
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
                      color: Colors.green.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(income.category),
                      color: Colors.green,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    income.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  subtitle: Text(
                    '${income.category} • ${DateFormat('MMM dd, yyyy').format(income.date)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: Text(
                    '+ $formattedAmount',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
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
      case 'salary':
        return Icons.work_outline;
      case 'freelance':
        return Icons.computer_outlined;
      case 'investment':
        return Icons.trending_up_outlined;
      case 'gift':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.add_chart_outlined;
    }
  }
}
