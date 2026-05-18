import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';

/// Abstract contract for wallet data operations.
abstract class WalletRepository {
  Stream<List<WalletEntity>> streamWallets();
  Future<List<WalletEntity>> getWallets();
  Future<void> addWallet(WalletEntity wallet);
  Future<void> updateWallet(WalletEntity wallet);
  Future<void> deleteWallet(String walletId);
}
