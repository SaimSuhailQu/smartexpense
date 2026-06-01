import 'package:flutter/material.dart';
import 'package:smartexpense/utils/date_utils.dart' show TimeRange;
import 'package:smartexpense/theme/app_colors.dart';

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onRangeChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withAlpha(100) : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTimeRangeButton(context, TimeRange.daily, 'Day'),
          _buildTimeRangeButton(context, TimeRange.weekly, 'Week'),
          _buildTimeRangeButton(context, TimeRange.monthly, 'Month'),
          _buildTimeRangeButton(context, TimeRange.yearly, 'Year'),
        ],
      ),
    );
  }

  Widget _buildTimeRangeButton(BuildContext context, TimeRange range, String label) {
    final isSelected = selectedRange == range;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => onRangeChanged(range),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? AppColors.primary : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && !isDark ? [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected 
                ? (isDark ? Colors.white : AppColors.primary) 
                : (isDark ? Colors.white54 : Colors.black54),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
