class AppConstants {
  static const String appName = 'FinTrack';
  static const double maxWebWidth = 1200.0;
  static const double mobileBreakpoint = 600.0;
  
  // Firestore Collection Names
  static const String transactionsCollection = 'transactions';
  
  // Transaction Types
  static const String typeIncome = 'income';
  static const String typeExpense = 'expense';
  
  // Expense Categories
  static const String expenseSmall = 'small_expense';
  static const String expenseLarge = 'large_expense';
  static const String expenseNone = 'none';
  
  // Payment Methods
  static const List<String> paymentMethods = ['Cash', 'QR', 'Debit'];
  
  // Threshold for large expense
  static const int largeExpenseThreshold = 200000;
}
