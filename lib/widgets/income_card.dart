import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../theme/typography.dart';
import '../theme/spacing.dart';
import 'glass_container.dart';

/// Enhanced income card with semantic colors and tabular figures
///
/// Improvements:
/// - Semantic income colors (WCAG AA compliant)
/// - Tabular figures for aligned amount display
/// - Improved spacing and visual hierarchy
/// - Better contrast ratios for accessibility
class IncomeCard extends StatelessWidget {
  final Income income;
  const IncomeCard({super.key, required this.income});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final formattedAmount = currencyService.formatAmount(income.amount);

    // Use semantic income color
    final incomeColor = AppColors.incomePositive;

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
      borderColor: incomeColor.withOpacity(isDark ? 0.12 : 0.06),
      shadows: AppColors.getShadow(theme.brightness, 2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Leading accent bar with income color
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      incomeColor,
                      incomeColor.withOpacity(0.7),
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
                          color: incomeColor.withOpacity(isDark ? 0.15 : 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(income.category),
                          color: incomeColor,
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
                            // Income title
                            Text(
                              income.title,
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
                              '${income.category} • ${DateFormat('MMM dd, yyyy').format(income.date)}',
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
                        '+ $formattedAmount',
                        style: AppTypography.financialMedium(
                          color: incomeColor,
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

  /// Returns appropriate icon for income category
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
      case 'business':
        return Icons.business_outlined;
      case 'rental':
        return Icons.home_outlined;
      case 'dividend':
        return Icons.account_balance_outlined;
      case 'interest':
        return Icons.savings_outlined;
      case 'bonus':
        return Icons.star_outline;
      default:
        return Icons.add_chart_outlined;
    }
  }
}
