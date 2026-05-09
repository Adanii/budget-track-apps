// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/models/transaction_model.dart';
import 'package:fin_track/widgets/balance_header.dart';
import 'package:fin_track/widgets/transaction_card.dart';
import 'package:fin_track/widgets/loading_shimmer.dart';
import 'package:fin_track/widgets/empty_state.dart';
import 'package:fin_track/widgets/error_state.dart';
import 'package:fin_track/widgets/main_layout.dart';
import 'package:fin_track/widgets/wallet_list_widget.dart';
import 'package:fin_track/widgets/summary_cards.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(currentMonth),
    );
    final balanceAsync = ref.watch(latestBalanceProvider);
    final walletBalancesAsync = ref.watch(walletBalancesProvider);

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < AppConstants.mobileBreakpoint;

    return MainLayout(
      title: 'Dashboard',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(latestBalanceProvider);
          ref.invalidate(transactionsStreamProvider(currentMonth));
        },
        child: transactionsAsync.when(
          data: (transactions) => isMobile
              ? _buildMobileView(
                  context,
                  ref,
                  transactions,
                  balanceAsync,
                  walletBalancesAsync,
                )
              : _buildWebView(
                  context,
                  ref,
                  transactions,
                  balanceAsync,
                  walletBalancesAsync,
                ),
          loading: () => const LoadingShimmer(),
          error: (e, _) => ErrorState(
            message: 'Gagal memuat data: $e',
            onRetry: () =>
                ref.invalidate(transactionsStreamProvider(currentMonth)),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    AsyncValue<int> balanceAsync,
    AsyncValue<Map<String, int>> walletBalancesAsync,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: balanceAsync.when(
              data: (balance) => BalanceHeader(
                balance: balance,
                monthName: DateFormat('MMMM yyyy').format(DateTime.now()),
              ).animate().fadeIn().scale(curve: Curves.easeOutBack),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) =>
                  const Center(child: Text('Error loading balance')),
            ),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(
          child: walletBalancesAsync.when(
            data: (balances) => WalletListWidget(balances: balances),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SummaryCardsWidget(
              transactions: transactions,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        if (transactions.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Transactions',
              subtitle: 'Start by recording your first income or expense.',
              actionLabel: '+ Record Now',
              onAction: () => context.push('/add-expense'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final transaction = transactions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child:
                      TransactionCard(
                            transaction: transaction,
                            onDelete: () =>
                                _handleDelete(context, ref, transaction),
                          )
                          .animate()
                          .fadeIn(delay: (index * 50).ms)
                          .slideX(begin: 0.05),
                );
              }, childCount: transactions.length),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildWebView(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    AsyncValue<int> balanceAsync,
    AsyncValue<Map<String, int>> walletBalancesAsync,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final income = transactions
        .where((t) => t.transactionType == AppConstants.typeIncome)
        .fold(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.transactionType == AppConstants.typeExpense)
        .fold(0, (sum, t) => sum + t.amount);

    Map<String, int> paymentSummary = {};
    for (var m in AppConstants.wallets) {
      paymentSummary[m] = transactions
          .where(
            (t) =>
                t.transactionType == AppConstants.typeExpense &&
                t.paymentMethod == m,
          )
          .fold(0, (sum, t) => sum + t.amount);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Financial Overview',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn().slideX(begin: -0.1),
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildBalanceSection(
                      balanceAsync,
                      walletBalancesAsync,
                      income,
                      expense,
                    ).animate().fadeIn(delay: 300.ms).scale(),
                    const SizedBox(height: 24),
                    _buildDetailedTable(
                      paymentSummary,
                      currencyFormat,
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                flex: 3,
                child: _buildRecentTransactionsTable(
                  context,
                  ref,
                  transactions,
                  currencyFormat,
                ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(
    AsyncValue<int> balanceAsync,
    AsyncValue<Map<String, int>> walletBalancesAsync,
    int income,
    int expense,
  ) {
    return Card(
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [AppColors.card, AppColors.surface.withValues(alpha: 0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            balanceAsync.when(
              data: (balance) => Column(
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(balance),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const Text('Error loading balance'),
            ),
            const SizedBox(height: 24),
            walletBalancesAsync.when(
              data: (balances) => WalletListWidget(balances: balances),
              loading: () => const CircularProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildSimpleSummary(
                    'Income',
                    income,
                    AppColors.income,
                    Icons.arrow_downward_rounded,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white10),
                Expanded(
                  child: _buildSimpleSummary(
                    'Expense',
                    expense,
                    AppColors.expense,
                    Icons.arrow_upward_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleSummary(
    String label,
    int amount,
    Color color,
    IconData icon,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedTable(
    Map<String, int> paymentSummary,
    NumberFormat format,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...paymentSummary.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PaymentUtils.getPaymentColor(
                          e.key,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: PaymentUtils.getPaymentIcon(e.key),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      e.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      format.format(e.value),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsTable(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    NumberFormat format,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (transactions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: Text('No recent transactions'),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(3),
                  3: IntrinsicColumnWidth(),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'DATE',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'NOTE',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'AMOUNT',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...transactions
                      .take(10)
                      .map(
                        (t) => TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(DateFormat('dd MMM').format(t.date)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: [
                                  Icon(
                                    t.transactionType == AppConstants.typeIncome
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 14,
                                    color:
                                        t.transactionType ==
                                            AppConstants.typeIncome
                                        ? AppColors.income
                                        : AppColors.expense,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.transactionType == AppConstants.typeIncome
                                        ? 'Income'
                                        : 'Expense',
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                t.note.isEmpty ? '-' : t.note,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                format.format(t.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      t.transactionType ==
                                          AppConstants.typeIncome
                                      ? AppColors.income
                                      : AppColors.expense,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionModel transaction,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      await ref
          .read(transactionActionProvider.notifier)
          .deleteTransaction(transaction.id);
      ref.invalidate(latestBalanceProvider);
    }
  }
}
