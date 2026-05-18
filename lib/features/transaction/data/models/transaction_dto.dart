import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';

/// Data Transfer Object — handles Firestore serialization/deserialization.
/// Keeps the domain entity clean from any Firebase dependency.
class TransactionDto {
  static TransactionEntity fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionEntity(
      id: doc.id,
      person: data['person'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      amount: data['amount'] ?? 0,
      transactionType: data['transaction_type'] ?? '',
      expenseType: data['expense_type'] ?? '',
      paymentMethod: data['payment_method'] ?? '',
      destinationWallet: data['destination_wallet'],
      note: data['note'] ?? '',
      month: data['month'] ?? '',
      balanceAfter: data['balance_after'] ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  static Map<String, dynamic> toFirestore(TransactionEntity entity) {
    return {
      'person': entity.person,
      'date': Timestamp.fromDate(entity.date),
      'amount': entity.amount,
      'transaction_type': entity.transactionType,
      'expense_type': entity.expenseType,
      'payment_method': entity.paymentMethod,
      'destination_wallet': entity.destinationWallet,
      'note': entity.note,
      'month': entity.month,
      'balance_after': entity.balanceAfter,
      'created_at': Timestamp.fromDate(entity.createdAt),
    };
  }
}
