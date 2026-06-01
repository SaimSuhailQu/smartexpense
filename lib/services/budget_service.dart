import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartexpense/models/budget.dart';

class BudgetService with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;

  BudgetService() {
    try {
      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase services not available: $e');
      _firestore = null;
      _auth = null;
    }
  }

  Future<void> addBudget(Budget budget) async {
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
          .collection('budgets')
          .doc(budget.id)
          .set(budget.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding budget: $e');
      rethrow;
    }
  }

  Stream<List<Budget>> getBudgetsStream() {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return Stream.value([]);
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                return Budget.fromMap(doc.data());
              } catch (e) {
                debugPrint('Error parsing budget document ${doc.id}: $e');
                return null;
              }
            })
            .where((budget) => budget != null)
            .cast<Budget>()
            .toList();
      } catch (e) {
        debugPrint('Error processing budgets snapshot: $e');
        return <Budget>[];
      }
    });
  }

  Future<void> deleteBudget(String budgetId) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('budgets')
        .doc(budgetId)
        .delete();

    notifyListeners();
  }
}
