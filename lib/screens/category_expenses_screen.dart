import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/widgets/expense_card.dart';

class CategoryExpensesScreen extends StatelessWidget {
  final String category;
  final DateTime selectedDate;
  final TimeRange timeRange;

  const CategoryExpensesScreen({
    super.key,
    required this.category,
    required this.selectedDate,
    required this.timeRange,
  });

  @override
  Widget build(BuildContext context) {
    final expenseService = context.watch<ExpenseService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.getExpensesStream(timeRange, selectedDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = snapshot.data
              ?.where((expense) => expense.category == category)
              .toList() ??
              [];

          if (expenses.isEmpty) {
            return const Center(
              child: Text('No expenses found for this category.'),
            );
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
                        expenseService.deleteExpense(expense.id);
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
