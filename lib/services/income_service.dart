import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/services/currency_conversion_service.dart';
import 'package:smartexpense/utils/date_utils.dart'; // Contains TimeRange enum

class IncomeService with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  final CurrencyService _currencyService;
  final CurrencyConversionService _conversionService;

  IncomeService(this._currencyService, this._conversionService) {
    // Initialize Firebase services only if Firebase is available
    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase services not available: $e');
      _firestore = null;
      _auth = null;
    }
  }

  Future<void> addIncome(Income income) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    try {
      final user = _auth!.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore!
          .collection('users')
          .doc(user.uid)
          .collection('incomes')
          .doc(income.id)
          .set(income.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding income: $e');
      rethrow;
    }
  }

  Stream<List<Income>> getIncomesStream(TimeRange range, DateTime selectedDate, {Map<String, dynamic>? filters}) {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return Stream.value([]);
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    Query query = _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('incomes');

    if (filters != null && filters.isNotEmpty) {
      if (filters['startDate'] != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(filters['startDate']));
      }
      if (filters['endDate'] != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(filters['endDate']));
      }
      if (filters['categories'] != null && (filters['categories'] as List).isNotEmpty) {
        query = query.where('category', whereIn: filters['categories']);
      }
      if (filters['minAmount'] != null) {
        query = query.where('amount', isGreaterThanOrEqualTo: filters['minAmount']);
      }
      if (filters['maxAmount'] != null) {
        query = query.where('amount', isLessThanOrEqualTo: filters['maxAmount']);
      }
      if (filters['tags'] != null && (filters['tags'] as List).isNotEmpty) {
        query = query.where('tags', arrayContainsAny: filters['tags']);
      }
    } else {
      final start = _getRangeStart(range, selectedDate);
      final end = _getRangeEnd(range, selectedDate);
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                   .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      try {
        final incomes = snapshot.docs
            .map((doc) {
              try {
                return Income.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing income document ${doc.id}: $e');
                return null;
              }
            })
            .where((income) => income != null)
            .cast<Income>()
            .toList();

        final primaryCurrency = _currencyService.primaryCurrency;
        final convertedIncomes = await Future.wait(incomes.map((income) async {
          if (income.currency != primaryCurrency) {
            final convertedAmount = await _conversionService.convert(
                income.amount, income.currency, primaryCurrency);
            return Income(
              id: income.id,
              title: income.title,
              amount: convertedAmount,
              date: income.date,
              category: income.category,
              notes: income.notes,
              currency: primaryCurrency,
              tags: income.tags,
            );
          }
          return income;
        }));

        return convertedIncomes;
      } catch (e) {
        debugPrint('Error processing incomes snapshot: $e');
        return <Income>[];
      }
    });
  }

  Future<void> deleteIncome(String incomeId) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('incomes')
        .doc(incomeId)
        .delete();

    notifyListeners();
  }

  Future<double> calculateTotalInPrimaryCurrency(List<Income> incomes) async {
    final primaryCurrency = _currencyService.primaryCurrency;
    double total = 0.0;

    for (final income in incomes) {
      if (income.currency == primaryCurrency) {
        total += income.amount;
      } else {
        total += await _conversionService.convert(
          income.amount,
          income.currency,
          primaryCurrency,
        );
      }
    }
    return total;
  }

  // Helper: Start of time range
  DateTime _getRangeStart(TimeRange range, DateTime date) {
    switch (range) {
      case TimeRange.daily:
        return DateTime(date.year, date.month, date.day);
      case TimeRange.weekly:
        return date.subtract(Duration(days: date.weekday - 1));
      case TimeRange.monthly:
        return DateTime(date.year, date.month, 1);
      case TimeRange.yearly:
        if (date.month < 7) { // Before July
          return DateTime(date.year - 1, 7, 1);
        } else { // July or after
          return DateTime(date.year, 7, 1);
        }
      case TimeRange.loans:
        // For loans, we don't need a specific date range
        // Return a default range that covers all time
        return DateTime(2000);
      case TimeRange.categories:
        // For categories, we don't need a specific date range
        // Return a default range that covers all time
        return DateTime(2000);
      case TimeRange.custom:
        return DateTime.now(); // Should not be used
    }

  }

  // Helper: End of time range
  DateTime _getRangeEnd(TimeRange range, DateTime date) {
    switch (range) {
      case TimeRange.daily:
        return DateTime(date.year, date.month, date.day, 23, 59, 59);
      case TimeRange.weekly:
        return date
            .add(Duration(days: 7 - date.weekday))
            .add(const Duration(hours: 23, minutes: 59, seconds: 59));
      case TimeRange.monthly:
        final nextMonth = DateTime(date.year, date.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case TimeRange.yearly:
        if (date.month < 7) { // Before July
          return DateTime(date.year, 6, 30, 23, 59, 59);
        } else { // July or after
          return DateTime(date.year + 1, 6, 30, 23, 59, 59);
        }
      case TimeRange.loans:
        // For loans, we don't need a specific date range
        // Return a default range that covers all time
        return DateTime(2100);
      case TimeRange.categories:
        // For categories, we don't need a specific date range
        // Return a default range that covers all time
        return DateTime(2100);
      case TimeRange.custom:
        return DateTime.now(); // Should not be used
    }

  }
}
