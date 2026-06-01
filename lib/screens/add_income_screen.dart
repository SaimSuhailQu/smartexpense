import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/widgets/income_form.dart';

class AddIncomeScreen extends StatelessWidget {
  const AddIncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Income')),
      body: IncomeForm(
        onSave: (income) {
          Provider.of<IncomeService>(context, listen: false).addIncome(income);
          Navigator.pop(context);
        },
      ),
    );
  }
}
