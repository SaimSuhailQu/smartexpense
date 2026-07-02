import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/widgets/expense_card.dart';
import 'package:smartexpense/utils/date_utils.dart';

class RecentExpensesScreen extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeRange? selectedRange;

  const RecentExpensesScreen({
    super.key,
    this.selectedDate,
    this.selectedRange,
  });

  String _getTitle(TimeRange range, DateTime date) {
    switch (range) {
      case TimeRange.daily:
        return 'Expenses: ${DateFormat.yMMMd().format(date)}';
      case TimeRange.weekly:
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return 'Expenses: ${DateFormat.yMMMd().format(start)} - ${DateFormat.yMMMd().format(end)}';
      case TimeRange.monthly:
        return 'Expenses: ${DateFormat.yMMM().format(date)}';
      case TimeRange.yearly:
        return 'Expenses: ${DateFormat.y().format(date)}';
      default:
        return 'Recent Expenses';
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = selectedDate ?? DateTime.now();
    final range = selectedRange ?? TimeRange.monthly;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(range, date)),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseService>().getExpensesStream(range, date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            String emptyMessage = 'No expenses recorded for this period.';
            if (range == TimeRange.monthly) {
              emptyMessage = 'No expenses recorded for this month.';
            } else if (range == TimeRange.yearly) {
              emptyMessage = 'No expenses recorded for this year.';
            } else if (range == TimeRange.daily) {
              emptyMessage = 'No expenses recorded for this day.';
            } else if (range == TimeRange.weekly) {
              emptyMessage = 'No expenses recorded for this week.';
            }
            return Center(child: Text(emptyMessage));
          }
          return ListView.builder(
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Slidable(
                key: ValueKey(expense.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) {
                        context.read<ExpenseService>().deleteExpense(expense.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${expense.title} deleted.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ],
                ),
                child: ExpenseCard(expense: expense),
              );
            },
          );
        },
      ),
    );
  }
}
