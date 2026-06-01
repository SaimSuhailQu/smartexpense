import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/widgets/expense_card.dart';
import 'package:smartexpense/utils/date_utils.dart';

class RecentExpensesScreen extends StatelessWidget {
  const RecentExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Expenses'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseService>().getExpensesStream(TimeRange.monthly, DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses recorded for this month.'));
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
