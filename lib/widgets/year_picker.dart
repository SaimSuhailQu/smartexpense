import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartexpense/theme/app_colors.dart';

class YearPicker extends StatefulWidget {
  final DateTime selectedYear;
  final Function(DateTime) onYearChanged;

  const YearPicker({
    super.key,
    required this.selectedYear,
    required this.onYearChanged,
  });

  @override
  State<YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<YearPicker> {
  late DateTime _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withAlpha(100) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () {
              setState(() {
                _selectedYear = DateTime(_selectedYear.year - 1);
                widget.onYearChanged(_selectedYear);
              });
            },
            splashRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              DateFormat('yyyy').format(_selectedYear),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () {
              setState(() {
                _selectedYear = DateTime(_selectedYear.year + 1);
                widget.onYearChanged(_selectedYear);
              });
            },
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
