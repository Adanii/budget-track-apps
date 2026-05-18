import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fin_track/features/wallet/domain/usecases/get_wallets_usecase.dart';
import 'package:fin_track/features/wallet/domain/usecases/add_wallet_usecase.dart';
import 'package:fin_track/features/wallet/domain/usecases/update_wallet_usecase.dart';
import 'package:fin_track/features/wallet/domain/usecases/delete_wallet_usecase.dart';
import 'package:fin_track/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:fin_track/features/wallet/data/repositories/wallet_repository_impl.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final walletDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSourceImpl(FirebaseFirestore.instance);
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletDataSourceProvider));
});

// ── Use Cases ─────────────────────────────────────────────────────────────────

final getWalletsUseCaseProvider = Provider((ref) {
  return GetWalletsUseCase(ref.watch(walletRepositoryProvider));
});

final addWalletUseCaseProvider = Provider((ref) {
  return AddWalletUseCase(ref.watch(walletRepositoryProvider));
});

final updateWalletUseCaseProvider = Provider((ref) {
  return UpdateWalletUseCase(ref.watch(walletRepositoryProvider));
});

final deleteWalletUseCaseProvider = Provider((ref) {
  return DeleteWalletUseCase(ref.watch(walletRepositoryProvider));
});

// ── State Providers ───────────────────────────────────────────────────────────

final walletsStreamProvider = StreamProvider<List<WalletEntity>>((ref) {
  return ref.watch(getWalletsUseCaseProvider).call();
});

// ── Wallet Action Notifier ────────────────────────────────────────────────────

class WalletNotifier extends StateNotifier<AsyncValue<void>> {
  final AddWalletUseCase _addUseCase;
  final UpdateWalletUseCase _updateUseCase;
  final DeleteWalletUseCase _deleteUseCase;

  WalletNotifier({
    required AddWalletUseCase addUseCase,
    required UpdateWalletUseCase updateUseCase,
    required DeleteWalletUseCase deleteUseCase,
  })  : _addUseCase = addUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        super(const AsyncValue.data(null));

  Future<void> addWallet(WalletEntity wallet) async {
    state = const AsyncValue.loading();
    try {
      await _addUseCase(wallet);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWallet(WalletEntity wallet) async {
    state = const AsyncValue.loading();
    try {
      await _updateUseCase(wallet);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWallet(String walletId) async {
    state = const AsyncValue.loading();
    try {
      await _deleteUseCase(walletId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final walletActionProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<void>>((ref) {
  return WalletNotifier(
    addUseCase: ref.watch(addWalletUseCaseProvider),
    updateUseCase: ref.watch(updateWalletUseCaseProvider),
    deleteUseCase: ref.watch(deleteWalletUseCaseProvider),
  );
});
