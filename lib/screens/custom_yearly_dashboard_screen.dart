import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/widgets/custom_yearly_charts.dart';

class CustomYearlyDashboardScreen extends StatefulWidget {
  const CustomYearlyDashboardScreen({super.key});

  @override
  State<CustomYearlyDashboardScreen> createState() =>
      _CustomYearlyDashboardScreenState();
}

class _CustomYearlyDashboardScreenState
    extends State<CustomYearlyDashboardScreen> {
  DateTime _selectedYear = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expenseService = Provider.of<ExpenseService>(context);
    final startDate = DateTime(_selectedYear.year, 1, 1);
    final endDate = DateTime(_selectedYear.year, 12, 31);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Yearly Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedYear,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDatePickerMode: DatePickerMode.year,
              );
              if (picked != null && picked.year != _selectedYear.year) {
                setState(() {
                  _selectedYear = picked;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.getExpensesBetweenDates(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final expenses = snapshot.data ?? [];
          return CustomYearlyCharts(
            expenses: expenses,
            selectedYear: _selectedYear,
          );
        },
      ),
    );
  }
}
