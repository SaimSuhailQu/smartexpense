import 'package:cloud_firestore/cloud_firestore.dart';

class Income {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;
  final String currency;
  final List<String> tags;

  Income({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    this.currency = 'PKR',
    this.tags = const [],
  });

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: map['category'] ?? 'Other',
      notes: map['notes'],
      currency: map['currency'] ?? 'PKR',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'notes': notes,
      'currency': currency,
      'tags': tags,
    };
  }
}
