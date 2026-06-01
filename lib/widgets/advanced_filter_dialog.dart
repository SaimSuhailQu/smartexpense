import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:smartexpense/services/categorizer_service.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/theme/app_colors.dart';
import 'package:intl/intl.dart';

class AdvancedFilterDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilter;

  const AdvancedFilterDialog({super.key, required this.onApplyFilter});

  @override
  State<AdvancedFilterDialog> createState() => _AdvancedFilterDialogState();
}

class _AdvancedFilterDialogState extends State<AdvancedFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedCategories = [];
  double? _minAmount;
  double? _maxAmount;
  final List<String> _tags = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categorizer = context.watch<CategorizerService>();
    final categories = categorizer.categories.keys.toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E293B).withAlpha(204) 
                  : Colors.white.withAlpha(217),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withAlpha(20) 
                    : Colors.black.withAlpha(13),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Advanced Filters',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle(theme, 'Date Range'),
                    const SizedBox(height: 12),
                    _buildDateRow(context, 'Start Date', _startDate, (date) => setState(() => _startDate = date)),
                    const SizedBox(height: 12),
                    _buildDateRow(context, 'End Date', _endDate, (date) => setState(() => _endDate = date)),
                    const Divider(height: 40),
                    _buildSectionTitle(theme, 'Categories'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: categories.map((category) {
                        final isSelected = _selectedCategories.contains(category);
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withAlpha(50),
                          checkmarkColor: AppColors.primary,
                        );
                      }).toList(),
                    ),
                    const Divider(height: 40),
                    _buildSectionTitle(theme, 'Amount Range'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Min', 
                              prefixIcon: Icon(Icons.remove, size: 16)
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _minAmount = double.tryParse(value),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Max', 
                              prefixIcon: Icon(Icons.add, size: 16)
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _maxAmount = double.tryParse(value),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 40),
                    _buildSectionTitle(theme, 'Tags'),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        prefixIcon: Icon(Icons.tag_outlined),
                        hintText: 'travel, food, work',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _tags.clear();
                          _tags.addAll(value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('CANCEL'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            widget.onApplyFilter({
                              'startDate': _startDate,
                              'endDate': _endDate,
                              'categories': _selectedCategories,
                              'minAmount': _minAmount,
                              'maxAmount': _maxAmount,
                              'tags': _tags,
                            });
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('APPLY FILTERS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildDateRow(BuildContext context, String label, DateTime? date, Function(DateTime) onSelect) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selectedDate != null) onSelect(selectedDate);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withAlpha(50)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: isDark ? Colors.white70 : Colors.black54),
            const SizedBox(width: 12),
            Text(
              date != null ? DateFormat('MMM dd, yyyy').format(date) : label,
              style: TextStyle(
                color: date != null ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54),
              ),
            ),
            const Spacer(),
            Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
