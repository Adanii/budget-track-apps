import 'package:fin_track/features/wallet/domain/repositories/wallet_repository.dart';

class DeleteWalletUseCase {
  final WalletRepository repository;
  DeleteWalletUseCase(this.repository);

  Future<void> call(String walletId) {
    return repository.deleteWallet(walletId);
  }
}
