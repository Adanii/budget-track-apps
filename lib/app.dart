import 'package:flutter/material.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/screens/home_screen.dart';
import 'package:fin_track/screens/add_income_screen.dart';
import 'package:fin_track/screens/add_expense_screen.dart';
import 'package:fin_track/screens/history_screen.dart';
import 'package:fin_track/screens/filtered_transactions_screen.dart';
import 'package:fin_track/screens/transfer_screen.dart';
import 'package:fin_track/screens/wallet_management_screen.dart';
import 'package:go_router/go_router.dart';

class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/add-income',
          builder: (context, state) => const AddIncomeScreen(),
        ),
        GoRoute(
          path: '/add-expense',
          builder: (context, state) => const AddExpenseScreen(),
        ),
        GoRoute(
          path: '/transfer',
          builder: (context, state) => const TransferScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/wallets',
          builder: (context, state) => const WalletManagementScreen(),
        ),
        GoRoute(
          path: '/transactions/:type/:month',
          builder: (context, state) {
            final type = state.pathParameters['type']!;
            final month = state.pathParameters['month']!;
            return FilteredTransactionsScreen(type: type, month: month);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'BudgetTracker',
      theme: AppTheme.premiumDark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
