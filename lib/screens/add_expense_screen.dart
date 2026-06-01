import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/widgets/expense_form.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  Expense? _initialExpense;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _scanReceipt,
          ),
        ],
      ),
      body: ExpenseForm(
        initialExpense: _initialExpense,
        onSave: (expense) {
          Provider.of<ExpenseService>(context, listen: false).addExpense(expense);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final textRecognizer = TextRecognizer();
      final recognizedText =
          await textRecognizer.processImage(InputImage.fromFilePath(pickedFile.path));
      await _processScannedText(recognizedText.text);
      textRecognizer.close();
    }
  }

  Future<void> _processScannedText(String text) async {
    double? amount;
    DateTime? date;

    // Find amount
    final amountRegex = RegExp(r'total\s*[:\s]*\$?(\d+\.\d{2})', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch != null) {
      amount = double.tryParse(amountMatch.group(1)!);
    }

    // Find date
    final dateRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})');
    final dateMatch = dateRegex.firstMatch(text);
    if (dateMatch != null) {
      try {
        date = DateFormat('MM/dd/yy').parse(dateMatch.group(1)!);
      } catch (e) {
        // try another format
        try {
          date = DateFormat('dd/MM/yyyy').parse(dateMatch.group(1)!);
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
    }

    setState(() {
      _initialExpense = Expense(
        id: '',
        title: 'Scanned Expense',
        amount: amount ?? 0.0,
        date: date ?? DateTime.now(),
        category: 'Other',
      );
    });
  }
}