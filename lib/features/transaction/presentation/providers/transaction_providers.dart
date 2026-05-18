import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:fin_track/features/transaction/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_track/features/transaction/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_track/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_track/features/transaction/domain/usecases/get_wallet_balances_usecase.dart';
import 'package:fin_track/features/transaction/domain/usecases/get_latest_balance_usecase.dart';
import 'package:fin_track/features/transaction/data/datasources/transaction_remote_datasource.dart';
import 'package:fin_track/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:fin_track/features/wallet/presentation/providers/wallet_providers.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final transactionDataSourceProvider = Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSourceImpl(FirebaseFirestore.instance);
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    transactionDataSource: ref.watch(transactionDataSourceProvider),
    walletDataSource: ref.watch(walletDataSourceProvider),
  );
});

// ── Use Cases ─────────────────────────────────────────────────────────────────

final getTransactionsUseCaseProvider = Provider((ref) {
  return GetTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

final addTransactionUseCaseProvider = Provider((ref) {
  return AddTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final deleteTransactionUseCaseProvider = Provider((ref) {
  return DeleteTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final getWalletBalancesUseCaseProvider = Provider((ref) {
  return GetWalletBalancesUseCase(ref.watch(transactionRepositoryProvider));
});

final getLatestBalanceUseCaseProvider = Provider((ref) {
  return GetLatestBalanceUseCase(ref.watch(transactionRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────────────────────────

final currentMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

final transactionsStreamProvider =
    StreamProvider.family<List<TransactionEntity>, String>((ref, month) {
  return ref.watch(getTransactionsUseCaseProvider).call(month);
});

final latestBalanceProvider = FutureProvider<int>((ref) {
  return ref.watch(getLatestBalanceUseCaseProvider).call();
});

final walletBalancesProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(getWalletBalancesUseCaseProvider).call();
});

// ── Transaction Action Notifier ───────────────────────────────────────────────

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final AddTransactionUseCase _addUseCase;
  final DeleteTransactionUseCase _deleteUseCase;
  final GetLatestBalanceUseCase _latestBalanceUseCase;

  TransactionNotifier({
    required AddTransactionUseCase addUseCase,
    required DeleteTransactionUseCase deleteUseCase,
    required GetLatestBalanceUseCase latestBalanceUseCase,
  })  : _addUseCase = addUseCase,
        _deleteUseCase = deleteUseCase,
        _latestBalanceUseCase = latestBalanceUseCase,
        super(const AsyncValue.data(null));

  Future<void> addTransaction({
    required String person,
    required DateTime date,
    required int amount,
    required String transactionType,
    required String expenseType,
    required String paymentMethod,
    String? destinationWallet,
    required String note,
  }) async {
    state = const AsyncValue.loading();
    try {
      final latestBalance = await _latestBalanceUseCase();
      final newBalance = switch (transactionType) {
        AppConstants.typeIncome || AppConstants.typeAdjustmentAdd => latestBalance + amount,
        AppConstants.typeExpense || AppConstants.typeAdjustmentSub => latestBalance - amount,
        _ => latestBalance, // Transfer: no change to total
      };

      final transaction = TransactionEntity(
        id: '',
        person: person,
        date: date,
        amount: amount,
        transactionType: transactionType,
        expenseType: expenseType,
        paymentMethod: paymentMethod,
        destinationWallet: destinationWallet,
        note: note,
        month: DateFormat('yyyy-MM').format(date),
        balanceAfter: newBalance,
        createdAt: DateTime.now(),
      );

      await _addUseCase(transaction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await _deleteUseCase(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionActionProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  return TransactionNotifier(
    addUseCase: ref.watch(addTransactionUseCaseProvider),
    deleteUseCase: ref.watch(deleteTransactionUseCaseProvider),
    latestBalanceUseCase: ref.watch(getLatestBalanceUseCaseProvider),
  );
});
