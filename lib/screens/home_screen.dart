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
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: balanceAsync.when(
                  data: (balance) => BalanceHeader(
                    balance: balance,
                    monthName: DateFormat('MMMM yyyy').format(DateTime.now()),
                  ).animate().fadeIn().slideY(begin: -0.05),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(child: Text('Error loading balance')),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: walletBalancesAsync.when(
                data: (balances) => WalletListWidget(balances: balances),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SummaryCardsWidget(
                  transactions: transactions,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            if (transactions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Text('Transaksi Terakhir',
                          style: GoogleFonts.outfit(
                            fontSize: 16, fontWeight: FontWeight.bold,
                          )),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push('/history'),
                        child: Text('Lihat Semua',
                            style: TextStyle(color: AppColors.primary, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            if (transactions.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No Transactions',
                  subtitle: 'Start by recording your first income or expense.',
                  actionLabel: '+ Record Now',
                  onAction: () => _showAddTransactionSheet(context),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = transactions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TransactionCard(
                        transaction: transaction,
                        onDelete: () => _handleDelete(context, ref, transaction),
                      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05),
                    );
                  }, childCount: transactions.length),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        // FAB
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionSheet(context),
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text('Catat', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
        ),
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
      locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
    );
    final income = transactions
        .where((t) => t.transactionType == AppConstants.typeIncome)
        .fold(0, (acc, t) => acc + t.amount);
    final expense = transactions
        .where((t) => t.transactionType == AppConstants.typeExpense)
        .fold(0, (acc, t) => acc + t.amount);

    Map<String, int> walletExpense = {};
    Map<String, int> walletIncome = {};
    for (var m in AppConstants.wallets) {
      walletExpense[m] = transactions
          .where((t) => t.transactionType == AppConstants.typeExpense && t.paymentMethod == m)
          .fold(0, (acc, t) => acc + t.amount);
      walletIncome[m] = transactions
          .where((t) => t.transactionType == AppConstants.typeIncome && t.paymentMethod == m)
          .fold(0, (acc, t) => acc + t.amount);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dashboard', style: GoogleFonts.outfit(
                    fontSize: 30, fontWeight: FontWeight.bold,
                  )),
                  Text('Ringkasan keuangan Anda', style: GoogleFonts.outfit(
                    fontSize: 14, color: AppColors.textSecondary,
                  )),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),
          const SizedBox(height: 32),

          // Top Stats Row
          Row(
            children: [
              Expanded(child: _buildStatTile(
                label: 'Total Saldo',
                valueWidget: balanceAsync.when(
                  data: (b) => TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: b.toDouble()),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutExpo,
                    builder: (ctx, v, child) => Text(currencyFormat.format(v.toInt()),
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  ),
                  loading: () => const CircularProgressIndicator(strokeWidth: 2),
                  error: (e, st) => const Text('-'),
                ),
                icon: Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                gradient: true,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatTile(
                label: 'Pemasukan',
                valueWidget: Text(currencyFormat.format(income),
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.income)),
                icon: Icons.arrow_downward_rounded,
                color: AppColors.income,
                onTap: () => context.push('/transactions/${AppConstants.typeIncome}/${DateFormat('yyyy-MM').format(DateTime.now())}'),
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatTile(
                label: 'Pengeluaran',
                valueWidget: Text(currencyFormat.format(expense),
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.expense)),
                icon: Icons.arrow_upward_rounded,
                color: AppColors.expense,
                onTap: () => context.push('/transactions/${AppConstants.typeExpense}/${DateFormat('yyyy-MM').format(DateTime.now())}'),
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatTile(
                label: 'Transaksi',
                valueWidget: Text('${transactions.length}',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.info)),
                icon: Icons.receipt_long_rounded,
                color: AppColors.info,
              )),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
          const SizedBox(height: 24),

          // Wallet Balances
          walletBalancesAsync.when(
            data: (balances) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Sumber Saldo', Icons.account_balance_wallet_outlined),
                const SizedBox(height: 12),
                WalletListWidget(balances: balances),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),

          // Main Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildWalletSummaryTable(
                      title: 'Pemasukan per Sumber',
                      icon: Icons.pie_chart_outline_rounded,
                      walletData: walletIncome,
                      format: currencyFormat,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _buildWalletSummaryTable(
                      title: 'Pengeluaran per Sumber',
                      icon: Icons.pie_chart_outline_rounded,
                      walletData: walletExpense,
                      format: currencyFormat,
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildRecentTransactionsTable(context, ref, transactions, currencyFormat)
                    .animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String label,
    required Widget valueWidget,
    required IconData icon,
    required Color color,
    bool gradient = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: gradient ? null : AppColors.card,
            gradient: gradient ? LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.card],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ) : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(label, style: GoogleFonts.outfit(
            fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500,
          )),
          const SizedBox(height: 4),
          valueWidget,
        ],
      ),
    ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(
          fontSize: 16, fontWeight: FontWeight.bold,
        )),
      ],
    );
  }


  Widget _buildWalletSummaryTable({
    required String title,
    required IconData icon,
    required Map<String, int> walletData,
    required NumberFormat format,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          const SizedBox(height: 20),
          ...walletData.entries.map((e) {
            final color = PaymentUtils.getPaymentColor(e.key);
            final maxValue = walletData.values.isEmpty ? 0 : walletData.values.reduce((a, b) => a > b ? a : b);
            final double progressValue = maxValue == 0 ? 0 : e.value / maxValue;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PaymentUtils.getPaymentIcon(e.key, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key, style: GoogleFonts.outfit(
                          fontSize: 13, fontWeight: FontWeight.w600,
                        )),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: Colors.white10,
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(format.format(e.value), style: GoogleFonts.outfit(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: e.value > 0 ? color : AppColors.textMuted,
                  )),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTable(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('Aktivitas Terakhir', Icons.receipt_long_rounded),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/history'),
                child: Text('Lihat Semua', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('Belum ada transaksi', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...transactions.take(10).map((t) {
              final isIncome = t.transactionType == AppConstants.typeIncome;
              final color = isIncome ? AppColors.income : AppColors.expense;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: color, size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.note.isEmpty ? (isIncome ? 'Pemasukan' : 'Pengeluaran') : t.note,
                            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${DateFormat('dd MMM yyyy').format(t.date)} · ${t.paymentMethod}',
                            style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncome ? '+' : '-'} ${format.format(t.amount)}',
                          style: GoogleFonts.outfit(
                            fontSize: 14, fontWeight: FontWeight.bold, color: color,
                          ),
                        ),
                        Text(t.person, style: GoogleFonts.outfit(
                          fontSize: 11, color: AppColors.textMuted,
                        )),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Record Transaction',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { context.pop(); context.go('/add-income'); },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.income,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () { context.pop(); context.go('/add-expense'); },
                    icon: const Icon(Icons.remove_rounded),
                    label: const Text('Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.expense,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
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
