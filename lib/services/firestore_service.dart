import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TransactionModel>> streamTransactions(String month) {
    return _db
        .collection(AppConstants.transactionsCollection)
        .where('month', isEqualTo: month)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromFirestore(doc))
            .toList());
  }

  Future<Map<String, int>> getWalletBalances() async {
    final snapshot = await _db.collection(AppConstants.transactionsCollection).get();
    Map<String, int> balances = {};
    
    // Initialize balances to 0 for all known wallets
    for (var m in AppConstants.wallets) {
      balances[m] = 0;
    }
    
    for (var doc in snapshot.docs) {
      final t = TransactionModel.fromFirestore(doc);
      if (t.transactionType == AppConstants.typeIncome) {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) + t.amount;
      } else {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) - t.amount;
      }
    }
    return balances;
  }

  Future<int> getLatestBalance() async {
    final balances = await getWalletBalances();
    return balances.values.fold<int>(0, (sum, balance) => sum + balance);
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _db
        .collection(AppConstants.transactionsCollection)
        .add(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String id) async {
    await _db.collection(AppConstants.transactionsCollection).doc(id).delete();
  }
}
