import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/domain/repositories/wallet_repository.dart';

class GetWalletsUseCase {
  final WalletRepository repository;
  GetWalletsUseCase(this.repository);

  Stream<List<WalletEntity>> call() {
    return repository.streamWallets();
  }
}
