import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/widgets/transaction_card.dart';
import 'package:fin_track/widgets/loading_shimmer.dart';
import 'package:fin_track/widgets/empty_state.dart';
import 'package:fin_track/widgets/main_layout.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(currentMonth),
    );

    // Generate last 12 months for selection
    final months = List.generate(12, (index) {
      final date = DateTime.now().subtract(Duration(days: 30 * index));
      return DateFormat('yyyy-MM').format(date);
    });

    return MainLayout(
      title: 'History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildMonthPicker(ref, months, currentMonth),
          _buildSummaryBar(transactionsAsync),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: _buildTransactionList(transactionsAsync, ref, currentMonth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPicker(
    WidgetRef ref,
    List<String> months,
    String currentMonth,
  ) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final monthStr = months[index];
          final isSelected = monthStr == currentMonth;
          final date = DateFormat('yyyy-MM').parse(monthStr);
          final displayMonth = DateFormat('MMM').format(date).toUpperCase();
          final displayYear = DateFormat('yyyy').format(date);

          return GestureDetector(
            onTap: () => ref.read(currentMonthProvider.notifier).state = monthStr,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                  width: 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayMonth,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    displayYear,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: isSelected ? Colors.white.withValues(alpha: 0.7) : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (index * 30).ms).scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }

  Widget _buildSummaryBar(AsyncValue transactionsAsync) {
    return transactionsAsync.when(
      data: (transactions) {
        final income = transactions
            .where((t) => t.transactionType == 'income')
            .fold(0, (sum, t) => sum + t.amount);
        final expense = transactions
            .where((t) => t.transactionType == 'expense')
            .fold(0, (sum, t) => sum + t.amount);
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniSummary(
                label: 'INCOME',
                amount: currencyFormat.format(income),
                color: AppColors.income,
                icon: Icons.arrow_upward_rounded,
              ),
              Container(width: 1, height: 30, color: Colors.white10),
              _MiniSummary(
                label: 'EXPENSE',
                amount: currencyFormat.format(expense),
                color: AppColors.expense,
                icon: Icons.arrow_downward_rounded,
              ),
              Container(width: 1, height: 30, color: Colors.white10),
              _MiniSummary(
                label: 'NET',
                amount: currencyFormat.format(income - expense),
                color: AppColors.primary,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2);
      },
      loading: () => const SizedBox(height: 100),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildTransactionList(
    AsyncValue transactionsAsync,
    WidgetRef ref,
    String currentMonth,
  ) {
    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'No transactions found',
            subtitle: 'Try selecting a different month.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TransactionCard(
                transaction: transaction,
                onDelete: () async {
                  await ref
                      .read(transactionActionProvider.notifier)
                      .deleteTransaction(transaction.id);
                  ref.invalidate(latestBalanceProvider);
                },
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
          },
        );
      },
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _MiniSummary extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _MiniSummary({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          amount,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
