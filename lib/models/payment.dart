import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartexpense/utils/model_parsing.dart';

class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String notes;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    required this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    final DateTime dateTime = parseModelDate(map['date']);

    return Payment(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: dateTime,
      notes: map['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date), // Store as Firestore Timestamp
      'notes': notes,
    };
  }
}
