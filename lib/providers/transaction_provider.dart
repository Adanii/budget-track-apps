import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/models/transaction_model.dart';
import 'package:fin_track/services/firestore_service.dart';
import 'package:fin_track/core/constants.dart';
import 'package:intl/intl.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final currentMonthProvider = StateProvider<String>((ref) {
  return DateFormat('yyyy-MM').format(DateTime.now());
});

final transactionsStreamProvider = StreamProvider.family<List<TransactionModel>, String>((ref, month) {
  final service = ref.watch(firestoreServiceProvider);
  return service.streamTransactions(month);
});

final latestBalanceProvider = FutureProvider<int>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getLatestBalance();
});

final walletBalancesProvider = FutureProvider<Map<String, int>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getWalletBalances();
});

class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _service;
  TransactionNotifier(this._service) : super(const AsyncValue.data(null));

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
      final latestBalance = await _service.getLatestBalance();
      final newBalance = transactionType == AppConstants.typeIncome || transactionType == AppConstants.typeAdjustmentAdd
          ? latestBalance + amount 
          : transactionType == AppConstants.typeExpense || transactionType == AppConstants.typeAdjustmentSub
              ? latestBalance - amount
              : latestBalance; // Transfer does not change total balance

      final transaction = TransactionModel(
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

      await _service.addTransaction(transaction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String id) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteTransaction(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionActionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return TransactionNotifier(service);
});
