import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_card_placeholder.dart';
import '../widgets/slide_animation.dart';
import '../utils/date_utils.dart';

class ExpenseListWithAnimations extends StatelessWidget {
  final DateTime selectedDate;
  final TimeRange range;

  const ExpenseListWithAnimations({
    super.key,
    required this.range,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseService>(
      builder: (context, expenseService, _) {
        return StreamBuilder<List<Expense>>(
          stream: expenseService.getExpensesStream(range, selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                itemCount: 6,
                itemBuilder: (_, index) => SlideAnimation(
                  index: index,
                  child: const ExpenseCardPlaceholder(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No expenses found.'));
            }

            final expenses = snapshot.data!;
            return ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (_, index) {
                final expense = expenses[index];
                return SlideAnimation(
                  index: index,
                  child: Slidable(
                    key: ValueKey(expense.id),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (_) {
                            expenseService.deleteExpense(expense.id);
                          },
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: ExpenseCard(expense: expense),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
