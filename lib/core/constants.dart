class AppConstants {
  static const String appName = 'Budget Tracker';
  static const double maxWebWidth = 1200.0;
  static const double mobileBreakpoint = 600.0;

  // Firestore Collection Names
  static const String transactionsCollection = 'transactions';
  static const String walletsCollection = 'wallets';

  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  static const String typeTransfer = 'transfer';

  // Expense Categories
  static const String expenseSmall = 'small_expense';
  static const String expenseLarge = 'large_expense';
  static const String expenseNone = 'none';

  // Banks (Dasar sumber saldo untuk ikon/warna)
  static const List<String> banks = ['Mandiri', 'BCA', 'GoPay', 'SeaBank', 'Superbank', 'Bank Jago', 'Cash', 'Lainnya'];

  // Threshold for large expense
  static const int largeExpenseThreshold = 200000;
}
