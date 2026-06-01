import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/recurring_transaction.dart';
import 'package:smartexpense/services/recurring_transaction_service.dart';
import 'package:smartexpense/services/categorizer_service.dart';
import 'package:intl/intl.dart';

class AddRecurringTransactionScreen extends StatefulWidget {
  final RecurringTransaction? recurringTransaction;

  const AddRecurringTransactionScreen({super.key, this.recurringTransaction});

  @override
  State<AddRecurringTransactionScreen> createState() =>
      _AddRecurringTransactionScreenState();
}

class _AddRecurringTransactionScreenState
    extends State<AddRecurringTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late String _category;
  late String _type;
  late Frequency _frequency;
  late DateTime _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final categories =
        context.read<CategorizerService>().categories.keys.toList();
    _title = widget.recurringTransaction?.title ?? '';
    _amount = widget.recurringTransaction?.amount ?? 0.0;
    _category = widget.recurringTransaction?.category ??
        (categories.isNotEmpty ? categories.first : 'Other');
    _type = widget.recurringTransaction?.type ?? 'expense';
    _frequency = widget.recurringTransaction?.frequency ?? Frequency.monthly;
    _startDate = widget.recurringTransaction?.startDate ?? DateTime.now();
    _endDate = widget.recurringTransaction?.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final categorizer = context.watch<CategorizerService>();
    final categories = categorizer.categories.keys.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recurringTransaction == null
            ? 'Add Recurring Transaction'
            : 'Edit Recurring Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                initialValue: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter a title' : null,
                onSaved: (value) {
                  _title = value!;
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
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: ['expense', 'income']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _type = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Frequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  border: OutlineInputBorder(),
                ),
                items: Frequency.values
                    .map((frequency) => DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _frequency = value;
                    });
                  }
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
                    child: Text(
                        'End Date: ${_endDate != null ? DateFormat.yMd().format(_endDate!) : 'None'}'),
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
                child: const Text('Save'),
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
      initialDate: isStartDate
          ? _startDate
          : (_endDate ?? DateTime.now().add(const Duration(days: 365))),
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
      final recurringTransaction = RecurringTransaction(
        id: widget.recurringTransaction?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        amount: _amount,
        category: _category,
        type: _type,
        frequency: _frequency,
        startDate: _startDate,
        endDate: _endDate,
        nextOccurrenceDate: _startDate,
      );
      Provider.of<RecurringTransactionService>(context, listen: false)
          .addRecurringTransaction(recurringTransaction);
      Navigator.pop(context);
    }
  }
}
