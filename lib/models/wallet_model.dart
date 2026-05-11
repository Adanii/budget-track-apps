import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String bank;
  final String name;
  final DateTime createdAt;

  WalletModel({
    required this.id,
    required this.bank,
    required this.name,
    required this.createdAt,
  });

  String get displayName => name.isNotEmpty ? '$bank ($name)' : bank;

  factory WalletModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WalletModel(
      id: doc.id,
      bank: data['bank'] ?? 'Lainnya',
      name: data['name'] ?? '',
      createdAt: data['created_at'] != null 
          ? (data['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bank': bank,
      'name': name,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}
