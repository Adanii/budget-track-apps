/// Pure Dart entity — no framework or database dependencies.
class TransactionEntity {
  final String id;
  final String person;
  final DateTime date;
  final int amount;
  final String transactionType;
  final String expenseType;
  final String paymentMethod;
  final String? destinationWallet;
  final String note;
  final String month;
  final int balanceAfter;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.person,
    required this.date,
    required this.amount,
    required this.transactionType,
    required this.expenseType,
    required this.paymentMethod,
    this.destinationWallet,
    required this.note,
    required this.month,
    required this.balanceAfter,
    required this.createdAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? person,
    DateTime? date,
    int? amount,
    String? transactionType,
    String? expenseType,
    String? paymentMethod,
    String? destinationWallet,
    String? note,
    String? month,
    int? balanceAfter,
    DateTime? createdAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      person: person ?? this.person,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      expenseType: expenseType ?? this.expenseType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      destinationWallet: destinationWallet ?? this.destinationWallet,
      note: note ?? this.note,
      month: month ?? this.month,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
