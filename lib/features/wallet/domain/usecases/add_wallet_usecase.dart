import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/domain/repositories/wallet_repository.dart';

class AddWalletUseCase {
  final WalletRepository repository;
  AddWalletUseCase(this.repository);

  Future<void> call(WalletEntity wallet) {
    return repository.addWallet(wallet);
  }
}
