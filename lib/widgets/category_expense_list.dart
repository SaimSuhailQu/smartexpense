import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/currency_service.dart';

class CategoryExpenseList extends StatelessWidget {
  final Map<String, double> categoryData;

  const CategoryExpenseList({
    super.key,
    required this.categoryData,
  });

  Widget _buildCategoryListItem(BuildContext context, MapEntry<String, double> categoryEntry, int index, double total) {
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final theme = Theme.of(context);
    final categoryName = categoryEntry.key;
    final amount = categoryEntry.value;
    final percentage = total > 0 ? (amount / total) : 0.0;
    final color = kPalette[index % kPalette.length];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryName,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$categoryName: ${currencyService.formatAmount(amount)}'),
                  backgroundColor: color,
                ),
              );
            },
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: theme.scaffoldBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = categoryData.values.fold(0.0, (a, b) => a + b);

    // Estimated height for one item.
    const double itemHeight = 68.0;
    final double containerHeight = sortedEntries.length > 5 ? itemHeight * 5 : (sortedEntries.isEmpty ? 0 : itemHeight * sortedEntries.length);


    return SizedBox(
      height: containerHeight,
      child: ListView.builder(
        itemCount: sortedEntries.length,
        itemBuilder: (context, index) {
          return _buildCategoryListItem(context, sortedEntries[index], index, total);
        },
      ),
    );
  }

  static const List<Color> kPalette = [
    Color(0xFF8A2BE2), // Purple
    Color(0xFFFFA500), // Orange
    Color(0xFF32CD32), // LimeGreen
    Colors.cyan,
    Colors.pink,
    Colors.red,
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];
}
