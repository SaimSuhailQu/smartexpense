import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/widgets/budget_indicator.dart';
import 'package:smartexpense/widgets/expense_card.dart';
import 'package:smartexpense/widgets/charts.dart';
import 'package:smartexpense/screens/add_expense_screen.dart';
import 'package:smartexpense/widgets/time_range_selector.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  TimeRange _selectedRange = TimeRange.monthly;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartExpense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TimeRangeSelector(
              selectedRange: _selectedRange,
              onRangeChanged: (range) => setState(() => _selectedRange = range),
            ),
            BudgetIndicator(range: _selectedRange, selectedDate: _selectedDate),
            _buildExpenseList(),
            _buildExpenseChart(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseList() {
    return Consumer<ExpenseService>(
      builder: (context, expenseService, child) {
        return StreamBuilder<List<Expense>>(
          stream: expenseService.getExpensesStream(_selectedRange, _selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final expenses = snapshot.data ?? [];
            return Column(
              children: expenses.map((expense) => ExpenseCard(expense: expense)).toList(),
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseChart() {
    return Consumer<ExpenseService>(
      builder: (context, expenseService, child) {
        return StreamBuilder<List<Expense>>(
          stream: expenseService.getExpensesStream(_selectedRange, _selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading chart: ${snapshot.error}'));
            }
            return ExpenseCharts(
              expenses: snapshot.data ?? [],
              timeRange: _selectedRange,
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _navigateToAddExpense(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
  }
}