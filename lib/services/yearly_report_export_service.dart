import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';

// ─── Internal data models ────────────────────────────────────────────────────

class _CategoryEntry {
  final String category;
  final double amount;
  final int count;

  const _CategoryEntry({
    required this.category,
    required this.amount,
    required this.count,
  });
}

class _MonthlyEntry {
  final String monthName;
  final double income;
  final double expenses;

  const _MonthlyEntry({
    required this.monthName,
    required this.income,
    required this.expenses,
  });
}

// ─── Service ─────────────────────────────────────────────────────────────────

/// Handles exporting the yearly categories chart data as PDF or CSV.
class YearlyReportExportService {
  // Colour palette mirrors the one in enhanced_yearly_charts_fixed.dart
  static const List<PdfColor> _categoryColors = [
    PdfColor.fromInt(0xFF1E88E5), // blue
    PdfColor.fromInt(0xFF43A047), // green
    PdfColor.fromInt(0xFFFB8C00), // orange
    PdfColor.fromInt(0xFF8E24AA), // purple
    PdfColor.fromInt(0xFFE53935), // red
    PdfColor.fromInt(0xFF00897B), // teal
    PdfColor.fromInt(0xFF3949AB), // indigo
    PdfColor.fromInt(0xFFFFB300), // amber
    PdfColor.fromInt(0xFFE91E63), // pink
    PdfColor.fromInt(0xFF00ACC1), // cyan
  ];

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Generates a PDF report and opens the system share/print dialog.
  Future<void> exportYearlyReportAsPdf({
    required List<Expense> expenses,
    required List<Income> incomes,
    required int year,
    required String currencySymbol,
  }) async {
    final categoryData = _buildCategoryData(expenses);
    final monthlyData = _buildMonthlyData(expenses, incomes, year);
    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
    final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);
    final netSavings = totalIncome - totalExpenses;

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _buildHeader(year),
        footer: (ctx) => _buildFooter(ctx),
        build: (_) => [
          _buildSummarySection(
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netSavings: netSavings,
            sym: currencySymbol,
          ),
          pw.SizedBox(height: 24),
          _buildCategorySection(
            data: categoryData,
            totalExpenses: totalExpenses,
            sym: currencySymbol,
          ),
          pw.SizedBox(height: 24),
          _buildMonthlySection(data: monthlyData, sym: currencySymbol),
          pw.SizedBox(height: 24),
          _buildTransactionsSection(expenses: expenses, sym: currencySymbol),
        ],
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'SmartExpense_Report_$year.pdf',
    );
  }

  /// Generates a comprehensive CSV file and opens it.
  Future<void> exportYearlyReportAsCsv({
    required List<Expense> expenses,
    required List<Income> incomes,
    required int year,
    required String currencySymbol,
  }) async {
    final categoryData = _buildCategoryData(expenses);
    final monthlyData = _buildMonthlyData(expenses, incomes, year);
    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
    final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);
    final netSavings = totalIncome - totalExpenses;

    final rows = <List<dynamic>>[];

    // ── Summary block ──────────────────────────────────────────────────────
    rows.addAll([
      ['SMARTEXPENSE – YEARLY FINANCIAL REPORT'],
      ['Year', year.toString()],
      ['Generated', DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())],
      [],
      ['--- SUMMARY ---'],
      ['Metric', 'Amount'],
      ['Total Income', '$currencySymbol ${totalIncome.toStringAsFixed(2)}'],
      [
        'Total Expenses',
        '$currencySymbol ${totalExpenses.toStringAsFixed(2)}'
      ],
      ['Net Savings', '$currencySymbol ${netSavings.toStringAsFixed(2)}'],
      [
        'Savings Rate',
        totalIncome > 0
            ? '${(netSavings / totalIncome * 100).toStringAsFixed(1)}%'
            : '0.0%',
      ],
      [],
    ]);

    // ── Category breakdown ─────────────────────────────────────────────────
    rows.addAll([
      ['--- CATEGORY BREAKDOWN ---'],
      ['Rank', 'Category', 'Total Amount', '% of Expenses', 'No. Transactions'],
    ]);
    for (int i = 0; i < categoryData.length; i++) {
      final item = categoryData[i];
      final pct = totalExpenses > 0
          ? '${(item.amount / totalExpenses * 100).toStringAsFixed(1)}%'
          : '0.0%';
      rows.add([
        i + 1,
        item.category,
        '$currencySymbol ${item.amount.toStringAsFixed(2)}',
        pct,
        item.count,
      ]);
    }
    rows.add([]);

    // ── Monthly cash flow ──────────────────────────────────────────────────
    rows.addAll([
      ['--- MONTHLY CASH FLOW ---'],
      ['Month', 'Income', 'Expenses', 'Savings', 'Savings Rate'],
    ]);
    for (final m in monthlyData) {
      final savings = m.income - m.expenses;
      final rate = m.income > 0
          ? '${(savings / m.income * 100).toStringAsFixed(1)}%'
          : '-';
      rows.add([
        m.monthName,
        '$currencySymbol ${m.income.toStringAsFixed(2)}',
        '$currencySymbol ${m.expenses.toStringAsFixed(2)}',
        '$currencySymbol ${savings.toStringAsFixed(2)}',
        rate,
      ]);
    }
    rows.add([]);

    // ── Expense transactions ───────────────────────────────────────────────
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    rows.addAll([
      ['--- EXPENSE TRANSACTIONS (${sorted.length}) ---'],
      ['Date', 'Title', 'Category', 'Amount', 'Notes'],
    ]);
    for (final e in sorted) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(e.date),
        e.title,
        e.category,
        '$currencySymbol ${e.amount.toStringAsFixed(2)}',
        e.notes ?? '',
      ]);
    }

    final csv = Csv().encode(rows);
    final dir = await getDownloadsDirectory();
    final file = File('${dir!.path}/SmartExpense_Report_$year.csv');
    await file.writeAsString(csv);
    await OpenFile.open(file.path);
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────

  List<_CategoryEntry> _buildCategoryData(List<Expense> expenses) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final e in expenses) {
      totals.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
      counts.update(e.category, (v) => v + 1, ifAbsent: () => 1);
    }
    return totals.entries
        .map((entry) => _CategoryEntry(
              category: entry.key,
              amount: entry.value,
              count: counts[entry.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<_MonthlyEntry> _buildMonthlyData(
    List<Expense> expenses,
    List<Income> incomes,
    int year,
  ) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return List.generate(12, (i) {
      final month = i + 1;
      return _MonthlyEntry(
        monthName: monthNames[i],
        income: incomes
            .where((inc) => inc.date.year == year && inc.date.month == month)
            .fold<double>(0, (s, inc) => s + inc.amount),
        expenses: expenses
            .where((e) => e.date.year == year && e.date.month == month)
            .fold<double>(0, (s, e) => s + e.amount),
      );
    });
  }

  // ─── PDF widget builders ──────────────────────────────────────────────────

  pw.Widget _buildHeader(int year) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.indigo200, width: 1.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SmartExpense',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo700,
                ),
              ),
              pw.Text(
                'Yearly Financial Report – $year',
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.blueGrey600,
                ),
              ),
            ],
          ),
          pw.Text(
            DateFormat('dd MMM yyyy').format(DateTime.now()),
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.blueGrey400,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.blueGrey100, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}  ·  SmartExpense',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.blueGrey400),
      ),
    );
  }

  pw.Widget _buildSummarySection({
    required double totalIncome,
    required double totalExpenses,
    required double netSavings,
    required String sym,
  }) {
    final rate = totalIncome > 0
        ? '${(netSavings / totalIncome * 100).toStringAsFixed(1)}%'
        : '0.0%';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Financial Summary'),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _summaryCard('Total Income', '$sym ${totalIncome.toStringAsFixed(2)}',
                PdfColors.green700),
            pw.SizedBox(width: 10),
            _summaryCard('Total Expenses',
                '$sym ${totalExpenses.toStringAsFixed(2)}', PdfColors.red700),
            pw.SizedBox(width: 10),
            _summaryCard(
              'Net Savings',
              '$sym ${netSavings.toStringAsFixed(2)}',
              netSavings >= 0 ? PdfColors.blue700 : PdfColors.orange700,
            ),
            pw.SizedBox(width: 10),
            _summaryCard('Savings Rate', rate, PdfColors.purple700),
          ],
        ),
      ],
    );
  }

  pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: PdfColors.blueGrey100),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                  fontSize: 7.5, color: PdfColors.blueGrey500),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCategorySection({
    required List<_CategoryEntry> data,
    required double totalExpenses,
    required String sym,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Category Breakdown (${data.length} categories)'),
        pw.SizedBox(height: 8),
        pw.Table(
          border:
              pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(28),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FixedColumnWidth(50),
            5: const pw.FlexColumnWidth(2.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              children: [
                _th('#'),
                _th('Category'),
                _th('Amount'),
                _th('% Total'),
                _th('Count'),
                _th('Share'),
              ],
            ),
            ...data.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final pct =
                  totalExpenses > 0 ? item.amount / totalExpenses : 0.0;
              final color =
                  _categoryColors[i % _categoryColors.length];
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i.isEven ? PdfColors.grey50 : PdfColors.white,
                ),
                children: [
                  _td('${i + 1}', align: pw.TextAlign.center),
                  _tdWithDot(item.category, color),
                  _td('$sym ${item.amount.toStringAsFixed(2)}', bold: true),
                  _td('${(pct * 100).toStringAsFixed(1)}%'),
                  _td('${item.count}', align: pw.TextAlign.center),
                  _progressBar(pct, color),
                ],
              );
            }),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
              children: [
                _td(''),
                _td('TOTAL', bold: true),
                _td('$sym ${totalExpenses.toStringAsFixed(2)}', bold: true),
                _td('100%', bold: true),
                _td(
                  '${data.fold(0, (s, e) => s + e.count)}',
                  bold: true,
                  align: pw.TextAlign.center,
                ),
                _td(''),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMonthlySection({
    required List<_MonthlyEntry> data,
    required String sym,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Monthly Cash Flow'),
        pw.SizedBox(height: 8),
        pw.Table(
          border:
              pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              children: [
                _th('Month'),
                _th('Income'),
                _th('Expenses'),
                _th('Savings'),
                _th('Rate'),
              ],
            ),
            ...data.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              final savings = m.income - m.expenses;
              final rate = m.income > 0
                  ? '${(savings / m.income * 100).toStringAsFixed(1)}%'
                  : '-';
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i.isEven ? PdfColors.grey50 : PdfColors.white,
                ),
                children: [
                  _td(m.monthName),
                  _td('$sym ${m.income.toStringAsFixed(2)}',
                      color: PdfColors.green700),
                  _td('$sym ${m.expenses.toStringAsFixed(2)}',
                      color: PdfColors.red700),
                  _td(
                    '$sym ${savings.toStringAsFixed(2)}',
                    bold: true,
                    color: savings >= 0 ? PdfColors.blue700 : PdfColors.orange700,
                  ),
                  _td(rate,
                      color: savings >= 0
                          ? PdfColors.green700
                          : PdfColors.red700),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTransactionsSection({
    required List<Expense> expenses,
    required String sym,
  }) {
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Expense Transactions (${sorted.length})'),
        pw.SizedBox(height: 8),
        pw.Table(
          border:
              pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo700),
              children: [
                _th('Date'),
                _th('Title'),
                _th('Category'),
                _th('Amount'),
                _th('Notes'),
              ],
            ),
            ...sorted.asMap().entries.map((entry) {
              final i = entry.key;
              final e = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: i.isEven ? PdfColors.grey50 : PdfColors.white,
                ),
                children: [
                  _td(DateFormat('yyyy-MM-dd').format(e.date)),
                  _td(e.title),
                  _td(e.category),
                  _td('$sym ${e.amount.toStringAsFixed(2)}',
                      bold: true, color: PdfColors.red700),
                  _td(e.notes ?? '', color: PdfColors.blueGrey500),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // ─── PDF primitive helpers ────────────────────────────────────────────────

  pw.Widget _sectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo700,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _td(
    String text, {
    bool bold = false,
    PdfColor? color,
    pw.TextAlign? align,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : null,
          color: color ?? PdfColors.grey800,
        ),
      ),
    );
  }

  pw.Widget _tdWithDot(String text, PdfColor dotColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Row(
        children: [
          pw.Container(
            width: 7,
            height: 7,
            decoration: pw.BoxDecoration(
              color: dotColor,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _progressBar(double fraction, PdfColor color) {
    final clampedFraction = fraction.clamp(0.0, 1.0);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.LayoutBuilder(
        builder: (context, constraints) {
          final barWidth =
              (constraints?.maxWidth ?? 80) * clampedFraction;
          return pw.Stack(
            children: [
              pw.Container(
                height: 7,
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(3.5),
                ),
              ),
              pw.Container(
                width: barWidth,
                height: 7,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(3.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
