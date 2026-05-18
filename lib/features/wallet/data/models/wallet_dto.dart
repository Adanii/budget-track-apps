import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';

/// Data Transfer Object — handles Firestore serialization/deserialization for wallets.
class WalletDto {
  static WalletEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletEntity(
      id: doc.id,
      bank: data['bank'] ?? 'Lainnya',
      name: data['name'] ?? '',
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  static Map<String, dynamic> toFirestore(WalletEntity entity) {
    return {
      'bank': entity.bank,
      'name': entity.name,
      'created_at': Timestamp.fromDate(entity.createdAt),
    };
  }
}
