import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/models/transaction_model.dart';
import 'package:fin_track/models/wallet_model.dart';

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

  Future<List<WalletModel>> getWallets() async {
    final snapshot = await _db.collection(AppConstants.walletsCollection).orderBy('created_at').get();
    
    if (snapshot.docs.isEmpty) {
      final batch = _db.batch();
      final List<String> defaultBanks = ['Cash', 'Mandiri', 'BCA', 'GoPay', 'SeaBank', 'Bank Jago', 'QRIS', 'Lainnya'];
      
      for (var bank in defaultBanks) {
        final docRef = _db.collection(AppConstants.walletsCollection).doc(bank);
        batch.set(docRef, {
          'bank': bank,
          'name': '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return getWallets(); // Retry
    }
    
    return snapshot.docs.map((doc) => WalletModel.fromFirestore(doc)).toList();
  }

  Stream<List<WalletModel>> streamWallets() {
    return _db.collection(AppConstants.walletsCollection).orderBy('created_at').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => WalletModel.fromFirestore(doc)).toList()
    );
  }

  Future<void> addWallet(WalletModel wallet) async {
    // We use set instead of add, because if id is empty, we create a new doc, 
    // but WalletModel already has an id. If it's a new UUID, set works perfectly.
    await _db.collection(AppConstants.walletsCollection).doc(wallet.id).set(wallet.toFirestore());
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await _db.collection(AppConstants.walletsCollection).doc(wallet.id).update(wallet.toFirestore());
  }

  Future<void> deleteWallet(String walletId) async {
    await _db.collection(AppConstants.walletsCollection).doc(walletId).delete();
  }

  Future<Map<String, int>> getWalletBalances() async {
    final snapshot = await _db.collection(AppConstants.transactionsCollection).get();
    final wallets = await getWallets();
    Map<String, int> balances = {};
    
    for (var w in wallets) {
      balances[w.id] = 0;
    }
    
    for (var doc in snapshot.docs) {
      final t = TransactionModel.fromFirestore(doc);
      if (t.transactionType == AppConstants.typeIncome) {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) + t.amount;
      } else if (t.transactionType == AppConstants.typeExpense) {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) - t.amount;
      } else if (t.transactionType == AppConstants.typeTransfer) {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) - t.amount;
        if (t.destinationWallet != null) {
          balances[t.destinationWallet!] = (balances[t.destinationWallet!] ?? 0) + t.amount;
        }
      } else if (t.transactionType == AppConstants.typeAdjustmentAdd) {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) + t.amount;
      } else if (t.transactionType == AppConstants.typeAdjustmentSub) {
        balances[t.paymentMethod] = (balances[t.paymentMethod] ?? 0) - t.amount;
      }
    }
    return balances;
  }

  Future<int> getLatestBalance() async {
    final balances = await getWalletBalances();
    return balances.values.fold<int>(0, (acc, balance) => acc + balance);
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
