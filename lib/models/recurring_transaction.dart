import 'package:cloud_firestore/cloud_firestore.dart';

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
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      category: map['category'],
      type: map['type'],
      frequency: Frequency.values
          .firstWhere((e) => e.toString() == map['frequency']),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null
          ? (map['endDate'] as Timestamp).toDate()
          : null,
      nextOccurrenceDate: (map['nextOccurrenceDate'] as Timestamp).toDate(),
    );
  }
}
