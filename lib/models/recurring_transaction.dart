import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartexpense/utils/model_parsing.dart';

enum Frequency { daily, weekly, monthly, yearly }

class RecurringTransaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String type; // 'expense' or 'income'
  final Frequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextOccurrenceDate;

  RecurringTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextOccurrenceDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'frequency': frequency.toString(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'nextOccurrenceDate': Timestamp.fromDate(nextOccurrenceDate),
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Other',
      type: map['type'] ?? 'expense',
      frequency: Frequency.values.firstWhere(
        (e) => e.toString() == map['frequency'],
        orElse: () => Frequency.monthly,
      ),
      startDate: parseModelDate(map['startDate']),
      endDate:
          map['endDate'] != null ? parseModelDate(map['endDate']) : null,
      nextOccurrenceDate: parseModelDate(map['nextOccurrenceDate']),
    );
  }
}
