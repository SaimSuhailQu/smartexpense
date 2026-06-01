import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/utils/date_utils.dart';

class ExpenseCharts extends StatelessWidget {
  final List<Expense> expenses;
  final TimeRange timeRange;

  const ExpenseCharts({
    super.key,
    required this.expenses,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        title: ChartTitle(text: _getChartTitle()),
        legend: const Legend(isVisible: false),
        series: <CartesianSeries>[
          LineSeries<Expense, String>(
            dataSource: expenses,
            xValueMapper: (Expense expense, _) => expense.category,
            yValueMapper: (Expense expense, _) => expense.amount,
            color: Colors.purple,
            width: 3,
            markerSettings: const MarkerSettings(isVisible: true),
            onPointTap: (ChartPointDetails details) {
              final index = details.pointIndex;
              if (index != null && index < expenses.length) {
                final expense = expenses[index];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${expense.category}: RS ${expense.amount.toStringAsFixed(2)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          )
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (timeRange) {
      case TimeRange.daily:
        return 'Daily Expenses';
      case TimeRange.weekly:
        return 'Weekly Expenses';
      case TimeRange.monthly:
        return 'Monthly Expenses';
      case TimeRange.yearly:
        return 'Yearly Expenses';
      case TimeRange.loans:
        return 'Loan Expenses';
      case TimeRange.categories:
        return 'Category Expenses';
      case TimeRange.custom:
        return 'Custom Range Expenses';
    }
  }
}
