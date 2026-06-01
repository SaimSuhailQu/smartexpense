import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:smartexpense/theme/app_colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/services/yearly_report_export_service.dart';
import 'package:smartexpense/widgets/glass_container.dart';
import 'package:smartexpense/widgets/tactile_bounce.dart';
class EnhancedYearlyCharts extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;
  final DateTime selectedYear;

  const EnhancedYearlyCharts({
    super.key,
    required this.expenses,
    required this.incomes,
    required this.selectedYear,
  });

  @override
  State<EnhancedYearlyCharts> createState() => _EnhancedYearlyChartsState();
}

class _EnhancedYearlyChartsState extends State<EnhancedYearlyCharts>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime getFiscalYearStart(DateTime date) {
    if (date.month < 7) {
      return DateTime(date.year - 1, 7, 1);
    } else {
      return DateTime(date.year, 7, 1);
    }
  }

  List<MonthlyFinancialData> _getMonthlyFinancialData() {
    final list = <MonthlyFinancialData>[];
    final fiscalStart = getFiscalYearStart(widget.selectedYear);

    for (int i = 0; i < 12; i++) {
      final currentMonthDate = DateTime(fiscalStart.year, fiscalStart.month + i, 1);
      final monthStart = DateTime(currentMonthDate.year, currentMonthDate.month, 1);
      final monthEnd = DateTime(currentMonthDate.year, currentMonthDate.month + 1, 0, 23, 59, 59);

      // Filter expenses
      final monthExpenses = widget.expenses.where((e) =>
          e.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(monthEnd.add(const Duration(seconds: 1))));
      final totalExpenses = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

      // Filter incomes
      final monthIncomes = widget.incomes.where((income) =>
          income.date.isAfter(monthStart.subtract(const Duration(seconds: 1))) &&
          income.date.isBefore(monthEnd.add(const Duration(seconds: 1))));
      final totalIncome = monthIncomes.fold(0.0, (sum, income) => sum + income.amount);

      list.add(MonthlyFinancialData(
        year: currentMonthDate.year,
        month: currentMonthDate.month,
        income: totalIncome,
        expenses: totalExpenses,
      ));
    }
    return list;
  }

  List<CategoryExpense> _getCategoryData() {
    final categoryTotals = <String, double>{};
    for (final expense in widget.expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final list = categoryTotals.entries
        .map((entry) => CategoryExpense(category: entry.key, amount: entry.value))
        .toList();
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.blue.shade500,
      Colors.green.shade500,
      Colors.orange.shade500,
      Colors.purple.shade500,
      Colors.red.shade500,
      Colors.teal.shade500,
      Colors.indigo.shade500,
      Colors.amber.shade500,
      Colors.pink.shade500,
      Colors.cyan.shade500,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final monthlyData = _getMonthlyFinancialData();

    final totalExpenses = widget.expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalIncome = widget.incomes.fold(0.0, (sum, e) => sum + e.amount);
    final totalSavings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0.0;

    return FadeTransition(
      opacity: _animation,
      child: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 16),
          SizedBox(
            height: 480,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(totalIncome, totalExpenses, totalSavings, savingsRate, monthlyData),
                _buildCashFlowTab(monthlyData),
                _buildSavingsTab(monthlyData),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.brightness == Brightness.dark ? 30 : 10),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withAlpha(150) ?? Colors.grey,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        tabs: const [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Overview'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Cash Flow'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Savings'),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Categories'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    double totalIncome,
    double totalExpenses,
    double totalSavings,
    double savingsRate,
    List<MonthlyFinancialData> monthlyData,
  ) {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    final avgMonthlyIncome = totalIncome / 12;
    final avgMonthlyExpenses = totalExpenses / 12;
    
    // Safety check for empty lists when calculating milestones
    MonthlyFinancialData highestExpenseMonth = dataOrEmptyFallback(monthlyData);
    MonthlyFinancialData highestIncomeMonth = dataOrEmptyFallback(monthlyData);
    if (monthlyData.isNotEmpty) {
      highestExpenseMonth = monthlyData.reduce((a, b) => a.expenses > b.expenses ? a : b);
      highestIncomeMonth = monthlyData.reduce((a, b) => a.income > b.income ? a : b);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Yearly Income',
                  value: currencyService.formatAmountWithDecimal(totalIncome),
                  icon: Icons.arrow_upward_rounded,
                  iconColor: Colors.green,
                  gradientColors: [Colors.green.shade500, Colors.teal.shade700],
                  onTap: () => _showMetricAdviceSheet(
                    'Yearly Income',
                    currencyService.formatAmountWithDecimal(totalIncome),
                    'Excellent earning progress! Having a yearly income of ${currencyService.formatAmount(totalIncome)} is a strong base. Consider allocating 15-20% of your earnings immediately into automated investments to build long-term compound wealth.',
                    [Colors.green.shade500, Colors.teal.shade700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Yearly Expenses',
                  value: currencyService.formatAmountWithDecimal(totalExpenses),
                  icon: Icons.arrow_downward_rounded,
                  iconColor: Colors.red,
                  gradientColors: [Colors.red.shade500, Colors.red.shade700],
                  onTap: () => _showMetricAdviceSheet(
                    'Yearly Expenses',
                    currencyService.formatAmountWithDecimal(totalExpenses),
                    'Your yearly expenses total ${currencyService.formatAmount(totalExpenses)}. Reviewing your top-spent category items under the \'Categories\' tab is the quickest way to find optimization opportunities. Try reducing minor recurring monthly subscriptions to keep this curve optimal.',
                    [Colors.red.shade500, Colors.red.shade700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Net Savings',
                  value: currencyService.formatAmountWithDecimal(totalSavings),
                  icon: Icons.savings_rounded,
                  iconColor: Colors.blue,
                  gradientColors: [Colors.blue.shade500, Colors.indigo.shade700],
                  onTap: () => _showMetricAdviceSheet(
                    'Net Savings',
                    currencyService.formatAmountWithDecimal(totalSavings),
                    totalSavings >= 0
                        ? 'You have kept a positive net savings balance of ${currencyService.formatAmount(totalSavings)}! Keeping this net positive allows you to invest and grow your net worth. Try setting a monthly challenge to build your emergency fund even further.'
                        : 'Your net savings is currently in the negative by ${currencyService.formatAmount(totalSavings.abs())}. Don\'t worry! This is a great opportunity to review your spending targets and use the \'Budgets\' screen to keep high-spend categories in check.',
                    [Colors.blue.shade500, Colors.indigo.shade700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Savings Rate',
                  value: '${savingsRate.toStringAsFixed(1)}%',
                  icon: Icons.pie_chart_rounded,
                  iconColor: Colors.purple,
                  gradientColors: [Colors.purple.shade500, Colors.deepPurple.shade700],
                  onTap: () => _showMetricAdviceSheet(
                    'Savings Rate',
                    '${savingsRate.toStringAsFixed(1)}%',
                    'Your current yearly savings rate is ${savingsRate.toStringAsFixed(1)}%. A saving rate of 15% to 20% is considered healthy, while hitting 30% or more accelerates your timeline to financial independence exponentially. Keep optimization high!',
                    [Colors.purple.shade500, Colors.deepPurple.shade700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildCashFlowBalanceBar(totalIncome, totalExpenses, totalSavings),
          const SizedBox(height: 20),
          _buildSecondaryStatsSection(
            avgMonthlyIncome: avgMonthlyIncome,
            avgMonthlyExpenses: avgMonthlyExpenses,
            highestIncomeMonth: highestIncomeMonth,
            highestExpenseMonth: highestExpenseMonth,
          ),
        ],
      ),
    );
  }

  MonthlyFinancialData dataOrEmptyFallback(List<MonthlyFinancialData> list) {
    if (list.isNotEmpty) return list.first;
    return MonthlyFinancialData(year: DateTime.now().year, month: DateTime.now().month, income: 0, expenses: 0);
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark 
        ? Colors.black.withAlpha(35) 
        : Colors.white.withAlpha(120);

    return TactileBounce(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        borderRadius: BorderRadius.circular(16),
        color: cardBgColor,
        borderColor: gradientColors.first.withAlpha(isDark ? 70 : 40),
        gradient: LinearGradient(
          colors: gradientColors.map((c) => c.withAlpha(isDark ? 30 : 15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: gradientColors.first.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: gradientColors.first, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricAdviceSheet(String title, String value, String advice, List<Color> colors) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.first.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      title == 'Yearly Income'
                          ? Icons.arrow_upward_rounded
                          : title == 'Yearly Expenses'
                              ? Icons.arrow_downward_rounded
                              : title == 'Net Savings'
                                  ? Icons.savings_rounded
                                  : Icons.pie_chart_rounded,
                      color: colors.first,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
                          ),
                        ),
                        Text(
                          value,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Financial Intelligence Insight',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.first,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.first.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.first.withAlpha(30),
                  ),
                ),
                child: Text(
                  advice,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.first,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Got it!'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildCashFlowBalanceBar(double income, double expenses, double savings) {
    final theme = Theme.of(context);
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    final expensePercent = income > 0 ? (expenses / income).clamp(0.0, 1.0) : 1.0;
    final savingsPercent = income > 0 ? (savings / income).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Cash Flow Distribution',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Savings: ${(savingsPercent * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: savings >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (expensePercent > 0)
                    Expanded(
                      flex: (expensePercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                        ),
                      ),
                    ),
                  if (savingsPercent > 0)
                    Expanded(
                      flex: (savingsPercent * 100).round(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade400, Colors.green.shade600],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.red.shade500, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'Spent: ${currencyService.formatAmount(expenses)} (${(expensePercent * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green.shade500, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      'Saved: ${currencyService.formatAmount(savings)} (${(savingsPercent * 100).toStringAsFixed(0)}%)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSecondaryStatsSection({
    required double avgMonthlyIncome,
    required double avgMonthlyExpenses,
    required MonthlyFinancialData highestIncomeMonth,
    required MonthlyFinancialData highestExpenseMonth,
  }) {
    final theme = Theme.of(context);
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yearly Averages & Milestones',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSecondaryStatRow(
            label: 'Avg. Monthly Income',
            value: currencyService.formatAmountWithDecimal(avgMonthlyIncome),
            icon: Icons.trending_up_rounded,
            iconColor: Colors.green,
          ),
          const Divider(height: 24),
          _buildSecondaryStatRow(
            label: 'Avg. Monthly Spend',
            value: currencyService.formatAmountWithDecimal(avgMonthlyExpenses),
            icon: Icons.trending_down_rounded,
            iconColor: Colors.red,
          ),
          const Divider(height: 24),
          _buildSecondaryStatRow(
            label: 'Highest Income Month',
            value: '${highestIncomeMonth.monthName.substring(0, 3)} - ${currencyService.formatAmount(highestIncomeMonth.income)}',
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
          ),
          const Divider(height: 24),
          _buildSecondaryStatRow(
            label: 'Highest Spend Month',
            value: '${highestExpenseMonth.monthName.substring(0, 3)} - ${currencyService.formatAmount(highestExpenseMonth.expenses)}',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStatRow({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withAlpha(180),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowTab(List<MonthlyFinancialData> data) {
    final theme = Theme.of(context);
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(20)),
      ),
      child: SfCartesianChart(
        onChartTouchInteractionDown: (ChartTouchInteractionArgs args) {
          HapticFeedback.selectionClick();
        },
        title: ChartTitle(
          text: 'Monthly Income vs. Expenses',
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: theme.textTheme.bodySmall,
        ),
        primaryXAxis: CategoryAxis(
          labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180)),
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          labelFormat: '${currencyService.symbol}{value}',
          labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180)),
          majorGridLines: MajorGridLines(width: 0.5, color: theme.dividerColor.withAlpha(50)),
        ),
        series: <CartesianSeries>[
          ColumnSeries<MonthlyFinancialData, String>(
            name: 'Income',
            dataSource: data,
            xValueMapper: (MonthlyFinancialData item, _) => item.monthName.substring(0, 3),
            yValueMapper: (MonthlyFinancialData item, _) => item.income,
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.teal.shade600],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            animationDuration: 1000,
          ),
          ColumnSeries<MonthlyFinancialData, String>(
            name: 'Expenses',
            dataSource: data,
            xValueMapper: (MonthlyFinancialData item, _) => item.monthName.substring(0, 3),
            yValueMapper: (MonthlyFinancialData item, _) => item.expenses,
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.orange.shade700],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            animationDuration: 1000,
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          shared: true,
          header: '',
          canShowMarker: true,
          color: theme.brightness == Brightness.dark
              ? const ui.Color(0xFF10111A).withAlpha(220)
              : Colors.white.withAlpha(235),
          borderColor: AppColors.primary.withAlpha(120),
          borderWidth: 1.0,
          format: 'point.x : ${currencyService.symbol}point.y',
          textStyle: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsTab(List<MonthlyFinancialData> data) {
    final theme = Theme.of(context);
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(20)),
      ),
      child: SfCartesianChart(
        onChartTouchInteractionDown: (ChartTouchInteractionArgs args) {
          HapticFeedback.selectionClick();
        },
        title: ChartTitle(
          text: 'Monthly Savings Progression',
          textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
          textStyle: theme.textTheme.bodySmall,
        ),
        primaryXAxis: CategoryAxis(
          labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180)),
          majorGridLines: const MajorGridLines(width: 0),
        ),
        primaryYAxis: NumericAxis(
          labelFormat: '${currencyService.symbol}{value}',
          labelStyle: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180)),
          majorGridLines: MajorGridLines(width: 0.5, color: theme.dividerColor.withAlpha(50)),
        ),
        series: <CartesianSeries>[
          SplineAreaSeries<MonthlyFinancialData, String>(
            name: 'Savings',
            dataSource: data,
            xValueMapper: (MonthlyFinancialData item, _) => item.monthName.substring(0, 3),
            yValueMapper: (MonthlyFinancialData item, _) => item.savings,
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade400.withAlpha(180),
                Colors.teal.shade100.withAlpha(50),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: Colors.teal.shade600,
            borderWidth: 2,
            animationDuration: 1000,
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          shared: true,
          header: '',
          canShowMarker: true,
          color: theme.brightness == Brightness.dark
              ? const ui.Color(0xFF10111A).withAlpha(220)
              : Colors.white.withAlpha(235),
          borderColor: AppColors.primary.withAlpha(120),
          borderWidth: 1.0,
          format: 'point.x : ${currencyService.symbol}point.y',
          textStyle: TextStyle(
            color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final categoryData = _getCategoryData();
    final theme = Theme.of(context);
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    if (categoryData.isEmpty) {
      return Container(
        alignment: Alignment.center,
        child: const Text('No expense data available for categories'),
      );
    }

    final totalSpent = categoryData.fold(0.0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withAlpha(20)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: SfCircularChart(
              margin: EdgeInsets.zero,
              palette: List.generate(categoryData.length, (index) => _getCategoryColor(index)),
              series: <CircularSeries>[
                DoughnutSeries<CategoryExpense, String>(
                  dataSource: categoryData,
                  xValueMapper: (CategoryExpense data, _) => data.category,
                  yValueMapper: (CategoryExpense data, _) => data.amount,
                  innerRadius: '60%',
                  explode: true,
                  explodeIndex: 0,
                  explodeOffset: '10%',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: false,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Header row: title + export buttons ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Category Breakdown',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currencyService.formatAmount(totalSpent),
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              _buildExportButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                color: Colors.red.shade600,
                onTap: () => _exportAsPdf(currencyService),
              ),
              const SizedBox(width: 6),
              _buildExportButton(
                icon: Icons.table_chart_rounded,
                label: 'CSV',
                color: Colors.green.shade700,
                onTap: () => _exportAsCsv(currencyService),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: categoryData.length,
              itemBuilder: (context, index) {
                final item = categoryData[index];
                final percent = totalSpent > 0 ? (item.amount / totalSpent) : 0.0;
                final categoryColor = _getCategoryColor(index);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.category,
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${currencyService.formatAmount(item.amount)} (${(percent * 100).toStringAsFixed(1)}%)',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: theme.dividerColor.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Export helpers ────────────────────────────────────────────────────

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TactileBounce(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportAsPdf(CurrencyService currencyService) async {
    final exportService = YearlyReportExportService();
    try {
      await exportService.exportYearlyReportAsPdf(
        expenses: widget.expenses,
        incomes: widget.incomes,
        year: widget.selectedYear.year,
        currencySymbol: currencyService.symbol,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportAsCsv(CurrencyService currencyService) async {
    final exportService = YearlyReportExportService();
    try {
      await exportService.exportYearlyReportAsCsv(
        expenses: widget.expenses,
        incomes: widget.incomes,
        year: widget.selectedYear.year,
        currencySymbol: currencyService.symbol,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV saved to Downloads'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class CategoryExpense {
  final String category;
  final double amount;

  CategoryExpense({required this.category, required this.amount});
}

class MonthlyFinancialData {
  final int year;
  final int month;
  final double income;
  final double expenses;

  MonthlyFinancialData({
    required this.year,
    required this.month,
    required this.income,
    required this.expenses,
  });

  double get savings => income - expenses;

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
