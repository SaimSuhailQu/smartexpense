import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smartexpense/utils/model_parsing.dart';

class Budget {
  final String id;
  final String category;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.category,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] ?? '',
      category: map['category'] ?? 'Other',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: parseModelDate(map['startDate']),
      endDate: parseModelDate(map['endDate']),
    );
  }
}
