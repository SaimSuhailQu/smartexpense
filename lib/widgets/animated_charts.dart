import 'package:flutter/material.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/widgets/circular_expense_chart.dart';
import 'package:smartexpense/widgets/category_expense_list.dart';

class AnimatedExpenseCharts extends StatefulWidget {
  final List<Expense> expenses;
  final TimeRange timeRange;
  final DateTime selectedDate;

  const AnimatedExpenseCharts({
    super.key,
    required this.expenses,
    required this.timeRange,
    required this.selectedDate,
  });

  @override
  State<AnimatedExpenseCharts> createState() => _AnimatedExpenseChartsState();
}

class _AnimatedExpenseChartsState extends State<AnimatedExpenseCharts>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Color> _palette = [
    const Color(0xFF8A2BE2), // Purple
    const Color(0xFFFFA500), // Orange
    const Color(0xFF32CD32), // LimeGreen
    Colors.cyan,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryData = _getCategoryData();
    final total = categoryData.values.fold(0.0, (sum, amount) => sum + amount);
    final entries = categoryData.entries.toList();

    return FadeTransition(
      opacity: _animation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CircularExpenseChart(
              categoryData: categoryData,
              total: total,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Expenses',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListView(
              children: entries.asMap().entries.map((indexedEntry) {
                final index = indexedEntry.key;
                final entry = indexedEntry.value;
                return _buildCategoryItem(
                  entry.key,
                  entry.value,
                  total,
                  index,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CategoryExpenseList(
              categoryData: categoryData,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String category, double amount, double total, int index) {
    final percentage = total > 0 ? (amount / total) : 0.0;
    final theme = Theme.of(context);
    final color = _palette[index % _palette.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% $category',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: theme.scaffoldBackgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }





  Map<String, double> _getCategoryData() {
    final Map<String, double> categoryTotals = {};
    for (final expense in widget.expenses) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }
}
