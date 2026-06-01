
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:open_file/open_file.dart';

class ExportUtil {
  static Future<void> exportToCSV(List<Expense> expenses) async {
    final List<List<dynamic>> csvData = [
      ['Title', 'Amount', 'Date', 'Category', 'Notes'],
      ...expenses.map((e) => [
        e.title,
        e.amount,
        e.date.toIso8601String(),
        e.category,
        e.notes ?? ''
      ])
    ];

    final String csv = Csv().encode(csvData);
    final String path = (await getDownloadsDirectory())!.path;
    final File file = File('$path/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    
    await file.writeAsString(csv);
    await OpenFile.open(file.path);
  }

  static Future<List<Expense>> importFromCSV(String filePath) async {
    final file = File(filePath);
    final csvString = await file.readAsString();
    final List<List<dynamic>> data = Csv().decode(csvString);
    
    return data.sublist(1).map((row) => Expense(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: row[0].toString(),
      amount: double.parse(row[1].toString()),
      date: DateTime.parse(row[2].toString()),
      category: row[3].toString(),
      notes: row.length > 4 ? row[4].toString() : null,
    )).toList();
  }
}