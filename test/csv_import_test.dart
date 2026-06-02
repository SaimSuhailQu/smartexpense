import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter_test/flutter_test.dart';

/// This is a simple test to verify CSV import functionality
class CsvImportTest {
  /// Create a test CSV file with sample data
  static Future<String> createTestCsvFile() async {
    const List<List<dynamic>> csvData = [
      ['Category', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21'],
      ['Charity', 1500, 3000, 300, 300, 500, 150, 1500, 100, '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Grocery', 14150, 400, 4800, 350, 1900, 1500, 1600, 3990, 760, 500, 650, 600, '', '', '', '', '', '', '', '', ''],
      ['Milk/Yougard', 700, 220, 180, 250, 160, 250, 550, 500, 1000, 250, '', '', '', '', '', '', '', '', '', '', ''],
      ['Fruits/Veg', 900, 1000, 300, 400, 1400, 300, 800, 850, 550, 500, 1500, '', '', '', '', '', '', '', '', '', ''],
      ['Bakery/Sweets', 500, 1000, 200, 500, 500, 500, 200, 500, 500, 400, 400, 200, 200, 1000, 500, 400, 400, 200, 500, 500, 500, 1200],
      ['Chicken/Meat', 750, 1000, 300, 1150, 1330, 1300, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Miscellinous', 400, 1300, 900, 1050, 200, 100, 50, 330, 300, 300, 1500, 1000, 350, 350, 300, 2000, 800, 1000, '', '', '', ''],
      ['Doctor/Med', 500, 920, 1000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Garm/Shoes', 3000, 700, 1000, 6000, 6000, 300, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Functions/Gifts', 200, 200, 500, 1000, 1000, 1000, 250, 500, '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Education Fee', 3500, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Carry/Bike', 200, 2400, 2000, 600, 6000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Traveling', 1000, 300, 1000, 1000, 1000, 1000, 300, 1000, '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Bills/Cards', 4180, 680, 1300, 1500, 100, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Committee', 24000, 10000, 8000, 40000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Salaries', 500, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Mother', 3000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Mrs', 1000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Shamikh', 2250, 1000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Zubair', 3000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Shoaib', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Malik SB.', 2000, 2000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Saim', 2000, 3050, 1000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Affan', 3000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Moiz', 10000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Baji SR.', 1000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Loans', 5000, 50000, 5000, 5000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Bashir Sweep', 5000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['House Cash', 3000, 8000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Payments', 5000, 7000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Saad', 500, 500, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
      ['Bkr case', 3000, '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''],
    ];

    final String csv = Csv().encode(csvData);
    final Directory tempDir = Directory.systemTemp;
    const String fileName = 'test_expenses.csv';
    final File file = File('${tempDir.path}/$fileName');
    
    await file.writeAsString(csv);
    return file.path;
  }

  /// Parse CSV data manually to verify import logic
  static Future<List<Map<String, dynamic>>> parseCsvFile(String filePath) async {
    final File file = File(filePath);
    final csvString = await file.readAsString();
    final List<List<dynamic>> data = Csv().decode(csvString);
    
    final List<Map<String, dynamic>> expenses = [];
    
    if (data.isEmpty) {
      return expenses;
    }

    // Skip header row
    for (var i = 1; i < data.length; i++) {
      final row = data[i];
      if (row.isEmpty || row.length < 2) continue;

      final category = row[0].toString().trim();
      if (category.isEmpty) continue;

      // Process amounts in columns 1, 2, 3, etc.
      for (var j = 1; j < row.length; j++) {
        final amountStr = row[j].toString();
        final amount = double.tryParse(amountStr) ?? 0.0;
        if (amount <= 0) continue;

        expenses.add({
          'category': category,
          'amount': amount,
          'day': j,
        });
      }
    }

    return expenses;
  }
}

void main() {
  test('Verify CSV import parsing logic', () async {
    final filePath = await CsvImportTest.createTestCsvFile();
    final parsedExpenses = await CsvImportTest.parseCsvFile(filePath);

    expect(parsedExpenses, isNotEmpty);
    expect(parsedExpenses[0]['category'], equals('Charity'));
    expect(parsedExpenses[0]['amount'], equals(1500.0));
    expect(parsedExpenses[0]['day'], equals(1));

    // Cleanup
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  });
}
