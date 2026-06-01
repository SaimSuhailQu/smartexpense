import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/screens/category_expenses_screen.dart';
import 'package:smartexpense/services/currency_service.dart';

class CategoriesTabContent extends StatelessWidget {
  final DateTime selectedDate;
  final TimeRange selectedRange;

  const CategoriesTabContent({
    super.key,
    required this.selectedDate,
    required this.selectedRange,
  });

  @override
  Widget build(BuildContext context) {
    final expenseService = context.watch<ExpenseService>();
    final currencyService = context.watch<CurrencyService>();

    return StreamBuilder<List<Expense>>(
      stream: expenseService.getExpensesStream(selectedRange, selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final expenses = snapshot.data ?? [];
        final categories = groupExpensesByCategory(expenses);

        if (categories.isEmpty) {
          return const Center(
            child: Text('No expenses found for this period.'),
          );
        }

        return ListView.builder(
          itemCount: categories.keys.length,
          itemBuilder: (context, index) {
            final category = categories.keys.elementAt(index);
            final categoryData = categories[category]!;
            final totalAmount = categoryData['totalAmount'] as double;
            final transactionCount = categoryData['transactionCount'] as int;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(category),
                subtitle: Text('$transactionCount transactions'),
                trailing: Text(
                  currencyService.formatAmountWithDecimal(totalAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryExpensesScreen(
                        category: category,
                        selectedDate: selectedDate,
                        timeRange: selectedRange,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> groupExpensesByCategory(
      List<Expense> expenses) {
    final Map<String, Map<String, dynamic>> categories = {};

    for (final expense in expenses) {
      if (categories.containsKey(expense.category)) {
        categories[expense.category]!['totalAmount'] += expense.amount;
        categories[expense.category]!['transactionCount'] += 1;
      } else {
        categories[expense.category] = {
          'totalAmount': expense.amount,
          'transactionCount': 1,
        };
      }
    }

    return categories;
  }
}
