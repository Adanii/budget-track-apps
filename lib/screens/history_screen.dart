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
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/models/transaction_model.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(currentMonth),
    );
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > AppConstants.mobileBreakpoint;

    return MainLayout(
      title: 'History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(context, ref, currentMonth),
          _buildSummaryBar(transactionsAsync, isDesktop),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: _buildTransactionList(transactionsAsync, ref, currentMonth, isDesktop),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, WidgetRef ref, String currentMonth) {
    final date = DateFormat('yyyy-MM').parse(currentMonth);
    final monthName = DateFormat('MMMM').format(date);
    final yearName = DateFormat('yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: InkWell(
        onTap: () => _showMonthPicker(context, ref, currentMonth),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthName,
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  Text(
                    yearName,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref, String currentMonth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MonthPickerModal(
        initialMonth: currentMonth,
        onSelected: (month) {
          ref.read(currentMonthProvider.notifier).state = month;
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildSummaryBar(AsyncValue transactionsAsync, bool isDesktop) {
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

        final net = income - expense;
        final largestExpense = transactions.where((t) => t.transactionType == 'expense').isEmpty 
            ? 0 
            : transactions.where((t) => t.transactionType == 'expense').map((e) => e.amount).reduce((a, b) => a > b ? a : b);

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _MiniSummary(
                label: 'TOTAL INCOME',
                amount: currencyFormat.format(income),
                color: AppColors.income,
                icon: Icons.arrow_upward_rounded,
              ),
              if (isDesktop) _buildDivider(),
              _MiniSummary(
                label: 'TOTAL EXPENSE',
                amount: currencyFormat.format(expense),
                color: AppColors.expense,
                icon: Icons.arrow_downward_rounded,
              ),
              if (isDesktop) _buildDivider(),
              _MiniSummary(
                label: 'NET BALANCE',
                amount: currencyFormat.format(net),
                color: AppColors.primary,
                icon: Icons.account_balance_wallet_rounded,
              ),
              if (isDesktop && transactions.isNotEmpty) ...[
                _buildDivider(),
                _MiniSummary(
                  label: 'LARGEST EXPENSE',
                  amount: currencyFormat.format(largestExpense),
                  color: AppColors.warning,
                  icon: Icons.trending_up_rounded,
                ),
                _buildDivider(),
                _MiniSummary(
                  label: 'TRANSACTIONS',
                  amount: '${transactions.length}',
                  color: AppColors.info,
                  icon: Icons.receipt_long_rounded,
                ),
              ],
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2);
      },
      loading: () => const SizedBox(height: 100),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildDivider() => Container(width: 1, height: 40, color: Colors.white10);

  Widget _buildTransactionList(
    AsyncValue transactionsAsync,
    WidgetRef ref,
    String currentMonth,
    bool isDesktop,
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

        if (isDesktop) {
          return _buildTransactionTable(transactions, ref);
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
                  ref.invalidate(walletBalancesProvider);
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

  Widget _buildTransactionTable(List<TransactionModel> transactions, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.white.withValues(alpha: 0.05),
        ),
        child: DataTable(
          horizontalMargin: 24,
          columnSpacing: 24,
          headingTextStyle: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
          columns: const [
            DataColumn(label: Text('DATE')),
            DataColumn(label: Text('PERSON')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('SUMBER')),
            DataColumn(label: Text('NOTE')),
            DataColumn(label: Text('AMOUNT'), numeric: true),
            DataColumn(label: Text('BALANCE'), numeric: true),
            DataColumn(label: Text('')),
          ],
          rows: transactions.asMap().entries.map((entry) {
            final t = entry.value;
            final isIncome = t.transactionType == 'income';

            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM yyyy').format(t.date))),
                DataCell(Text(t.person.isEmpty ? '-' : t.person)),
                DataCell(_buildCategoryBadge(t.expenseType, isIncome)),
                DataCell(Text(t.paymentMethod)),
                DataCell(
                  SizedBox(
                    width: 150,
                    child: Text(
                      t.note.isEmpty ? '-' : t.note,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '${isIncome ? '+' : '-'}${currencyFormat.format(t.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    currencyFormat.format(t.balanceAfter),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
                    onPressed: () async {
                      await ref.read(transactionActionProvider.notifier).deleteTransaction(t.id);
                      ref.invalidate(latestBalanceProvider);
                      ref.invalidate(walletBalancesProvider);
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildCategoryBadge(String type, bool isIncome) {
    if (isIncome) {
      return _Badge(label: 'Income', color: AppColors.income);
    }
    
    switch (type) {
      case AppConstants.expenseLarge:
        return _Badge(label: 'Large Exp', color: AppColors.expense);
      case AppConstants.expenseSmall:
        return _Badge(label: 'Small Exp', color: AppColors.primary);
      default:
        return _Badge(label: 'General', color: AppColors.textMuted);
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _MonthPickerModal extends StatefulWidget {
  final String initialMonth;
  final Function(String) onSelected;

  const _MonthPickerModal({
    required this.initialMonth,
    required this.onSelected,
  });

  @override
  State<_MonthPickerModal> createState() => _MonthPickerModalState();
}

class _MonthPickerModalState extends State<_MonthPickerModal> {
  late int selectedYear;
  late String selectedMonth;

  @override
  void initState() {
    super.initState();
    final date = DateFormat('yyyy-MM').parse(widget.initialMonth);
    selectedYear = date.year;
    selectedMonth = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => selectedYear--),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$selectedYear',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => setState(() => selectedYear++),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final monthStr = '$selectedYear-${month.toString().padLeft(2, '0')}';
              final isSelected = monthStr == selectedMonth;
              final displayName = DateFormat('MMMM').format(DateTime(selectedYear, month));

              return InkWell(
                onTap: () => widget.onSelected(monthStr),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppColors.primaryGradient : null,
                    color: isSelected ? null : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
