import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/categorizer_service.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

class CsvService {
  final CategorizerService _categorizerService;

  CsvService(this._categorizerService);

  /// Export expenses to CSV format
  Future<void> exportToCsv(List<Expense> expenses, {String? customFileName}) async {
    try {
      final List<List<dynamic>> csvData = [
        ['Title', 'Amount', 'Date', 'Category', 'Notes'],
        ...expenses.map((e) => [
          e.title,
          e.amount,
          DateFormat('yyyy-MM-dd').format(e.date),
          e.category,
          e.notes ?? ''
        ])
      ];

      final String csv = Csv().encode(csvData);
      final String path = (await getDownloadsDirectory())!.path;
      final String fileName = customFileName ?? 'expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final File file = File('$path/$fileName');
      
      await file.writeAsString(csv);
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to export to CSV: $e');
    }
  }

  /// Export expenses for a specific month
  Future<void> exportMonthlyToCsv(List<Expense> expenses, DateTime month) async {
    try {
      final monthName = DateFormat('MMMM_yyyy').format(month);
      final fileName = 'expenses_$monthName.csv';
      await exportToCsv(expenses, customFileName: fileName);
    } catch (e) {
      throw Exception('Failed to export monthly data: $e');
    }
  }

  /// Export expenses for a specific year
  Future<void> exportYearlyToCsv(List<Expense> expenses, int year) async {
    try {
      final fileName = 'expenses_$year.csv';
      await exportToCsv(expenses, customFileName: fileName);
    } catch (e) {
      throw Exception('Failed to export yearly data: $e');
    }
  }

  /// Import expenses from CSV format, supporting the user-specified multi-column format.
  Future<List<Expense>> importFromCsv() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return []; // User cancelled the picker, return empty list.
      }

      final fileName = result.files.single.name;
      final importDate = _parseDateFromFileName(fileName);

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final csvString = await file.readAsString();
      final List<List<dynamic>> data = Csv().decode(csvString);
      
      final expenses = <Expense>[];
      if (data.isEmpty) {
        return expenses;
      }

      // Skip header row if it exists
      final startIndex = _hasHeaderRow(data) ? 1 : 0;
    
      for (var i = startIndex; i < data.length; i++) {
        final row = data[i];
        if (row.isEmpty || row.length < 2) continue;

        try {
          // Handle the format: Category, Amount1, Amount2, Amount3, ...
          final category = row[0].toString().trim();
          if (category.isEmpty) continue;

          // Create category if it doesn't exist
          if (!_categorizerService.categories.containsKey(category)) {
            _categorizerService.addCategory(category);
          }

          // Process amounts in columns 1, 2, 3, etc.
          for (var j = 1; j < row.length; j++) {
            final amount = _parseAmount(row[j].toString());
            if (amount <= 0) continue;

            final DateTime expenseDate;
            if (importDate != null) {
              final daysInMonth = DateTime(importDate.year, importDate.month + 1, 0).day;
              final day = j <= daysInMonth ? j : daysInMonth;
              expenseDate = DateTime(importDate.year, importDate.month, day);
            } else {
              expenseDate = DateTime.now().subtract(Duration(days: j - 1));
            }

            expenses.add(Expense(
              id: DateTime.now().millisecondsSinceEpoch.toString() + expenses.length.toString(),
              title: '$category Expense $j',
              amount: amount,
              date: expenseDate,
              category: category,
              notes: 'Imported from CSV',
            ));
          }
        } catch (e) {
          continue;
        }
      }

      return expenses;
    } catch (e) {
      throw Exception('Failed to import from CSV: $e');
    }
  }






  /// Import expenses from custom format (as described by user)
  Future<List<Expense>> importFromCustomFormat(List<List<dynamic>> data) async {
    final expenses = <Expense>[];
    
    // Skip header row if it exists
    final startIndex = _hasHeaderRow(data) ? 1 : 0;
    
    for (var i = startIndex; i < data.length; i++) {
      final row = data[i];
      if (row.isEmpty || row.length < 2) continue;

      try {
        // Handle the format: Category, Amount1, Amount2, Amount3, ...
        final category = row[0].toString().trim();
        if (category.isEmpty) continue;

        // Create category if it doesn't exist
        if (!_categorizerService.categories.containsKey(category)) {
          _categorizerService.addCategory(category);
        }

        // Process amounts in columns 1, 2, 3, etc.
        for (var j = 1; j < row.length; j++) {
          final amount = _parseAmount(row[j].toString());
          if (amount <= 0) continue;

          expenses.add(Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString() + expenses.length.toString(),
            title: '$category Expense $j',
            amount: amount,
            date: DateTime.now().subtract(Duration(days: j - 1)), // Spread across recent days
            category: category,
            notes: 'Imported from CSV',
          ));
        }
      } catch (e) {
        continue;
      }
    }

    return expenses;
  }

  /// Create sample CSV template
  Future<void> createSampleTemplate() async {
    try {
      final List<List<dynamic>> csvData = [
        ['Title', 'Amount', 'Date', 'Category', 'Notes'],
        ['Grocery Shopping', 150.50, '2024-01-15', 'Groceries', 'Weekly shopping'],
        ['Movie Tickets', 25.00, '2024-01-14', 'Entertainment', 'Weekend movie'],
        ['Gas', 45.00, '2024-01-13', 'Transport', 'Fuel fill-up'],
        ['Charity Donation', 100.00, '2024-01-12', 'Charity', 'Monthly donation'],
        ['Restaurant', 60.00, '2024-01-11', 'Food', 'Dinner with friends'],
      ];

      final String csv = Csv().encode(csvData);
      final String path = (await getDownloadsDirectory())!.path;
      const String fileName = 'expense_template.csv';
      final File file = File('$path/$fileName');
      
      await file.writeAsString(csv);
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to create template: $e');
    }
  }

  /// Create custom format template
  Future<void> createCustomFormatTemplate() async {
    try {
      final List<List<dynamic>> csvData = [
        ['Category', 'Amount1', 'Amount2', 'Amount3', 'Amount4'],
        ['Charity', 1000, 500, 750, 200],
        ['Food', 200, 150, 300, 100],
        ['Transport', 50, 75, 100, 25],
        ['Shopping', 500, 300, 400, 600],
        ['Utilities', 200, 200, 250, 180],
        ['Entertainment', 100, 150, 80, 120],
      ];

      final String csv = Csv().encode(csvData);
      final String path = (await getDownloadsDirectory())!.path;
      const String fileName = 'custom_format_template.csv';
      final File file = File('$path/$fileName');
      
      await file.writeAsString(csv);
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to create custom template: $e');
    }
  }

  /// Create a sample CSV file that matches the format from the user's image
  Future<void> createSampleFromUserImage() async {
    try {
      final List<List<dynamic>> csvData = [
        ['Category', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31'],
        ['Food', 200, 150, 300, 100, 180, 220, 175, 250, 190, 210, 180, 240, 160, 200, 220, 180, 190, 230, 170, 210, 195, 225, 185, 205, 175, 195, 215, 185, 200, 190, 210],
        ['Transport', 50, 75, 100, 25, 60, 80, 45, 70, 55, 65, 50, 85, 40, 60, 75, 50, 55, 80, 45, 65, 58, 78, 52, 68, 48, 58, 72, 52, 60, 55, 65],
        ['Shopping', 500, 300, 400, 600, 350, 450, 550, 320, 380, 420, 360, 480, 340, 390, 440, 370, 385, 460, 330, 410, 395, 475, 355, 425, 345, 385, 435, 365, 400, 380, 420],
        ['Utilities', 200, 200, 250, 180, 220, 240, 210, 230, 190, 210, 200, 240, 180, 210, 230, 200, 205, 235, 185, 215, 210, 240, 195, 225, 190, 210, 230, 195, 215, 205, 225],
        ['Entertainment', 100, 150, 80, 120, 90, 130, 110, 140, 100, 120, 110, 160, 90, 110, 130, 100, 105, 135, 95, 125, 115, 145, 105, 125, 95, 115, 135, 105, 120, 110, 130],
        ['Charity', 1000, 500, 750, 200, 600, 800, 550, 700, 500, 650, 580, 780, 520, 620, 720, 580, 630, 730, 530, 670, 640, 760, 560, 660, 540, 680, 740, 540, 650, 590, 710],
      ];

      final String csv = Csv().encode(csvData);
      final String path = (await getDownloadsDirectory())!.path;
      const String fileName = 'sample_user_format.csv';
      final File file = File('$path/$fileName');
      
      await file.writeAsString(csv);
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to create sample from user image: $e');
    }
  }

  /// Helper method to check if first row is a header
  bool _hasHeaderRow(List<List<dynamic>> data) {
    if (data.isEmpty) return false;
    
    final firstRow = data[0];
    if (firstRow.isEmpty) return false;
    
    // Check if first cell contains common header words
    final firstCell = firstRow[0].toString().toLowerCase();
    return firstCell.contains('category') || 
           firstCell.contains('title') || 
           firstCell.contains('name');
  }

  /// Helper method to parse amount from various formats
  double _parseAmount(String value) {
    if (value.isEmpty) return 0.0;
    
    try {
      // Remove currency symbols and spaces
      final cleanValue = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
      return double.parse(cleanValue);
    } catch (e) {
      return 0.0;
    }
  }

  /// Helper method to parse date from filename (e.g., "july 2025.csv")
  DateTime? _parseDateFromFileName(String fileName) {
    try {
      final nameWithoutExt = fileName.toLowerCase().replaceAll('.csv', '').trim();
      final parts = nameWithoutExt.split(' ');
      if (parts.length < 2) return null;

      final yearPart = parts.firstWhere((p) => p.length == 4 && int.tryParse(p) != null, orElse: () => '');
      if (yearPart.isEmpty) return null;
      final year = int.parse(yearPart);

      final monthPart = parts.firstWhere((p) => p != yearPart, orElse: () => '');
      if (monthPart.isEmpty) return null;

      const monthMap = {
        'january': 1, 'jan': 1,
        'february': 2, 'feb': 2,
        'march': 3, 'mar': 3,
        'april': 4, 'apr': 4,
        'may': 5,
        'june': 6, 'jun': 6,
        'july': 7, 'jul': 7,
        'august': 8, 'aug': 8,
        'september': 9, 'sep': 9,
        'october': 10, 'oct': 10,
        'november': 11, 'nov': 11,
        'december': 12, 'dec': 12,
      };

      final month = monthMap[monthPart];
      if (month == null) return null;

      return DateTime(year, month);
    } catch (e) {
      return null;
    }
  }
}
