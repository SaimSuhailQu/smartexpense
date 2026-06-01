import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/utils/date_utils.dart';

class RecentIncomeScreen extends StatelessWidget {
  const RecentIncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Income'),
      ),
      body: Consumer<IncomeService>(
        builder: (context, incomeService, child) {
          // Using yearly range to show a comprehensive list of recent incomes
          return StreamBuilder<List<Income>>(
            stream: incomeService.getIncomesStream(TimeRange.yearly, DateTime.now()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading income: ${snapshot.error}'),
                );
              }

              final incomes = snapshot.data ?? [];

              if (incomes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No income records found',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Sort by date descending (newest first)
              incomes.sort((a, b) => b.date.compareTo(a.date));

              return ListView.builder(
                itemCount: incomes.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final income = incomes[index];
                  return Dismissible(
                    key: Key(income.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20.0),
                      color: Colors.red,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text('Are you sure you want to delete this income?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    onDismissed: (direction) {
                      incomeService.deleteIncome(income.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Income deleted')),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          child: const Icon(Icons.attach_money, color: Colors.green),
                        ),
                        title: Text(
                          income.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${DateFormat.yMMMd().format(income.date)} • ${income.category}',
                        ),
                        trailing: Consumer<CurrencyService>(
                          builder: (context, currencyService, _) => Text(
                            currencyService.formatAmountWithDecimal(income.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}