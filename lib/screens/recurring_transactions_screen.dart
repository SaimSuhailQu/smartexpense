import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/recurring_transaction.dart';
import 'package:smartexpense/services/recurring_transaction_service.dart';
import 'package:smartexpense/screens/add_recurring_transaction_screen.dart';
import 'package:intl/intl.dart';

class RecurringTransactionsScreen extends StatelessWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
      ),
      body: StreamBuilder<List<RecurringTransaction>>(
        stream: context
            .watch<RecurringTransactionService>()
            .getRecurringTransactionsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final recurringTransactions = snapshot.data ?? [];
          if (recurringTransactions.isEmpty) {
            return const Center(child: Text('No recurring transactions found.'));
          }
          return ListView.builder(
            itemCount: recurringTransactions.length,
            itemBuilder: (context, index) {
              final transaction = recurringTransactions[index];
              return ListTile(
                title: Text(transaction.title),
                subtitle: Text(
                    '${transaction.type} - Every ${transaction.frequency.toString().split('.').last}'),
                trailing: Text(
                  NumberFormat.currency(locale: 'en_IN', symbol: '₹')
                      .format(transaction.amount),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddRecurringTransactionScreen(
                          recurringTransaction: transaction),
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
            MaterialPageRoute(
                builder: (context) => const AddRecurringTransactionScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
