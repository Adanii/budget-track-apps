import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';

/// Abstract contract for transaction data operations.
/// Data layer must implement this; presentation layer depends only on this.
abstract class TransactionRepository {
  Stream<List<TransactionEntity>> streamTransactions(String month);
  Future<void> addTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  Future<Map<String, int>> getWalletBalances();
  Future<int> getLatestBalance();
}
