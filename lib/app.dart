import 'package:flutter/material.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/features/transaction/presentation/screens/home_screen.dart';
import 'package:fin_track/features/transaction/presentation/screens/add_income_screen.dart';
import 'package:fin_track/features/transaction/presentation/screens/add_expense_screen.dart';
import 'package:fin_track/features/transaction/presentation/screens/add_adjustment_screen.dart';
import 'package:fin_track/features/transaction/presentation/screens/history_screen.dart';
import 'package:fin_track/features/transaction/presentation/screens/filtered_transactions_screen.dart';
import 'package:fin_track/features/transaction/presentation/screens/transfer_screen.dart';
import 'package:fin_track/features/travel_planner/presentation/screens/hotel_restaurants_screen.dart';
import 'package:fin_track/features/travel_planner/presentation/screens/travel_plan_screen.dart';
import 'package:fin_track/features/wallet/presentation/screens/wallet_management_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:fin_track/core/constants.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/providers/theme_provider.dart';

class FinTrackApp extends ConsumerWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
          path: '/add-adjustment',
          builder: (context, state) => const AddAdjustmentScreen(),
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
          path: '/travel-plan',
          builder: (context, state) => const TravelPlanScreen(),
        ),
        GoRoute(
          path: '/travel-plan/hotel',
          builder: (context, state) => const HotelRestaurantsScreen(),
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
      title: AppConstants.appName,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
