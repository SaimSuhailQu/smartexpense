import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CircularExpenseChart extends StatelessWidget {
  final Map<String, double> categoryData;
  final double total;

  const CircularExpenseChart({
    super.key,
    required this.categoryData,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 9 categories and group the rest into "Others"
    final top9 = sortedEntries.take(9).toList();
    final othersSum = sortedEntries.skip(9).fold(0.0, (sum, entry) => sum + entry.value);
    final chartData = [...top9];
    if (othersSum > 0) {
      chartData.add(MapEntry('Others', othersSum));
    }

    return SizedBox(
      height: 140,
      width: 140,
      child: SfCircularChart(
        backgroundColor: Colors.transparent,
        series: <CircularSeries>[
          RadialBarSeries<MapEntry<String, double>, String>(
            dataSource: chartData,
            xValueMapper: (data, _) => data.key,
            yValueMapper: (data, _) => data.value,
            pointColorMapper: (data, index) => _palette[index % _palette.length],
            trackOpacity: 0.2,
            useSeriesColor: true,
            cornerStyle: CornerStyle.bothCurve,
            gap: '3%',
            radius: '100%',
            innerRadius: '65%',
            maximumValue: total,
            onPointTap: (ChartPointDetails details) {
              final index = details.pointIndex;
              if (index != null && index < chartData.length) {
                final entry = chartData[index];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${entry.key}: RS ${entry.value.toStringAsFixed(2)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            enableTooltip: true,
          )
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          format: 'point.x: point.y',
        ),
        annotations: <CircularChartAnnotation>[
          CircularChartAnnotation(
            widget: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currencyService.formatAmount(total),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                )
              ],
            )
          )
        ],
      ),
    );
  }

  static const List<Color> _palette = [
    Color(0xFF8A2BE2), // Purple
    Color(0xFFFFA500), // Orange
    Color(0xFF32CD32), // LimeGreen
    Colors.cyan,
    Colors.pink,
  ];
}
