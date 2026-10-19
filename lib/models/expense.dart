import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartexpense/utils/model_parsing.dart';

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
    // Bad dates throw (see model_parsing.dart) so the doc is skipped by the
    // stream mapper instead of being silently re-dated to today.
    final DateTime dateTime = parseModelDate(map['date']);

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
