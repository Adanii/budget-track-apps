import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:fin_track/features/transaction/data/datasources/transaction_remote_datasource.dart';
import 'package:fin_track/features/wallet/data/datasources/wallet_remote_datasource.dart';

/// Concrete implementation of TransactionRepository.
/// Depends on data sources (not Firestore directly).
class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource _transactionDataSource;
  final WalletRemoteDataSource _walletDataSource;

  TransactionRepositoryImpl({
    required TransactionRemoteDataSource transactionDataSource,
    required WalletRemoteDataSource walletDataSource,
  })  : _transactionDataSource = transactionDataSource,
        _walletDataSource = walletDataSource;

  @override
  Stream<List<TransactionEntity>> streamTransactions(String month) {
    return _transactionDataSource.streamTransactions(month);
  }

  @override
  Future<void> addTransaction(TransactionEntity transaction) {
    return _transactionDataSource.addTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) {
    return _transactionDataSource.deleteTransaction(id);
  }

  @override
  Future<Map<String, int>> getWalletBalances() async {
    final transactions = await _transactionDataSource.getAllTransactions();
    final wallets = await _walletDataSource.getWallets();

    final Map<String, int> balances = {for (final w in wallets) w.id: 0};

    for (final t in transactions) {
      switch (t.transactionType) {
        case AppConstants.typeIncome:
        case AppConstants.typeAdjustmentAdd:
          balances[t.paymentMethod] =
              (balances[t.paymentMethod] ?? 0) + t.amount;
          break;
        case AppConstants.typeExpense:
        case AppConstants.typeAdjustmentSub:
          balances[t.paymentMethod] =
              (balances[t.paymentMethod] ?? 0) - t.amount;
          break;
        case AppConstants.typeTransfer:
          balances[t.paymentMethod] =
              (balances[t.paymentMethod] ?? 0) - t.amount;
          if (t.destinationWallet != null) {
            balances[t.destinationWallet!] =
                (balances[t.destinationWallet!] ?? 0) + t.amount;
          }
          break;
      }
    }
    return balances;
  }

  @override
  Future<int> getLatestBalance() async {
    final balances = await getWalletBalances();
    return balances.values.fold<int>(0, (acc, b) => acc + b);
  }
}
