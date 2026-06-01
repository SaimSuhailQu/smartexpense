import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartexpense/models/loan.dart';
import 'package:smartexpense/models/payment.dart';
import 'package:smartexpense/services/currency_service.dart';
import 'package:smartexpense/services/currency_conversion_service.dart';

class LoanService with ChangeNotifier {
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  final CurrencyService _currencyService;
  final CurrencyConversionService _conversionService;

  LoanService(this._currencyService, this._conversionService) {
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

  Future<void> addLoan(Loan loan) async {
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
          .collection('loans')
          .doc(loan.id)
          .set(loan.toMap());

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding loan: $e');
      rethrow;
    }
  }

  Stream<List<Loan>> getLoansStream() {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return Stream.value([]);
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('loans')
        .orderBy('date', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final loans =
          snapshot.docs.map((doc) => Loan.fromMap(doc.data())).toList();
      final primaryCurrency = _currencyService.primaryCurrency;
      final convertedLoans = await Future.wait(loans.map((loan) async {
        if (loan.currency != primaryCurrency) {
          final convertedAmount = await _conversionService.convert(
              loan.amount, loan.currency, primaryCurrency);
          final convertedRemainingAmount = await _conversionService.convert(
              loan.remainingAmount, loan.currency, primaryCurrency);
          return Loan(
            id: loan.id,
            title: loan.title,
            amount: convertedAmount,
            remainingAmount: convertedRemainingAmount,
            date: loan.date,
            notes: loan.notes,
            type: loan.type,
            currency: primaryCurrency,
          );
        }
        return loan;
      }));
      return convertedLoans;
    });
  }

  Stream<List<Payment>> getPaymentsStream(String loanId) {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return Stream.value([]);
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('loans')
        .doc(loanId)
        .collection('payments')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateLoan(Loan loan) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('loans')
        .doc(loan.id)
        .update(loan.toMap());

    notifyListeners();
  }

  Future<void> deleteLoan(String loanId) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('loans')
        .doc(loanId)
        .delete();

    notifyListeners();
  }

  Future<void> addRepayment(String loanId, Payment payment) async {
    if (_auth == null || _firestore == null) {
      debugPrint('Firebase services not available on this platform');
      return;
    }
    final user = _auth!.currentUser;
    if (user == null) throw Exception('User not logged in');

    final loanDoc = _firestore!
        .collection('users')
        .doc(user.uid)
        .collection('loans')
        .doc(loanId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final loanSnapshot = await transaction.get(loanDoc);

      if (!loanSnapshot.exists) {
        throw Exception('Loan not found');
      }

      final loan = Loan.fromMap(loanSnapshot.data() as Map<String, dynamic>);
      final newRemainingAmount = loan.remainingAmount - payment.amount;

      if (newRemainingAmount < 0) {
        throw Exception('Repayment amount exceeds remaining loan amount');
      }

      // Update the loan's remaining amount
      transaction.update(loanDoc, {
        'remainingAmount': newRemainingAmount,
      });

      // Add the payment to the subcollection
      final paymentRef = loanDoc.collection('payments').doc(payment.id);
      transaction.set(paymentRef, payment.toMap());
    });

    notifyListeners();
  }
}
