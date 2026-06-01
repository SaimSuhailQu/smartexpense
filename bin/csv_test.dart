import 'dart:io';
import 'package:logger/logger.dart';
import '../test/csv_import_test.dart';

void main() async {
  final logger = Logger();
  
  logger.i('CSV Import Test');
  logger.i('===============');
  
  try {
    // Create test CSV file
    final filePath = await CsvImportTest.createTestCsvFile();
    logger.i('Created test CSV file at: $filePath');
    
    // Parse and display results
    final expenses = await CsvImportTest.parseCsvFile(filePath);
    logger.i('\nParsed ${expenses.length} expenses:');
    
    for (final expense in expenses) {
      logger.i('Category: ${expense['category']}, '
            'Amount: ${expense['amount']}, '
            'Day: ${expense['day']}');
    }
    
    logger.i('\nTest completed successfully!');
  } catch (e) {
    logger.e('Error: $e');
  }
  
  // Keep console open
  logger.i('\nPress any key to exit...');
  stdin.readLineSync();
}
