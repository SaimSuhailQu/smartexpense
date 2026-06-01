import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/services/budget_service.dart';
import 'package:smartexpense/screens/add_budget_screen.dart';
import 'package:intl/intl.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
      ),
      body: StreamBuilder<List<Budget>>(
        stream: context.watch<BudgetService>().getBudgetsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final budgets = snapshot.data ?? [];
          if (budgets.isEmpty) {
            return const Center(child: Text('No budgets found.'));
          }
          return ListView.builder(
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return ListTile(
                title: Text(budget.category),
                subtitle: Text(
                    '${DateFormat.yMd().format(budget.startDate)} - ${DateFormat.yMd().format(budget.endDate)}'),
                trailing: Text(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                      .format(budget.amount),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBudgetScreen(budget: budget),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBudgetScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
