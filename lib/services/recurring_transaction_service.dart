import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartexpense/models/recurring_transaction.dart';
import 'package:smartexpense/models/expense.dart';
import 'package:smartexpense/models/income.dart';
import 'package:smartexpense/services/expense_service.dart';
import 'package:smartexpense/services/income_service.dart';
import 'package:smartexpense/utils/stream_extensions.dart';

class RecurringTransactionService with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  RecurringTransactionService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase services not available: $e');
      _firestore = null;
      _auth = null;
    }
  }

  Future<void> addRecurringTransaction(
      RecurringTransaction recurringTransaction) async {
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
          .collection('recurring_transactions')
          .doc(recurringTransaction.id)
          .set(recurringTransaction.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding recurring transaction: $e');
      rethrow;
    }
  }

  Stream<List<RecurringTransaction>> getRecurringTransactionsStream() {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return Stream.value([]);
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('recurring_transactions')
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                return RecurringTransaction.fromMap(doc.data());
              } catch (e) {
                debugPrint(
                    'Error parsing recurring transaction document ${doc.id}: $e');
                return null;
              }
            })
            .where((transaction) => transaction != null)
            .cast<RecurringTransaction>()
            .toList();
      } catch (e) {
        debugPrint('Error processing recurring transactions snapshot: $e');
        return <RecurringTransaction>[];
      }
    });
  }

  Future<void> deleteRecurringTransaction(String transactionId) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('recurring_transactions')
        .doc(transactionId)
        .delete();

    notifyListeners();
  }

  Future<void> checkForRecurringTransactions(
      ExpenseService expenseService, IncomeService incomeService) async {
    if (_auth == null || _firestore == null) {
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final recurringTransactions = await getRecurringTransactionsStream().firstOrDefault([]);

    for (var transaction in recurringTransactions) {
      if (now.isAfter(transaction.nextOccurrenceDate)) {
        // Generate transaction
        if (transaction.type == 'expense') {
          final expense = Expense(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: transaction.title,
            amount: transaction.amount,
            date: transaction.nextOccurrenceDate,
            category: transaction.category,
          );
          await expenseService.addExpense(expense);
        } else {
          final income = Income(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: transaction.title,
            amount: transaction.amount,
            date: transaction.nextOccurrenceDate,
            category: transaction.category,
          );
          await incomeService.addIncome(income);
        }

        // Update next occurrence date
        DateTime nextDate;
        switch (transaction.frequency) {
          case Frequency.daily:
            nextDate = transaction.nextOccurrenceDate.add(const Duration(days: 1));
            break;
          case Frequency.weekly:
            nextDate = transaction.nextOccurrenceDate.add(const Duration(days: 7));
            break;
          case Frequency.monthly:
            nextDate = DateTime(
              transaction.nextOccurrenceDate.year,
              transaction.nextOccurrenceDate.month + 1,
              transaction.nextOccurrenceDate.day,
            );
            break;
          case Frequency.yearly:
            nextDate = DateTime(
              transaction.nextOccurrenceDate.year + 1,
              transaction.nextOccurrenceDate.month,
              transaction.nextOccurrenceDate.day,
            );
            break;
        }

        if (transaction.endDate == null || nextDate.isBefore(transaction.endDate!)) {
          final updatedTransaction = RecurringTransaction(
            id: transaction.id,
            title: transaction.title,
            amount: transaction.amount,
            category: transaction.category,
            type: transaction.type,
            frequency: transaction.frequency,
            startDate: transaction.startDate,
            endDate: transaction.endDate,
            nextOccurrenceDate: nextDate,
          );
          await addRecurringTransaction(updatedTransaction);
        } else {
          // End date reached, delete recurring transaction
          await deleteRecurringTransaction(transaction.id);
        }
      }
    }
  }
}
