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
import 'package:fin_track/models/wallet_model.dart';
import 'package:fin_track/providers/wallet_provider.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _selectedDateKey;
  String? _selectedWalletFilter; // null = Semua
  // Web-only filters: null = Semua
  String? _webDateFilter;
  String? _webWalletFilter;
  bool _isWebDateInitialized = false;

  List<String> _buildOrderedDates(String currentMonth) {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    final parsed = DateFormat('yyyy-MM').parse(currentMonth);
    final daysInMonth = DateUtils.getDaysInMonth(parsed.year, parsed.month);

    final allDates = List.generate(daysInMonth, (i) {
      final d = DateTime(parsed.year, parsed.month, i + 1);
      return DateFormat('yyyy-MM-dd').format(d);
    });

    // Today first, then backwards; if viewing another month show newest first
    final todayIndex = allDates.indexOf(todayStr);
    if (todayIndex == -1) return allDates.reversed.toList(); // past month → newest first
    // today → day 1 only (no future dates)
    return allDates.sublist(0, todayIndex + 1).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = ref.watch(currentMonthProvider);
    final transactionsAsync = ref.watch(
      transactionsStreamProvider(currentMonth),
    );
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > AppConstants.mobileBreakpoint;
    final wallets = ref.watch(walletsStreamProvider).value ?? [];

    return MainLayout(
      title: 'History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthHeader(context, ref, currentMonth),
          _buildSummaryBar(context, ref, transactionsAsync, isDesktop),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: _buildTransactionList(
                  transactionsAsync, ref, currentMonth, isDesktop, wallets,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context, WidgetRef ref, String currentMonth) {
    final date = DateFormat('yyyy-MM').parse(currentMonth);
    final monthName = DateFormat('MMMM yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Riwayat', style: GoogleFonts.outfit(
                fontSize: 28, fontWeight: FontWeight.bold,
              )),
              Text('Laporan keuangan bulan ini', style: GoogleFonts.outfit(
                fontSize: 13, color: AppColors.textSecondary,
              )),
            ],
          ),
          if (MediaQuery.of(context).size.width > AppConstants.mobileBreakpoint) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildWebFilterBar(ref),
              ),
            ),
          ] else
            const Spacer(),
          GestureDetector(
            onTap: () => _showMonthPicker(context, ref, currentMonth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(monthName, style: GoogleFonts.outfit(
                    fontSize: 13, color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  )),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.05);
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

  Widget _buildSummaryBar(BuildContext context, WidgetRef ref, AsyncValue transactionsAsync, bool isDesktop) {
    return transactionsAsync.when(
      data: (transactions) {
        final income = transactions
            .where((t) => t.transactionType == 'income')
            .fold(0, (acc, t) => acc + t.amount);
        final expense = transactions
            .where((t) => t.transactionType == 'expense')
            .fold(0, (acc, t) => acc + t.amount);
        final currencyFormat = NumberFormat.currency(
          locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0,
        );
        final net = income - expense;
        final isPositive = net >= 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              // Net balance highlight
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (isPositive ? AppColors.income : AppColors.expense).withValues(alpha: 0.15),
                      AppColors.card,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isPositive ? AppColors.income : AppColors.expense).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: isPositive ? AppColors.income : AppColors.expense,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Saldo Bulan Ini', style: GoogleFonts.outfit(
                          fontSize: 12, color: AppColors.textSecondary,
                        )),
                        Text(currencyFormat.format(net), style: GoogleFonts.outfit(
                          fontSize: 22, fontWeight: FontWeight.bold,
                          color: isPositive ? AppColors.income : AppColors.expense,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              // Income / Expense row
              Row(
                children: [
                  Expanded(child: _StatCard(
                    label: 'Pemasukan',
                    amount: currencyFormat.format(income),
                    color: AppColors.income,
                    icon: Icons.arrow_downward_rounded,
                    onTap: () {
                      final month = ref.read(currentMonthProvider);
                      context.push('/transactions/${AppConstants.typeIncome}/$month');
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(
                    label: 'Pengeluaran',
                    amount: currencyFormat.format(expense),
                    color: AppColors.expense,
                    icon: Icons.arrow_upward_rounded,
                    onTap: () {
                      final month = ref.read(currentMonthProvider);
                      context.push('/transactions/${AppConstants.typeExpense}/$month');
                    },
                  )),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
  Widget _buildTransactionList(
    AsyncValue transactionsAsync,
    WidgetRef ref,
    String currentMonth,
    bool isDesktop,
    List<WalletModel> wallets,
  ) {
    return transactionsAsync.when(
      data: (allTransactionsRaw) {
        final List<TransactionModel> allTransactions = allTransactionsRaw;
        
        if (allTransactions.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'Tidak ada transaksi',
            subtitle: 'Coba pilih bulan lain.',
          );
        }

        if (isDesktop) {
          // Build date chips: today first then descending to day 1
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

          final webDates = _buildOrderedDates(currentMonth);

          // Default selection on first load, or reset if month changed
          if (!_isWebDateInitialized || (_webDateFilter != null && !webDates.contains(_webDateFilter))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isWebDateInitialized = true;
                  _webDateFilter = webDates.first;
                });
              }
            });
          }
          
          // Apply web filters
          List<TransactionModel> webFiltered = allTransactions;
          if (_webDateFilter != null) {
            webFiltered = webFiltered
                .where((t) => DateFormat('yyyy-MM-dd').format(t.date) == _webDateFilter)
                .toList();
          }
          if (_webWalletFilter != null) {
            webFiltered = webFiltered
                .where((t) => t.paymentMethod == _webWalletFilter)
                .toList();
          }
          return _buildTransactionTable(webFiltered, ref, wallets);
        }

        // Build date list for this month
        final orderedDates = _buildOrderedDates(currentMonth);
        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // Reset if month changed
        if (_selectedDateKey == null || !orderedDates.contains(_selectedDateKey)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedDateKey = orderedDates.first);
          });
        }

        // Group by date
        final Map<String, List<TransactionModel>> grouped = {};
        for (final t in allTransactions) {
          final key = DateFormat('yyyy-MM-dd').format(t.date);
          grouped.putIfAbsent(key, () => []).add(t);
        }

        // Apply date + wallet filter
        final byDate = grouped[_selectedDateKey] ?? [];

        // Only show chips for wallets that actually appear in this date's transactions
        final usedWalletIds = byDate.map((t) => t.paymentMethod).toSet();
        final availableWallets = wallets.where((w) => usedWalletIds.contains(w.id)).toList();

        // Auto-reset filter if active wallet has no transactions on this date
        if (_selectedWalletFilter != null && !usedWalletIds.contains(_selectedWalletFilter)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedWalletFilter = null);
          });
        }

        final filteredList = _selectedWalletFilter == null
            ? byDate
            : byDate.where((t) => t.paymentMethod == _selectedWalletFilter).toList();

        return Column(
          children: [
            // Date Picker
            SizedBox(
              height: 86,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                itemCount: orderedDates.length,
                itemBuilder: (context, index) {
                  final dateKey = orderedDates[index];
                  final isSelected = dateKey == _selectedDateKey;
                  final isToday = dateKey == todayStr;
                  final parsed = DateFormat('yyyy-MM-dd').parse(dateKey);
                  final dayStr = DateFormat('dd').format(parsed);
                  final monthStr = DateFormat('MMM').format(parsed).toUpperCase();
                  final hasTransactions = grouped.containsKey(dateKey);

                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDateKey = dateKey),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 54,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isToday && !isSelected
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : isSelected
                                    ? AppColors.primary
                                    : Colors.white10,
                            width: isToday && !isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayStr,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              monthStr,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                            if (hasTransactions) ...[  
                              const SizedBox(height: 4),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ── Wallet Filter Chips ──────────────────────────────
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedWalletFilter = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedWalletFilter == null
                              ? AppColors.primary
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selectedWalletFilter == null
                                ? AppColors.primary
                                : Colors.white12,
                          ),
                        ),
                        child: Text(
                          'Semua',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedWalletFilter == null
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...availableWallets.map((w) {
                    final isActive = _selectedWalletFilter == w.id;
                    final color = PaymentUtils.getPaymentColor(w.bank);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() =>
                            _selectedWalletFilter = isActive ? null : w.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withValues(alpha: 0.2)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive ? color : Colors.white12,
                              width: isActive ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PaymentUtils.getPaymentIcon(w.bank, size: 13),
                              const SizedBox(width: 6),
                              Text(
                                w.displayName,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isActive
                                      ? color
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Transaction list for selected date
            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyDate()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredList[index];
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
                    ),
            ),
          ],
        );
      },
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyDate() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tidak ada transaksi',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada aktivitas keuangan\npada tanggal ini',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildTransactionTable(List<TransactionModel> transactions, WidgetRef ref, List<WalletModel> wallets) {
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
            final isIncome = t.transactionType == AppConstants.typeIncome;
            final isTransfer = t.transactionType == AppConstants.typeTransfer;
            
            final wallet = wallets.firstWhere((w) => w.id == t.paymentMethod, orElse: () => WalletModel(id: t.paymentMethod, bank: t.paymentMethod, name: '', createdAt: DateTime.now()));
            final destinationWallet = t.destinationWallet != null 
                ? wallets.firstWhere((w) => w.id == t.destinationWallet, orElse: () => WalletModel(id: t.destinationWallet!, bank: t.destinationWallet!, name: '', createdAt: DateTime.now()))
                : null;

            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd MMM yyyy').format(t.date))),
                DataCell(Text(t.person.isEmpty ? '-' : t.person)),
                DataCell(_buildCategoryBadge(t.expenseType, t.transactionType)),
                DataCell(Text(isTransfer ? '${wallet.displayName} → ${destinationWallet?.displayName ?? t.destinationWallet}' : wallet.displayName)),
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
                    '${isTransfer ? '' : (isIncome ? '+' : '-')}${currencyFormat.format(t.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTransfer ? AppColors.primary : (isIncome ? AppColors.income : AppColors.expense),
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

  Widget _buildCategoryBadge(String type, String transactionType) {
    if (transactionType == AppConstants.typeIncome) {
      return const _Badge(label: 'Income', color: AppColors.income);
    }
    if (transactionType == AppConstants.typeTransfer) {
      return const _Badge(label: 'Transfer', color: AppColors.primary);
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

  Widget _buildWebFilterBar(WidgetRef ref) {
    final currentMonth = ref.watch(currentMonthProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final webDates = _buildOrderedDates(currentMonth);
    final wallets = ref.watch(walletsStreamProvider).value ?? [];
    
    // Derive available wallets from current transactions (all in this month)
    final transactionsAsync = ref.watch(transactionsStreamProvider(currentMonth));
    final List<TransactionModel> allTransactions = transactionsAsync.value ?? [];
    final usedWalletIds = allTransactions.map((t) => t.paymentMethod).toSet();
    final availableWebWallets = wallets.where((w) => usedWalletIds.contains(w.id)).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 16),
            const SizedBox(width: 12),
            // Date Filter
            _buildWebDateChip('Semua', null),
            const SizedBox(width: 8),
            ...webDates.map((d) {
              final label = d == todayStr ? 'Today' : DateFormat('dd MMM').format(DateFormat('yyyy-MM-dd').parse(d));
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildWebDateChip(label, d),
              );
            }),
            Container(height: 20, width: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 8)),
            // Wallet Filter
            _buildWebWalletChip('Semua', null, Icons.all_inclusive_rounded, AppColors.primary),
            ...availableWebWallets.map((w) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _buildWebWalletChip(w.displayName, w.id, null, PaymentUtils.getPaymentColor(w.bank), wallet: w),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWebDateChip(String label, String? value) {
    final isSelected = _webDateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _webDateFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(label, style: GoogleFonts.outfit(
          fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        )),
      ),
    );
  }

  Widget _buildWebWalletChip(String label, String? value, IconData? icon, Color color, {WalletModel? wallet}) {
    final isSelected = _webWalletFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _webWalletFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 14),
            if (wallet != null) Padding(
              padding: const EdgeInsets.only(right: 6),
              child: PaymentUtils.getPaymentIcon(wallet.bank, size: 14),
            ),
            Text(label, style: GoogleFonts.outfit(
              fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
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

class _StatCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.outfit(
                  fontSize: 11, color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                )),
                const SizedBox(height: 2),
                Text(amount, style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color,
                ),
                overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }
}
