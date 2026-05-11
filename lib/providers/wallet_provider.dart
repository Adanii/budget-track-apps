import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/models/wallet_model.dart';
import 'package:fin_track/services/firestore_service.dart';
import 'package:fin_track/providers/transaction_provider.dart';

final walletsStreamProvider = StreamProvider<List<WalletModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.streamWallets();
});

class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _service;
  WalletNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> addWallet(WalletModel wallet) async {
    state = const AsyncValue.loading();
    try {
      await _service.addWallet(wallet);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWallet(WalletModel wallet) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateWallet(wallet);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWallet(String walletId) async {
    state = const AsyncValue.loading();
    try {
      await _service.deleteWallet(walletId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final walletActionProvider = StateNotifierProvider<WalletNotifier, AsyncValue<void>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return WalletNotifier(service);
});
