import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/data/models/wallet_dto.dart';

/// Remote data source — the only place that talks to Firestore for wallets.
abstract class WalletRemoteDataSource {
  Stream<List<WalletEntity>> streamWallets();
  Future<List<WalletEntity>> getWallets();
  Future<void> addWallet(WalletEntity wallet);
  Future<void> updateWallet(WalletEntity wallet);
  Future<void> deleteWallet(String walletId);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore _db;
  WalletRemoteDataSourceImpl(this._db);

  @override
  Stream<List<WalletEntity>> streamWallets() {
    return _db
        .collection(AppConstants.walletsCollection)
        .orderBy('created_at')
        .snapshots()
        .map((s) => s.docs.map(WalletDto.fromFirestore).toList());
  }

  @override
  Future<List<WalletEntity>> getWallets() async {
    final snapshot = await _db
        .collection(AppConstants.walletsCollection)
        .orderBy('created_at')
        .get();

    if (snapshot.docs.isEmpty) {
      // Seed default wallets on first run
      final batch = _db.batch();
      const defaultBanks = [
        'Cash', 'Mandiri', 'BCA', 'GoPay', 'SeaBank', 'Bank Jago', 'QRIS', 'Lainnya'
      ];
      for (final bank in defaultBanks) {
        final docRef =
            _db.collection(AppConstants.walletsCollection).doc(bank);
        batch.set(docRef, {
          'bank': bank,
          'name': '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return getWallets();
    }

    return snapshot.docs.map(WalletDto.fromFirestore).toList();
  }

  @override
  Future<void> addWallet(WalletEntity wallet) async {
    await _db
        .collection(AppConstants.walletsCollection)
        .doc(wallet.id)
        .set(WalletDto.toFirestore(wallet));
  }

  @override
  Future<void> updateWallet(WalletEntity wallet) async {
    await _db
        .collection(AppConstants.walletsCollection)
        .doc(wallet.id)
        .update(WalletDto.toFirestore(wallet));
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    await _db
        .collection(AppConstants.walletsCollection)
        .doc(walletId)
        .delete();
  }
}
