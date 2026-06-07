import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/widgets/empty_state.dart';
import 'package:smartexpense/widgets/shimmer_loading.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:smartexpense/theme/typography.dart';
import 'package:smartexpense/theme/spacing.dart';

class RecentIncomeScreen extends StatelessWidget {
  const RecentIncomeScreen({super.key});

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
          'Recent Income',
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
      body: Consumer<IncomeService>(
        builder: (context, incomeService, child) {
          // Using yearly range to show a comprehensive list of recent incomes
          return StreamBuilder<List<Income>>(
            stream: incomeService.getIncomesStream(TimeRange.yearly, DateTime.now()),
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
                          'Error Loading Income',
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

              final incomes = snapshot.data ?? [];

              // Empty state with call-to-action
              if (incomes.isEmpty) {
                return EmptyState.noIncome();
              }

              // Sort by date descending (newest first)
              incomes.sort((a, b) => b.date.compareTo(a.date));

              // Income list with theme-aware styling
              return ListView.builder(
                itemCount: incomes.length,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageMarginHorizontal,
                  vertical: AppSpacing.listItemGap,
                ),
                itemBuilder: (context, index) {
                  final income = incomes[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.listItemGap),
                    child: Dismissible(
                      key: Key(income.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: AppSpacing.xl),
                        decoration: BoxDecoration(
                          // Using expense color for delete background (semantic consistency)
                          color: AppColors.expenseNormal,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 32),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              backgroundColor: AppColors.getSurfaceColor(theme.brightness, 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
                              ),
                              title: Text(
                                'Confirm Delete',
                                style: AppTypography.headingMedium(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete this income?',
                                style: AppTypography.bodyMedium(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                  child: Text(
                                    'Cancel',
                                    style: AppTypography.buttonMedium(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                  child: Text(
                                    'Delete',
                                    style: AppTypography.buttonMedium(color: AppColors.expenseNormal),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        incomeService.deleteIncome(income.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Income deleted',
                              style: AppTypography.bodyMedium(color: Colors.white),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
                            ),
                          ),
                        );
                      },
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
                        // Using semantic card shadow
                        shadowColor: isDark ? Colors.black : Colors.grey.shade300,
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              // Income background tint
                              color: isDark
                                  ? AppColors.incomeBackgroundDark
                                  : AppColors.incomeBackgroundLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.attach_money,
                              // Using semantic income color
                              color: AppColors.incomePositive,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            income.title,
                            style: AppTypography.headingSmall(
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              '${DateFormat.yMMMd().format(income.date)} • ${income.category}',
                              style: AppTypography.labelMedium(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          trailing: Consumer<CurrencyService>(
                            builder: (context, currencyService, _) => Text(
                              currencyService.formatAmountWithDecimal(income.amount),
                              // Using financial typography for amounts
                              style: AppTypography.financialMedium(
                                color: AppColors.incomePositive,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
