import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/services/currency_conversion_service.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/utils/date_utils.dart'; // Contains TimeRange enum

class ExpenseService with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  final CurrencyService _currencyService;
  final CurrencyConversionService _currencyConversionService;

  ExpenseService(this._currencyService, this._currencyConversionService) {
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

  Future<void> addExpense(Expense expense) async {
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
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Stream<List<Expense>> getExpensesStream(TimeRange range, DateTime selectedDate, {Map<String, dynamic>? filters}) {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return Stream.value([]);
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    Query query = _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('expenses');

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
    } else {
      final start = _getRangeStart(range, selectedDate);
      final end = _getRangeEnd(range, selectedDate);
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                   .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end));
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) {
                  try {
                    return Expense.fromMap(doc.data() as Map<String, dynamic>);
                  } catch (e) {
                    debugPrint('Error parsing expense document ${doc.id}: $e');
                    return null;
                  }
                })
                .where((expense) => expense != null)
                .cast<Expense>()
                .toList();
          } catch (e) {
            debugPrint('Error processing expenses snapshot: $e');
            return <Expense>[];
          }
        });
  }

  Stream<List<Expense>> getExpensesBetweenDates(DateTime startDate, DateTime endDate) {
    return getExpensesStream(TimeRange.custom, DateTime.now(), filters: {
      'startDate': startDate,
      'endDate': endDate,
    });
  }

  Future<void> deleteExpense(String expenseId) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .doc(expenseId)
        .delete();

    notifyListeners();
  }

  /// Converts an expense amount to the user's primary currency
  Future<double> getExpenseInPrimaryCurrency(Expense expense) async {
    // Note: This assumes Expense model has a 'currency' field.
    // If not, please add: final String currency; to your Expense model.
    if (expense.currency == _currencyService.primaryCurrency) {
      return expense.amount;
    }
    return await _currencyConversionService.convert(
      expense.amount,
      expense.currency,
      _currencyService.primaryCurrency,
    );
  }

  /// Calculate total expenses in primary currency for a list of expenses
  Future<double> calculateTotalInPrimaryCurrency(List<Expense> expenses) async {
    double total = 0;
    for (var expense in expenses) {
      total += await getExpenseInPrimaryCurrency(expense);
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
        final int currentYear = date.year;
        final int currentMonth = date.month;
        if (currentMonth < 7) { // Before July
          return DateTime(currentYear - 1, 7, 1);
        } else { // July or after
          return DateTime(currentYear, 7, 1);
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
          final int currentYear = date.year;
          final int currentMonth = date.month;
          if (currentMonth < 7) { // Before July
            return DateTime(currentYear, 6, 30, 23, 59, 59);
          } else { // July or after
            return DateTime(currentYear + 1, 6, 30, 23, 59, 59);
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
