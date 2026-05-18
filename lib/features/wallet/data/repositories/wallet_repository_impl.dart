import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:fin_track/features/wallet/data/datasources/wallet_remote_datasource.dart';

/// Concrete implementation of WalletRepository.
class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource _dataSource;
  WalletRepositoryImpl(this._dataSource);

  @override
  Stream<List<WalletEntity>> streamWallets() {
    return _dataSource.streamWallets();
  }

  @override
  Future<List<WalletEntity>> getWallets() {
    return _dataSource.getWallets();
  }

  @override
  Future<void> addWallet(WalletEntity wallet) {
    return _dataSource.addWallet(wallet);
  }

  @override
  Future<void> updateWallet(WalletEntity wallet) {
    return _dataSource.updateWallet(wallet);
  }

  @override
  Future<void> deleteWallet(String walletId) {
    return _dataSource.deleteWallet(walletId);
  }
}
