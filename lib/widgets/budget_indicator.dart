import 'package:flutter/material.dart' hide DateUtils;
import 'package:smartexpense/utils/date_utils.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:provider/provider.dart';

class BudgetIndicator extends StatelessWidget {
  final TimeRange range;
  final DateTime selectedDate;

  const BudgetIndicator({
    super.key,
    required this.range,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    DateUtils.getRangeDates(range, selectedDate);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget ${_getRangeTitle(range)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.65, // Example value - replace with actual budget calculation
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 8),
          Consumer<CurrencyService>(
            builder: (context, currencyService, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${currencyService.symbol}650', style: Theme.of(context).textTheme.bodySmall),
                  Text('${currencyService.symbol}1000', style: Theme.of(context).textTheme.bodySmall),
                ],
              );
            }
          ),
        ],
      ),
    );
  }

  String _getRangeTitle(TimeRange range) {
    switch (range) {
      case TimeRange.daily:
        return 'Today';
      case TimeRange.weekly:
        return 'This Week';
      case TimeRange.monthly:
        return 'This Month';
      case TimeRange.yearly:
        return 'This Year';
      case TimeRange.loans:
        return 'Loans';
      case TimeRange.categories:
        return 'Categories';
      case TimeRange.custom:
        return 'Custom Range';
    }

  }
}
