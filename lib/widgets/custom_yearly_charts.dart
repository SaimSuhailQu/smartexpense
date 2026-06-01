import 'package:flutter/material.dart' hide YearPicker;
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smartexpense/services/currency_service.dart';

class CustomYearlyCharts extends StatefulWidget {
  final List<Expense> expenses;
  final DateTime selectedYear;

  const CustomYearlyCharts({super.key, required this.expenses, required this.selectedYear});

  @override
  State<CustomYearlyCharts> createState() => _CustomYearlyChartsState();
}

class _CustomYearlyChartsState extends State<CustomYearlyCharts>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  // late DateTime _selectedYear; // Removed
  // late Future<List<Expense>> _expensesFuture; // Removed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    // _selectedYear = DateTime.now(); // Removed
    // _loadExpenses(); // Removed
  }

  // void _loadExpenses() { // Removed
  //   final expenseService = Provider.of<ExpenseService>(context, listen: false);
  //   final startDate = DateTime(_selectedYear.year, 1, 1);
  //   final endDate = DateTime(_selectedYear.year, 12, 31);
  //   _expensesFuture = expenseService.getExpensesBetweenDates(startDate, endDate).first;
  // }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No longer using FutureBuilder as data is passed via constructor
    final expenses = widget.expenses;
    final selectedYear = widget.selectedYear;
    
    // Filter expenses for the selected year
    final yearlyExpenses = expenses.where((expense) => expense.date.year == selectedYear.year).toList();

    if (yearlyExpenses.isEmpty) {
      return const Center(child: Text('No expenses for this period.'));
    }

    final monthlyData = _getMonthlyData(yearlyExpenses);
    final totalYear = yearlyExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Removed _buildYearPicker(), year selection is managed by parent
            const SizedBox(height: 16),
            _buildHeader(totalYear),
            const SizedBox(height: 16),
            _buildTabBar(),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: TabBarView(
                controller: _tabController,
                children: [
                                _buildMonthlyBarChart(monthlyData),
                                _buildCategoryPieChart(yearlyExpenses),
                                _buildTrendLineChart(monthlyData),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(monthlyData),
          ],
        ),
      ),
    );
  }

  // Removed _buildYearPicker() as year selection is managed by parent

  Widget _buildHeader(double totalYear) {
    final currencyService =
        Provider.of<CurrencyService>(context, listen: false);
    final formattedTotal = currencyService.formatAmountWithDecimal(totalYear);
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Custom Yearly Expenses',
                  style:
                      theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTotal,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.calendar_today, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade400,
        tabs: const [
          Tab(text: 'Monthly'),
          Tab(text: 'Categories'),
          Tab(text: 'Trends'),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(List<MonthlyExpense> monthlyData) {
    final theme = Theme.of(context);
    final currencyService =
        Provider.of<CurrencyService>(context, listen: false);

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SfCartesianChart(
          title: ChartTitle(
            text: 'Monthly Expenses',
            textStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          primaryXAxis: CategoryAxis(
            labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            labelFormat: '${currencyService.symbol}{value}',
            labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            majorGridLines:
                MajorGridLines(width: 0.5, color: Colors.white.withAlpha(51)),
          ),
          series: <CartesianSeries>[
            ColumnSeries<MonthlyExpense, String>(
              dataSource: monthlyData,
              xValueMapper: (MonthlyExpense data, _) =>
                  data.monthName.substring(0, 3),
              yValueMapper: (MonthlyExpense data, _) => data.totalAmount,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                labelAlignment: ChartDataLabelAlignment.top,
                textStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
              animationDuration: 1000,
            ),
          ],
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.x : ${currencyService.symbol}point.y',
            textStyle: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPieChart(List<Expense> expenses) {
    final categoryData = _getCategoryData(expenses);
    final theme = Theme.of(context);
    final currencyService =
        Provider.of<CurrencyService>(context, listen: false);

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SfCircularChart(
          title: ChartTitle(
            text: 'Category Breakdown',
            textStyle:
                theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          legend: Legend(
            isVisible: true,
            overflowMode: LegendItemOverflowMode.wrap,
            textStyle:
                theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          series: <CircularSeries>[
            DoughnutSeries<CategoryExpense, String>(
              dataSource: categoryData,
              xValueMapper: (CategoryExpense data, _) => data.category,
              yValueMapper: (CategoryExpense data, _) => data.amount,
              innerRadius: '60%',
              explode: true,
              explodeOffset: '10%',
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                labelPosition: ChartDataLabelPosition.outside,
                connectorLineSettings: ConnectorLineSettings(
                  type: ConnectorType.curve,
                ),
              ),
              dataLabelMapper: (CategoryExpense data, _) =>
                  '${data.category}\n${currencyService.formatAmountWithDecimal(data.amount)}',
            )
          ],
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.x : ${currencyService.symbol}point.y',
            textStyle: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendLineChart(List<MonthlyExpense> monthlyData) {
    final theme = Theme.of(context);
    final currencyService =
        Provider.of<CurrencyService>(context, listen: false);

    return FadeTransition(
      opacity: _animation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SfCartesianChart(
          title: ChartTitle(
            text: 'Expense Trends',
            textStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          primaryXAxis: CategoryAxis(
            labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            labelFormat: '${currencyService.symbol}{value}',
            labelStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            majorGridLines:
                MajorGridLines(width: 0.5, color: Colors.white.withAlpha(51)),
          ),
          series: <CartesianSeries>[
            SplineAreaSeries<MonthlyExpense, String>(
              dataSource: monthlyData,
              xValueMapper: (MonthlyExpense data, _) =>
                  data.monthName.substring(0, 3),
              yValueMapper: (MonthlyExpense data, _) => data.totalAmount,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderColor: theme.colorScheme.primary,
              borderWidth: 3,
              markerSettings: const MarkerSettings(
                isVisible: true,
                height: 8,
                width: 8,
                borderWidth: 2,
                borderColor: Colors.white,
              ),
              animationDuration: 1000,
            ),
          ],
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.x : ${currencyService.symbol}point.y',
            textStyle: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<MonthlyExpense> monthlyData) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();
    final totalYear = monthlyData.fold(0.0, (sum, m) => sum + m.totalAmount);
    final monthlyAverage = totalYear / 12;
    final highestMonth =
        monthlyData.reduce((a, b) => a.totalAmount > b.totalAmount ? a : b);
    final lowestMonth =
        monthlyData.reduce((a, b) => a.totalAmount < b.totalAmount ? a : b);
    final currencyService =
        Provider.of<CurrencyService>(context, listen: false);

    return FadeTransition(
      opacity: _animation,
      child: Row(
        children: [
          _buildSummaryCard(
            'Monthly Average',
            currencyService.formatAmountWithDecimal(monthlyAverage),
            Icons.trending_up,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Highest Month',
            '''${highestMonth.monthName.substring(0, 3)}
${currencyService.formatAmountWithDecimal(highestMonth.totalAmount)}''',
            Icons.arrow_upward,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildSummaryCard(
            'Lowest Month',
            '''${lowestMonth.monthName.substring(0, 3)}
${currencyService.formatAmountWithDecimal(lowestMonth.totalAmount)}''',
            Icons.arrow_downward,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<MonthlyExpense> _getMonthlyData(List<Expense> expenses) {
    final monthlyData = <MonthlyExpense>[];
    final startYear = widget.selectedYear.year;

    for (int i = 0; i < 12; i++) {
      int month = i + 1;
      int year = startYear;

      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 0);
      final monthExpenses = expenses.where((expense) =>
          expense.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          expense.date.isBefore(monthEnd.add(const Duration(days: 1))));
      final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      monthlyData.add(MonthlyExpense(
        year: year,
        month: month,
        totalAmount: total,
      ));
    }
    return monthlyData;
  }

  List<CategoryExpense> _getCategoryData(List<Expense> expenses) {
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals.entries
        .map((entry) => CategoryExpense(category: entry.key, amount: entry.value))
        .toList();
  }
}

class MonthlyExpense {
  final int year;
  final int month;
  final double totalAmount;

  MonthlyExpense({
    required this.year,
    required this.month,
    required this.totalAmount,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class CategoryMonthlyData {
  final String month;
  final String category;
  final double amount;

  CategoryMonthlyData({
    required this.month,
    required this.category,
    required this.amount,
  });
}

class CategoryExpense {
  final String category;
  final double amount;

  CategoryExpense({required this.category, required this.amount});
}
