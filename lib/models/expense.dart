import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;
  final String currency;
  final List<String> tags;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    this.currency = 'PKR',
    this.tags = const [],
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    // Handle both Timestamp (from Firestore) and int (from local storage)
    DateTime dateTime;
    if (map['date'] is Timestamp) {
      dateTime = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(map['date']);
    } else {
      dateTime = DateTime.now(); // Fallback
    }

    return Expense(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: dateTime,
      category: map['category'] ?? 'Other',
      notes: map['notes'],
      currency: map['currency'] ?? 'PKR',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Null get description => null;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date), // Store as Firestore Timestamp
      'category': category,
      'notes': notes,
      'currency': currency,
      'tags': tags,
    };
  }
}
