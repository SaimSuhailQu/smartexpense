import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/services/currency_service.dart';

class FlCircularExpenseChart extends StatefulWidget {
  final Map<String, double> categoryData;
  final double total;

  const FlCircularExpenseChart({
    super.key,
    required this.categoryData,
    required this.total,
  });

  @override
  State<FlCircularExpenseChart> createState() => _FlCircularExpenseChartState();
}

class _FlCircularExpenseChartState extends State<FlCircularExpenseChart> {
  int touchedIndex = -1;
  MapEntry<String, double>? touchedEntry;

  @override
  Widget build(BuildContext context) {
    final sortedEntries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top9 = sortedEntries.take(9).toList();
    final othersSum = sortedEntries.skip(9).fold(0.0, (sum, entry) => sum + entry.value);
    final chartData = [...top9];
    if (othersSum > 0) {
      chartData.add(MapEntry('Others', othersSum));
    }

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (event is FlLongPressStart || event is FlTapDownEvent) {
                      if (pieTouchResponse != null &&
                          pieTouchResponse.touchedSection != null) {
                        touchedIndex =
                            pieTouchResponse.touchedSection!.touchedSectionIndex;
                        if (touchedIndex != -1) {
                          touchedEntry = chartData[touchedIndex];
                        }
                      }
                    } else if (event is FlLongPressEnd || event is FlTapUpEvent) {
                      touchedIndex = -1;
                      touchedEntry = null;
                    }
                  });
                },
              ),
              borderData: FlBorderData(
                show: false,
              ),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: showingSections(chartData),
            ),
          ),
          _buildCenterContent(),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyService = Provider.of<CurrencyService>(context, listen: false);
    
    if (touchedIndex == -1 || touchedEntry == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Total',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currencyService.formatAmount(widget.total),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          touchedEntry!.key,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          currencyService.formatAmount(touchedEntry!.value),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> showingSections(List<MapEntry<String, double>> chartData) {
    return List.generate(chartData.length, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      final color = _palette[i % _palette.length];

      final entry = chartData[i];
      final percentage = widget.total > 0 ? (entry.value / widget.total) * 100 : 0.0;

      return PieChartSectionData(
        color: color,
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: _Badge(
          name: entry.key,
          color: color,
          isSelected: isTouched,
        ),
        badgePositionPercentageOffset: 1.1,
      );
    });
  }

  static const List<Color> _palette = [
    Color(0xFF8A2BE2), // Purple
    Color(0xFFFFA500), // Orange
    Color(0xFF32CD32), // LimeGreen
    Colors.cyan,
    Colors.pink,
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.green,
    Colors.teal,
  ];
}

class _Badge extends StatelessWidget {
  final String name;
  final Color color;
  final bool isSelected;

  const _Badge({
    required this.name,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withAlpha(128),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 3,
            offset: const Offset(1, 1),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_right_alt, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
