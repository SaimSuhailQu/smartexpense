import 'package:cloud_firestore/cloud_firestore.dart';

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
    // Handle both Timestamp (from Firestore) and int (from local storage)
    DateTime dateTime;
    if (map['date'] is Timestamp) {
      dateTime = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(map['date']);
    } else {
      dateTime = DateTime.now(); // Fallback
    }

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
