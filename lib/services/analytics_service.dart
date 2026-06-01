import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/utils/stream_extensions.dart';

// Analytics data models for SmartExpense
class SmartExpenseAnalytics {
  final List<Expense> expenses;
  final List<Income> incomes;
  final DateTime startDate;
  final DateTime endDate;
  final TimeRange timeRange;

  SmartExpenseAnalytics({
    required this.expenses,
    required this.incomes,
    required this.startDate,
    required this.endDate,
    required this.timeRange,
  });

  double get totalExpenses => expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  double get totalIncome => incomes.fold(0.0, (sum, income) => sum + income.amount);
  double get netBalance => totalIncome - totalExpenses;
  double get savingsRate => totalIncome > 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0;

  Map<String, double> get expensesByCategory {
    Map<String, double> categoryTotals = {};
    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }
    return categoryTotals;
  }

  Map<String, int> get expenseCountByCategory {
    Map<String, int> categoryCounts = {};
    for (var expense in expenses) {
      categoryCounts[expense.category] = (categoryCounts[expense.category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  List<DailySpending> get dailySpendingTrend {
    Map<DateTime, double> dailyTotals = {};
    for (var expense in expenses) {
      DateTime day = DateTime(expense.date.year, expense.date.month, expense.date.day);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
    }
    
    List<DailySpending> trend = [];
    DateTime current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      DateTime day = DateTime(current.year, current.month, current.day);
      trend.add(DailySpending(
        date: day,
        amount: dailyTotals[day] ?? 0,
      ));
      current = current.add(const Duration(days: 1));
    }
    return trend;
  }

  double get averageDailySpending {
    if (expenses.isEmpty) return 0;
    int daysDiff = endDate.difference(startDate).inDays + 1;
    return totalExpenses / daysDiff;
  }

  Expense? get largestExpense {
    if (expenses.isEmpty) return null;
    return expenses.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  String get topExpenseCategory {
    if (expensesByCategory.isEmpty) return 'No expenses';
    return expensesByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<Expense> get recentExpenses {
    List<Expense> sorted = List.from(expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(10).toList();
  }
}

class DailySpending {
  final DateTime date;
  final double amount;

  DailySpending({required this.date, required this.amount});
}

// Main analytics dialog for SmartExpense - Made public
void showSmartExpenseAnalytics(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.90,
        child: const SmartExpenseAnalyticsDialog(),
      ),
    ),
  );
}

class SmartExpenseAnalyticsDialog extends StatefulWidget {
  const SmartExpenseAnalyticsDialog({super.key});

  @override
  SmartExpenseAnalyticsDialogState createState() => SmartExpenseAnalyticsDialogState();
}

class SmartExpenseAnalyticsDialogState extends State<SmartExpenseAnalyticsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SmartExpenseAnalytics? _analytics;
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.monthly;
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final expenseService = Provider.of<ExpenseService>(context, listen: false);
      final incomeService = Provider.of<IncomeService>(context, listen: false);

      // Get date range based on selected time range
      DateTime startDate, endDate;
      switch (_selectedTimeRange) {
        case TimeRange.daily:
          startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
          endDate = startDate;
          break;
        case TimeRange.monthly:
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
          break;
        case TimeRange.yearly:
          if (_selectedDate.month < 7) { // Before July
            startDate = DateTime(_selectedDate.year - 1, 7, 1);
            endDate = DateTime(_selectedDate.year, 6, 30, 23, 59, 59);
          } else { // July or after
            startDate = DateTime(_selectedDate.year, 7, 1);
            endDate = DateTime(_selectedDate.year + 1, 6, 30, 23, 59, 59);
          }
          break;
        default:
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      }

      // Get expenses and incomes for the selected period
      final expenseStream = expenseService.getExpensesStream(_selectedTimeRange, _selectedDate);
      final incomeStream = incomeService.getIncomesStream(_selectedTimeRange, _selectedDate);

      final expenses = await expenseStream.firstOrDefault([]);
      final incomes = await incomeStream.firstOrDefault([]);

      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _analytics = SmartExpenseAnalytics(
            expenses: expenses,
            incomes: incomes,
            startDate: startDate,
            endDate: endDate,
            timeRange: _selectedTimeRange,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor,
                theme.primaryColor.withAlpha((0.8 * 255).round()),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SmartExpense Analytics',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getTimeRangeText(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildTimeRangeDropdown(),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Spending'),
                  Tab(text: 'Categories'),
                  Tab(text: 'Trends'),
                  Tab(text: 'Insights'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your financial data...'),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildSpendingTab(),
                _buildCategoriesTab(),
                _buildTrendsTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  String _getTimeRangeText() {
    switch (_selectedTimeRange) {
      case TimeRange.daily:
        return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
      case TimeRange.monthly:
        return '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';
      case TimeRange.yearly:
        return '${_selectedDate.year}';
      default:
        return '';
    }
  }

  Widget _buildTimeRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<TimeRange>(
        value: _selectedTimeRange,
        dropdownColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        underline: Container(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        onChanged: (TimeRange? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedTimeRange = newValue;
            });
            _loadAnalyticsData();
          }
        },
        items: const [
          DropdownMenuItem(value: TimeRange.daily, child: Text('Daily')),
          DropdownMenuItem(value: TimeRange.monthly, child: Text('Monthly')),
          DropdownMenuItem(value: TimeRange.yearly, child: Text('Yearly')),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildOverviewTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    debugPrint('Debug: Building Overview Tab with analytics: $_analytics');

    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    debugPrint('Debug: Total Expenses: ${_analytics!.totalExpenses}');
    debugPrint('Debug: Total Income: ${_analytics!.totalIncome}');
    debugPrint('Debug: Net Balance: ${_analytics!.netBalance}');
    debugPrint('Debug: Savings Rate: ${_analytics!.savingsRate}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Key Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Expenses',
                  currencyService.formatAmountWithDecimal(_analytics!.totalExpenses),
                  Icons.money_off,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Total Income',
                  currencyService.formatAmountWithDecimal(_analytics!.totalIncome),
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Net Balance',
                  currencyService.formatAmountWithDecimal(_analytics!.netBalance),
                  _analytics!.netBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                  _analytics!.netBalance >= 0 ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Savings Rate',
                  '${_analytics!.savingsRate.toStringAsFixed(1)}%',
                  Icons.savings,
                  _analytics!.savingsRate > 0 ? Colors.blue : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Quick Stats Card
          _buildQuickStatsCard(),
          const SizedBox(height: 16),
          
          // Recent Transactions
          _buildRecentTransactionsCard(),
          const SizedBox(height: 16),
          
          // Top Categories Summary
          _buildTopCategoriesSummary(),
        ],
      ),
    );
  }

  Widget _buildSpendingTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    debugPrint('Debug: Building Spending Tab with analytics: $_analytics');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Daily Spending Chart
          _buildDailySpendingChart(),
          const SizedBox(height: 24),
          
          // Spending Summary Cards
          Row(
            children: [
              Expanded(child: _buildSpendingSummaryCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildLargestExpenseCard()),
            ],
          ),
          const SizedBox(height: 16),
          
          // Expense Distribution
          _buildExpenseDistributionCard(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  'Transactions',
                  '${_analytics!.expenses.length}',
                  Icons.receipt,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  'Categories',
                  '${_analytics!.expensesByCategory.length}',
                  Icons.category,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  'Avg/Day',
                  currencyService.formatAmount(_analytics!.averageDailySpending),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final recentExpenses = _analytics!.recentExpenses.take(5).toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (recentExpenses.isEmpty)
            const Center(
              child: Text(
                'No recent transactions',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
          ...recentExpenses.map((expense) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.blue, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        expense.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyService.formatAmountWithDecimal(expense.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${expense.date.day}/${expense.date.month}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTopCategoriesSummary() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final topCategories = _analytics!.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (topCategories.isEmpty)
            const Center(
              child: Text(
                'No category data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...topCategories.take(3).map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(topCategories.indexOf(entry)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${(entry.value / _analytics!.totalExpenses * 100).toStringAsFixed(1)}% of total',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyService.formatAmountWithDecimal(entry.value),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildDailySpendingChart() {
    if (_analytics!.dailySpendingTrend.isEmpty) {
      return _buildEmptyChart('No daily spending data available');
    }

    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final maxAmount = _analytics!.dailySpendingTrend
        .map((e) => e.amount)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Spending Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxAmount / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: maxAmount / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currencyService.formatAmount(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _analytics!.dailySpendingTrend.length / 7,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _analytics!.dailySpendingTrend.length) {
                          final date = _analytics!.dailySpendingTrend[index].date;
                          return Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _analytics!.dailySpendingTrend
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.amount))
                        .toList(),
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingSummaryCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'Average per Transaction',
            _analytics!.expenses.isNotEmpty
                ? currencyService.formatAmountWithDecimal(_analytics!.totalExpenses / _analytics!.expenses.length)
                : currencyService.formatAmountWithDecimal(0),
            Icons.receipt,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Daily Average',
            currencyService.formatAmountWithDecimal(_analytics!.averageDailySpending),
            Icons.calendar_today,
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Total Transactions',
            '${_analytics!.expenses.length}',
            Icons.list,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLargestExpenseCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final largestExpense = _analytics!.largestExpense;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Largest Expense',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (largestExpense != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyService.formatAmountWithDecimal(largestExpense.amount),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    largestExpense.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    largestExpense.category,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${largestExpense.date.day}/${largestExpense.date.month}/${largestExpense.date.year}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const Center(
              child: Text(
                'No expenses recorded',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseDistributionCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final sortedCategories = _analytics!.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedCategories.isEmpty)
            const Center(
              child: Text(
                'No expense data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / _analytics!.totalExpenses);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyService.formatAmountWithDecimal(entry.value),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(sortedCategories.indexOf(entry)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}% of total',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }


  Widget _buildCategoriesTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    debugPrint('Debug: Building Categories Tab with analytics: $_analytics');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildCategoryBreakdownChart(),
          const SizedBox(height: 24),
          _buildCategoryDetailsCard(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonthlyComparisonChart(),
          const SizedBox(height: 24),
          _buildSpendingPatternCard(),
          const SizedBox(height: 24),
          _buildBudgetProgressCard(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    if (_analytics == null) return const Center(child: Text('No data available'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFinancialHealthCard(),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Budget Alert',
            _getBudgetInsight(),
            Icons.warning,
            _getBudgetAlertColor(),
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Savings Opportunity',
            _getSavingsInsight(),
            Icons.savings,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Spending Pattern',
            _getSpendingPatternInsight(),
            Icons.timeline,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Category Focus',
            _getCategoryInsight(),
            Icons.category,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownChart() {
    if (_analytics!.expensesByCategory.isEmpty) {
      return _buildEmptyChart('No category data available');
    }

    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final sortedCategories = _analytics!.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Categories by Spending',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Showing top 6 categories',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: sortedCategories.first.value * 1.3,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (barSpot) => Colors.blueGrey.withAlpha((0.8 * 255).round()),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = sortedCategories[group.x.toInt()];
                      return BarTooltipItem(
                        '${category.key}\n${currencyService.formatAmountWithDecimal(rod.toY)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: sortedCategories.first.value / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currencyService.formatAmount(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < sortedCategories.length) {
                          final category = sortedCategories[index].key;
                          final percentage = (sortedCategories[index].value / _analytics!.totalExpenses * 100);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              children: [
                                Text(
                                  category.length > 10
                                      ? '${category.substring(0, 10)}...'
                                      : category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                barGroups: sortedCategories.take(6).map((entry) {
                  final index = sortedCategories.indexOf(entry);
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value,
                        color: _getCategoryColor(index),
                        width: 30,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: sortedCategories.first.value * 1.3,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                    showingTooltipIndicators: [],
                  );
                }).toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: sortedCategories.first.value / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(int index) {
    const colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.amber
    ];
    return colors[index % colors.length];
  }

  Widget _buildCategoryDetailsCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final sortedCategories = _analytics!.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedCategories.map((entry) => 
            _buildCategoryDetailRow(
              entry.key,
              currencyService.formatAmountWithDecimal(entry.value),
              _analytics!.expenseCountByCategory[entry.key] ?? 0,
              (entry.value / _analytics!.totalExpenses * 100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDetailRow(String category, String amount, int count, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$count transactions',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyComparisonChart() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final previousAmount = _analytics!.totalExpenses * 0.8; // Simulated previous period
    final currentAmount = _analytics!.totalExpenses;
    final percentageChange = previousAmount > 0 
        ? ((currentAmount - previousAmount) / previousAmount * 100) 
        : 0.0;
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Period Comparison',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: percentageChange > 0 ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      percentageChange > 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: percentageChange > 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${percentageChange.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: percentageChange > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _analytics!.totalExpenses * 1.3,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: previousAmount,
                        color: Colors.grey[400]!,
                        width: 40,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: currentAmount,
                        color: Theme.of(context).primaryColor,
                        width: 40,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      interval: _analytics!.totalExpenses / 4,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            currencyService.formatAmount(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('Previous', style: TextStyle(fontSize: 12));
                        if (value == 1) return const Text('Current', style: TextStyle(fontSize: 12));
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _analytics!.totalExpenses / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingPatternCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pattern, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Spending Patterns',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPatternItem(
            'Most Active Day',
            _getMostActiveDay(),
            Icons.calendar_today,
            Colors.orange,
          ),
          _buildPatternItem(
            'Average Transaction',
            _getAverageTransaction(),
            Icons.attach_money,
            Colors.green,
          ),
          _buildPatternItem(
            'Spending Frequency',
            _getSpendingFrequency(),
            Icons.timeline,
            Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternItem(String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMostActiveDay() {
    if (_analytics!.expenses.isEmpty) return 'No data';
    
    Map<int, int> dayCount = {};
    for (var expense in _analytics!.expenses) {
      dayCount[expense.date.weekday] = (dayCount[expense.date.weekday] ?? 0) + 1;
    }
    
    final mostActiveDay = dayCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[mostActiveDay.key - 1];
  }

  String _getAverageTransaction() {
    if (_analytics!.expenses.isEmpty) return '0';
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final average = _analytics!.totalExpenses / _analytics!.expenses.length;
    return currencyService.formatAmountWithDecimal(average);
  }

  String _getSpendingFrequency() {
    if (_analytics!.expenses.isEmpty) return 'No transactions';
    final days = _analytics!.endDate.difference(_analytics!.startDate).inDays + 1;
    final frequency = _analytics!.expenses.length / days;
    return '${frequency.toStringAsFixed(1)} per day';
  }

  Widget _buildBudgetProgressCard() {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final budgetUsed = _analytics!.totalIncome > 0 
        ? (_analytics!.totalExpenses / _analytics!.totalIncome) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.track_changes, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Budget Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: budgetUsed.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              budgetUsed > 1.0 ? Colors.red : 
              budgetUsed > 0.8 ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${currencyService.formatAmountWithDecimal(_analytics!.totalExpenses)}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                '${(budgetUsed * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: budgetUsed > 1.0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          if (_analytics!.totalIncome > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Budget: ${currencyService.formatAmountWithDecimal(_analytics!.totalIncome)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthCard() {
    final healthScore = _calculateHealthScore();
    final healthColor = _getHealthColor(healthScore);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            healthColor.withAlpha((0.1 * 255).round()),
            healthColor.withAlpha((0.05 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: healthColor.withAlpha((0.3 * 255).round())),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: healthColor.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getHealthIcon(healthScore),
                  color: healthColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Financial Health Score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getHealthDescription(healthScore),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${healthScore.toInt()}/100',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: healthScore / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(healthColor),
          ),
        ],
      ),
    );
  }

  double _calculateHealthScore() {
    double score = 50; // Base score
    
    // Savings rate bonus
    if (_analytics!.savingsRate > 0) {
      score += (_analytics!.savingsRate * 0.5).clamp(0, 30);
    } else {
      score -= 20;
    }
    
    // Income vs expenses
    if (_analytics!.totalIncome > _analytics!.totalExpenses) {
      score += 20;
    } else {
      score -= 15;
    }
    
    // Diversification bonus (more categories = better budgeting)
    if (_analytics!.expensesByCategory.length > 3) {
      score += 10;
    }
    
    return score.clamp(0, 100);
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getHealthIcon(double score) {
    if (score >= 80) return Icons.trending_up;
    if (score >= 60) return Icons.trending_flat;
    return Icons.trending_down;
  }

  String _getHealthDescription(double score) {
    if (score >= 80) return 'Excellent financial management';
    if (score >= 60) return 'Good, with room for improvement';
    return 'Needs attention';
  }

  String _getBudgetInsight() {
    if (_analytics!.totalIncome == 0) {
      return 'Set up income tracking to monitor your budget effectively.';
    }
    
    final spentPercentage = (_analytics!.totalExpenses / _analytics!.totalIncome) * 100;
    
    if (spentPercentage < 80) {
      return 'Great job! You\'re staying within budget with ${(100 - spentPercentage).toStringAsFixed(0)}% remaining.';
    } else if (spentPercentage < 100) {
      return 'Caution: You\'ve used ${spentPercentage.toStringAsFixed(0)}% of your budget. Consider reducing spending.';
    } else {
      return 'Alert: You\'ve exceeded your budget by ${(spentPercentage - 100).toStringAsFixed(0)}%. Review your expenses.';
    }
  }

  Color _getBudgetAlertColor() {
    if (_analytics!.totalIncome == 0) return Colors.blue;
    
    final spentPercentage = (_analytics!.totalExpenses / _analytics!.totalIncome) * 100;
    
    if (spentPercentage < 80) return Colors.green;
    if (spentPercentage < 100) return Colors.orange;
    return Colors.red;
  }

  String _getSavingsInsight() {
    if (_analytics!.savingsRate > 20) {
      return 'Excellent savings rate! Consider investing your surplus for long-term growth.';
    } else if (_analytics!.savingsRate > 10) {
      return 'Good savings habit. Try to increase by reducing non-essential expenses.';
    } else if (_analytics!.savingsRate > 0) {
      return 'You\'re saving, but there\'s room to improve. Review your top spending categories.';
    } else {
      return 'Focus on creating a budget surplus. Start by tracking all expenses and cutting unnecessary costs.';
    }
  }

  String _getSpendingPatternInsight() {
    final avgDaily = _analytics!.averageDailySpending;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);

    if (avgDaily > 0) {
      return 'Your average daily spending is ${currencyService.formatAmountWithDecimal(avgDaily)}. '
          'Try setting a daily limit to control expenses.';
    } else {
      return 'Start tracking daily expenses to identify spending patterns and opportunities to save.';
    }
  }

  String _getCategoryInsight() {
    if (_analytics!.expensesByCategory.isEmpty) {
      return 'Add expense categories to get personalized insights about your spending habits.';
    }
    
    final topCategory = _analytics!.topExpenseCategory;
    final topAmount = _analytics!.expensesByCategory[topCategory] ?? 0;
    final percentage = (topAmount / _analytics!.totalExpenses * 100);
    
    return '$topCategory accounts for ${percentage.toStringAsFixed(0)}% of your spending. '
           'Consider if this allocation aligns with your priorities.';
  }

  Widget _buildRecommendationCard(String title, String insight, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  insight,
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String message) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
