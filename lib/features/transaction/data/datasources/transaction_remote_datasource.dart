import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/features/transaction/data/models/transaction_dto.dart';

/// Remote data source — the only place in the app that talks to Firestore for transactions.
abstract class TransactionRemoteDataSource {
  Stream<List<TransactionEntity>> streamTransactions(String month);
  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionEntity>> getAllTransactions();
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final FirebaseFirestore _db;
  TransactionRemoteDataSourceImpl(this._db);

  @override
  Stream<List<TransactionEntity>> streamTransactions(String month) {
    return _db
        .collection(AppConstants.transactionsCollection)
        .where('month', isEqualTo: month)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(TransactionDto.fromFirestore).toList());
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    await _db
        .collection(AppConstants.transactionsCollection)
        .add(TransactionDto.toFirestore(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _db
        .collection(AppConstants.transactionsCollection)
        .doc(id)
        .delete();
  }

  @override
  Future<List<TransactionEntity>> getAllTransactions() async {
    final snapshot =
        await _db.collection(AppConstants.transactionsCollection).get();
    return snapshot.docs.map(TransactionDto.fromFirestore).toList();
  }
}
