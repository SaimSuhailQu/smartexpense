import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/budget.dart';
import 'package:smartexpense/services/budget_service.dart';
import 'package:smartexpense/services/categorizer_service.dart';
import 'package:intl/intl.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;

  const AddBudgetScreen({super.key, this.budget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _category;
  late double _amount;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final categories =
        context.read<CategorizerService>().categories.keys.toList();
    _category = widget.budget?.category ?? (categories.isNotEmpty ? categories.first : 'Other');
    _amount = widget.budget?.amount ?? 0.0;
    _startDate = widget.budget?.startDate ?? DateTime.now();
    _endDate = widget.budget?.endDate ??
        DateTime.now().add(const Duration(days: 30));
  }

  @override
  Widget build(BuildContext context) {
    final categorizer = context.watch<CategorizerService>();
    final categories = categorizer.categories.keys.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget == null ? 'Add Budget' : 'Edit Budget'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount != 0 ? _amount.toString() : '',
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
                onSaved: (value) {
                  _amount = double.tryParse(value!)!;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                        'Start Date: ${DateFormat.yMd().format(_startDate)}'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, isStartDate: true),
                    child: const Text('Select'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child:
                        Text('End Date: ${DateFormat.yMd().format(_endDate)}'),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context, isStartDate: false),
                    child: const Text('Select'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Save Budget'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isStartDate}) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = pickedDate;
        } else {
          _endDate = pickedDate;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final budget = Budget(
        id: widget.budget?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        category: _category,
        amount: _amount,
        startDate: _startDate,
        endDate: _endDate,
      );
      Provider.of<BudgetService>(context, listen: false).addBudget(budget);
      Navigator.pop(context);
    }
  }
}
