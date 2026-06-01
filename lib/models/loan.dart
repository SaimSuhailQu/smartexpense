import 'package:cloud_firestore/cloud_firestore.dart';

class Loan {
  final String id;
  final String title;
  final double amount;
  final double remainingAmount;
  final DateTime date;
  final String notes;
  final String type; // 'borrowed' or 'lent'
  final String currency;
  final double interestRate;

  Loan({
    required this.id,
    required this.title,
    required this.amount,
    required this.remainingAmount,
    required this.date,
    required this.notes,
    required this.type,
    this.currency = 'PKR',
    this.interestRate = 0.0,
  });

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] ?? '',
      type: map['type'] ?? 'borrowed',
      currency: map['currency'] ?? 'PKR',
      interestRate: (map['interestRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'remainingAmount': remainingAmount,
      'date': Timestamp.fromDate(date), // Store as Firestore Timestamp
      'notes': notes,
      'type': type,
      'currency': currency,
      'interestRate': interestRate,
    };
  }
}
