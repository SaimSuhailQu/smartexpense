import 'package:flutter/material.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/income_categorizer_service.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:intl/intl.dart';

class IncomeForm extends StatefulWidget {
  final Income? initialIncome;
  final Function(Income)? onSave;

  const IncomeForm({
    super.key,
    this.initialIncome,
    this.onSave,
  });

  @override
  State<IncomeForm> createState() => IncomeFormState();
}

class IncomeFormState extends State<IncomeForm> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late String _category;
  late DateTime _date;
  late String _currency;
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _title = widget.initialIncome?.title ?? '';
    _amount = widget.initialIncome?.amount ?? 0.0;
    _category = widget.initialIncome?.category ?? 'Salary';
    _date = widget.initialIncome?.date ?? DateTime.now();
    _currency = widget.initialIncome?.currency ?? 'PKR';
    _tags = widget.initialIncome?.tags ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final categorizer = context.watch<IncomeCategorizerService>();
    final categories = categorizer.categories.keys.toSet().toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!categories.contains(_category)) {
      _category = categories.contains('Other')
          ? 'Other'
          : (categories.isNotEmpty ? categories.first : 'Other');
    }

    final dropdownItems = [...categories, 'Add New Category...'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Where did this income come from?',
                prefixIcon: Icon(Icons.source_outlined),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please enter a title' : null,
              onChanged: (value) {
                _title = value.trim();
                final categorizer = context.read<IncomeCategorizerService>();
                final suggestedCategory = categorizer.categorizeIncome(_title);
                
                if (categorizer.shouldCreateNewCategory(_title)) {
                  final newCategoryName = categorizer.getSuggestedCategoryName(_title);
                  _promptCreateNewCategory(newCategoryName);
                } else if (categories.contains(suggestedCategory)) {
                  setState(() {
                    _category = suggestedCategory;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Consumer<CurrencyService>(
              builder: (context, currencyService, child) {
                return TextFormField(
                  initialValue: _amount != 0 ? _amount.toString() : '',
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                    suffixText: _currency,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter an amount';
                    final amount = double.tryParse(value);
                    if (amount == null) return 'Please enter a valid number';
                    if (amount <= 0) return 'Amount must be greater than zero';
                    return null;
                  },
                  onChanged: (value) {
                    final parsedValue = double.tryParse(value);
                    if (parsedValue != null) _amount = parsedValue;
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: dropdownItems
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value == 'Add New Category...') {
                        _showAddCategoryDialog();
                      } else if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                    ),
                    items: ['PKR', 'USD', 'EUR', 'GBP']
                        .map((currency) => DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _currency = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _tags.join(', '),
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'bonus, freelance, gift',
                prefixIcon: Icon(Icons.tag_outlined),
              ),
              onChanged: (value) {
                _tags = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              },
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null && pickedDate != _date) {
                  setState(() => _date = pickedDate);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withAlpha(isDark ? 50 : 20)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM dd, yyyy').format(_date),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_outlined, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: Colors.green,
                elevation: 8,
                shadowColor: Colors.green.withAlpha(50),
              ),
              child: const Text('SAVE INCOME', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _promptCreateNewCategory(String suggestedCategoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Category?'),
        content: Text('Would you like to create a new category "$suggestedCategoryName"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () {
              context.read<IncomeCategorizerService>().addCategory(suggestedCategoryName);
              setState(() {
                _category = suggestedCategoryName;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final newCategoryController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Category'),
        content: TextFormField(
          controller: newCategoryController,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () {
              final newCategory = newCategoryController.text.trim();
              if (newCategory.isNotEmpty) {
                context
                    .read<IncomeCategorizerService>()
                    .addCategory(newCategory);
                setState(() {
                  _category = newCategory;
                });
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        final income = Income(
          id: widget.initialIncome?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: _title,
          amount: _amount,
          date: _date,
          category: _category,
          currency: _currency,
          tags: _tags,
        );

        if (widget.onSave != null) {
          await widget.onSave!(income);
        } else {
          await Provider.of<IncomeService>(context, listen: false)
              .addIncome(income);
        }

        if (mounted) {
          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Income added successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              Navigator.of(context).pop(true);
            }
          });
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving income: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}