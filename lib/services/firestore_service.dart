import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense(String userId, Map<String, dynamic> expenseData) {
    return _firestore.collection('users').doc(userId).collection('expenses').add(expenseData);
  }

  Future<List<Map<String, dynamic>>> getExpenses(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('expenses').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}