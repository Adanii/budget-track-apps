import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String person;
  final DateTime date;
  final int amount;
  final String transactionType; // income, expense
  final String expenseType; // small_expense, large_expense, none
  final String paymentMethod;
  final String note;
  final String month; // YYYY-MM
  final int balanceAfter;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.person,
    required this.date,
    required this.amount,
    required this.transactionType,
    required this.expenseType,
    required this.paymentMethod,
    required this.note,
    required this.month,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      person: data['person'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      amount: data['amount'] ?? 0,
      transactionType: data['transaction_type'] ?? '',
      expenseType: data['expense_type'] ?? '',
      paymentMethod: data['payment_method'] ?? '',
      note: data['note'] ?? '',
      month: data['month'] ?? '',
      balanceAfter: data['balance_after'] ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'person': person,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'transaction_type': transactionType,
      'expense_type': expenseType,
      'payment_method': paymentMethod,
      'note': note,
      'month': month,
      'balance_after': balanceAfter,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? person,
    DateTime? date,
    int? amount,
    String? transactionType,
    String? expenseType,
    String? paymentMethod,
    String? note,
    String? month,
    int? balanceAfter,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      person: person ?? this.person,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      expenseType: expenseType ?? this.expenseType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      month: month ?? this.month,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
