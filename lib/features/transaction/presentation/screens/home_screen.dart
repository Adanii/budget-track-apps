// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/transaction/presentation/providers/transaction_providers.dart';
import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/widgets/balance_header.dart';
import 'package:fin_track/widgets/transaction_card.dart';
import 'package:fin_track/widgets/loading_shimmer.dart';
import 'package:fin_track/widgets/error_state.dart';
import 'package:fin_track/widgets/main_layout.dart';
import 'package:fin_track/widgets/wallet_list_widget.dart';
import 'package:fin_track/widgets/summary_cards.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedDateKey;
  String? _selectedWalletFilter; // null = Semua
  // Web-only filters: null = Semua
  String?
  _webDateFilter; // null=Semua, 'today'=today's date string, or specific date
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

    // Reorder: today first, then backwards to day 1, then wrap to end of month
    final todayIndex = allDates.indexOf(todayStr);
    if (todayIndex == -1) return allDates.reversed.toList();
    // today → day 1 only (no future dates)
    return allDates.sublist(0, todayIndex + 1).reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
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
                  currentMonth,
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
    List<TransactionEntity> transactions,
    AsyncValue<int> balanceAsync,
    AsyncValue<Map<String, int>> walletBalancesAsync,
    String currentMonth,
  ) {
    final orderedDates = _buildOrderedDates(currentMonth);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Auto-select today (or first date in list) if nothing selected
    if (_selectedDateKey == null || !orderedDates.contains(_selectedDateKey)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedDateKey = orderedDates.first);
      });
    }

    // Group transactions by date
    final Map<String, List<TransactionEntity>> grouped = {};
    for (final t in transactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    // Apply date + wallet filter
    final byDate = grouped[_selectedDateKey] ?? [];

    // Only show chips for wallets that actually appear in this date's transactions
    final allWallets = ref.watch(walletsStreamProvider).value ?? [];
    final usedWalletIds = byDate.map((t) => t.paymentMethod).toSet();
    final availableWallets = allWallets
        .where((w) => usedWalletIds.contains(w.id))
        .toList();

    // Auto-reset filter if active wallet has no transactions on this date
    if (_selectedWalletFilter != null &&
        !usedWalletIds.contains(_selectedWalletFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedWalletFilter = null);
      });
    }

    final filteredList = _selectedWalletFilter == null
        ? byDate
        : byDate
              .where((t) => t.paymentMethod == _selectedWalletFilter)
              .toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: balanceAsync.when(
                  data: (balance) => walletBalancesAsync.when(
                    data: (walletBalances) => BalanceHeader(
                      balance: balance,
                      monthName: DateFormat('MMMM yyyy').format(DateTime.now()),
                      walletBalances: walletBalances,
                    ).animate().fadeIn().slideY(begin: -0.05),
                    loading: () => BalanceHeader(
                      balance: balance,
                      monthName: DateFormat('MMMM yyyy').format(DateTime.now()),
                    ).animate().fadeIn().slideY(begin: -0.05),
                    error: (e, st) => BalanceHeader(
                      balance: balance,
                      monthName: DateFormat('MMMM yyyy').format(DateTime.now()),
                    ),
                  ),
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (err, st) =>
                      const Center(child: Text('Error loading balance')),
                ),
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

            // ── Section Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Transaksi Terakhir',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Date Selector (today first, full month) ─────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 76,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: orderedDates.length,
                  itemBuilder: (context, index) {
                    final dateKey = orderedDates[index];
                    final isSelected = dateKey == _selectedDateKey;
                    final isToday = dateKey == todayStr;
                    final parsed = DateFormat('yyyy-MM-dd').parse(dateKey);
                    final dayStr = DateFormat('dd').format(parsed);
                    final monthStr = DateFormat(
                      'MMM',
                    ).format(parsed).toUpperCase();
                    final hasTransactions = grouped.containsKey(dateKey);

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDateKey = dateKey),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.primary
                                : context.colors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isToday && !isSelected
                                  ? context.colors.primary.withValues(
                                      alpha: 0.5,
                                    )
                                  : isSelected
                                  ? context.colors.primary
                                  : Colors.white10,
                              width: isToday && !isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: context.colors.primary.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
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
                                  color: isSelected
                                      ? Colors.white
                                      : context.colors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                monthStr,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white70
                                      : context.colors.textSecondary,
                                ),
                              ),
                              if (hasTransactions) ...[
                                SizedBox(height: 4),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : context.colors.primary,
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
            ),

            SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Wallet Filter Chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // "Semua" chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedWalletFilter = null),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _selectedWalletFilter == null
                                ? context.colors.primary
                                : context.colors.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedWalletFilter == null
                                  ? context.colors.primary
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
                                  : context.colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // One chip per wallet
                    ...availableWallets.map((w) {
                      final isActive = _selectedWalletFilter == w.id;
                      final color = PaymentUtils.getPaymentColor(
                        w.bank,
                        context,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(
                            () =>
                                _selectedWalletFilter = isActive ? null : w.id,
                          ),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? color.withValues(alpha: 0.2)
                                  : context.colors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? color : Colors.white12,
                                width: isActive ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PaymentUtils.getPaymentIcon(w.bank, context, size: 13),
                                SizedBox(width: 6),
                                Text(
                                  w.displayName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? color
                                        : context.colors.textSecondary,
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
            ),

            SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Daily summary
            if (filteredList.isNotEmpty)
              SliverToBoxAdapter(child: _buildDailySummary(filteredList)),

            // ── Transactions for selected date ──────────────────────────
            if (filteredList.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(
                              alpha: 0.08,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            size: 40,
                            color: context.colors.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada transaksi',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Belum ada aktivitas keuangan\npada tanggal ini',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final transaction = filteredList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                  }, childCount: filteredList.length),
                ),
              ),

            SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
        // FAB
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionSheet(context),
            backgroundColor: context.colors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: Text(
              'Catat',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
        ),
      ],
    );
  }

  Widget _buildWebView(
    BuildContext context,
    WidgetRef ref,
    List<TransactionEntity> transactions,
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
        .fold(0, (acc, t) => acc + t.amount);
    final expense = transactions
        .where((t) => t.transactionType == AppConstants.typeExpense)
        .fold(0, (acc, t) => acc + t.amount);

    final dynamicWallets = ref.watch(walletsStreamProvider).value ?? [];
    Map<String, int> walletExpense = {};
    Map<String, int> walletIncome = {};
    for (final w in dynamicWallets) {
      walletExpense[w.id] = transactions
          .where(
            (t) =>
                t.transactionType == AppConstants.typeExpense &&
                t.paymentMethod == w.id,
          )
          .fold(0, (acc, t) => acc + t.amount);
      walletIncome[w.id] = transactions
          .where(
            (t) =>
                t.transactionType == AppConstants.typeIncome &&
                t.paymentMethod == w.id,
          )
          .fold(0, (acc, t) => acc + t.amount);
    }

    // Build date chips: today first then descending to day 1
    final currentMonth = ref.read(currentMonthProvider);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final webDates = _buildOrderedDates(currentMonth); // today→day1

    // Init web date filter to today on first load, or reset if month changed
    if (!_isWebDateInitialized ||
        (_webDateFilter != null && !webDates.contains(_webDateFilter))) {
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
    List<TransactionEntity> webFiltered = transactions;
    if (_webDateFilter != null) {
      webFiltered = webFiltered
          .where(
            (t) => DateFormat('yyyy-MM-dd').format(t.date) == _webDateFilter,
          )
          .toList();
    }
    if (_webWalletFilter != null) {
      webFiltered = webFiltered
          .where((t) => t.paymentMethod == _webWalletFilter)
          .toList();
    }

    // Derive wallet chips from ALL transactions (not just filtered)
    final usedWalletIds = transactions.map((t) => t.paymentMethod).toSet();
    final availableWebWallets = dynamicWallets
        .where((w) => usedWalletIds.contains(w.id))
        .toList();

    // Auto-reset web wallet filter if not in available
    if (_webWalletFilter != null && !usedWalletIds.contains(_webWalletFilter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _webWalletFilter = null);
      });
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
                  Text(
                    'Dashboard',
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ringkasan keuangan Anda',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 16),
              // Date chips + wallet chips inline in header
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildWebFilterBar(
                    webDates,
                    todayStr,
                    availableWebWallets,
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideY(begin: -0.05),
          const SizedBox(height: 32),

          // Top Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  label: 'Total Saldo',
                  valueWidget: balanceAsync.when(
                    data: (b) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: b.toDouble()),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutExpo,
                      builder: (ctx, v, child) => Text(
                        currencyFormat.format(v.toInt()),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    loading: () => CircularProgressIndicator(strokeWidth: 2),
                    error: (e, st) => const Text('-'),
                  ),
                  icon: Icons.account_balance_wallet_rounded,
                  color: context.colors.primary,
                  gradient: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatTile(
                  label: 'Pemasukan',
                  valueWidget: Text(
                    currencyFormat.format(income),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.income,
                    ),
                  ),
                  icon: Icons.arrow_downward_rounded,
                  color: context.colors.income,
                  onTap: () => context.push(
                    '/transactions/${AppConstants.typeIncome}/${DateFormat('yyyy-MM').format(DateTime.now())}',
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatTile(
                  label: 'Pengeluaran',
                  valueWidget: Text(
                    currencyFormat.format(expense),
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.expense,
                    ),
                  ),
                  icon: Icons.arrow_upward_rounded,
                  color: context.colors.expense,
                  onTap: () => context.push(
                    '/transactions/${AppConstants.typeExpense}/${DateFormat('yyyy-MM').format(DateTime.now())}',
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatTile(
                  label: 'Transaksi',
                  valueWidget: Text(
                    '${transactions.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.colors.info,
                    ),
                  ),
                  icon: Icons.receipt_long_rounded,
                  color: context.colors.info,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
          const SizedBox(height: 24),

          // Wallet Balances
          walletBalancesAsync
              .when(
                data: (balances) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader(
                      'Sumber Saldo',
                      Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 12),
                    WalletListWidget(balances: balances),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              )
              .animate()
              .fadeIn(delay: 200.ms),
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
                      ref: ref,
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                    const SizedBox(height: 24),
                    _buildWalletSummaryTable(
                      title: 'Pengeluaran per Sumber',
                      icon: Icons.pie_chart_outline_rounded,
                      walletData: walletExpense,
                      format: currencyFormat,
                      ref: ref,
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    if (_webDateFilter != null && webFiltered.isNotEmpty)
                      _buildDailySummary(webFiltered),
                    _buildRecentTransactionsTable(
                      context,
                      ref,
                      webFiltered,
                      currencyFormat,
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebFilterBar(
    List<String> webDates,
    String todayStr,
    List<WalletEntity> wallets,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              color: context.colors.primary,
              size: 16,
            ),
            const SizedBox(width: 12),
            // Date Filter
            _buildWebDateChip('Semua', null),
            const SizedBox(width: 8),
            ...webDates.map((d) {
              final label = d == todayStr
                  ? 'Today'
                  : DateFormat(
                      'dd MMM',
                    ).format(DateFormat('yyyy-MM-dd').parse(d));
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildWebDateChip(label, d),
              );
            }),
            Container(
              height: 20,
              width: 1,
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            // Wallet Filter
            _buildWebWalletChip(
              'Semua',
              null,
              Icons.all_inclusive_rounded,
              context.colors.primary,
            ),
            ...wallets.map(
              (w) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildWebWalletChip(
                  w.displayName,
                  w.id,
                  null,
                  PaymentUtils.getPaymentColor(w.bank, context),
                  wallet: w,
                ),
              ),
            ),
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
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? context.colors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? context.colors.primary
                : context.colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildWebWalletChip(
    String label,
    String? value,
    IconData? icon,
    Color color, {
    WalletEntity? wallet,
  }) {
    final isSelected = _webWalletFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _webWalletFilter = value),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: isSelected ? color : context.colors.textSecondary,
                size: 14,
              ),
            if (wallet != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: PaymentUtils.getPaymentIcon(wallet.bank, context, size: 14),
              ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary(List<TransactionEntity> transactions) {
    final dailyIncome = transactions
        .where((t) => t.transactionType == AppConstants.typeIncome)
        .fold(0, (sum, t) => sum + t.amount);
    final dailyExpense = transactions
        .where((t) => t.transactionType == AppConstants.typeExpense)
        .fold(0, (sum, t) => sum + t.amount);

    if (dailyIncome == 0 && dailyExpense == 0) return const SizedBox.shrink();

    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (dailyIncome > 0)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.income.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      color: context.colors.income,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pemasukan Harian',
                            style: GoogleFonts.outfit(
                              color: context.colors.income.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            format.format(dailyIncome),
                            style: GoogleFonts.outfit(
                              color: context.colors.income,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (dailyIncome > 0 && dailyExpense > 0) SizedBox(width: 12),
          if (dailyExpense > 0)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.colors.expense.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.expense.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      color: context.colors.expense,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengeluaran Harian',
                            style: GoogleFonts.outfit(
                              color: context.colors.expense.withValues(
                                alpha: 0.8,
                              ),
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            format.format(dailyExpense),
                            style: GoogleFonts.outfit(
                              color: context.colors.expense,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
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
            color: gradient ? null : context.colors.card,
            gradient: gradient
                ? LinearGradient(
                    colors: [
                      context.colors.primary.withValues(alpha: 0.2),
                      context.colors.card,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
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
                  Spacer(),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
        Icon(icon, color: context.colors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWalletSummaryTable({
    required String title,
    required IconData icon,
    required Map<String, int> walletData,
    required NumberFormat format,
    required WidgetRef ref,
  }) {
    final walletList = ref.watch(walletsStreamProvider).value ?? [];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title, icon),
          const SizedBox(height: 20),
          ...walletData.entries.map((e) {
            final w = walletList.firstWhere(
              (wallet) => wallet.id == e.key,
              orElse: () => WalletEntity(
                id: e.key,
                bank: e.key,
                name: '',
                createdAt: DateTime.now(),
              ),
            );
            final color = PaymentUtils.getPaymentColor(w.bank, context);
            final maxValue = walletData.values.isEmpty
                ? 0
                : walletData.values.reduce((a, b) => a > b ? a : b);
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
                    child: PaymentUtils.getPaymentIcon(w.bank, context, size: 16),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          w.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                  Text(
                    format.format(e.value),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: e.value > 0 ? color : context.colors.textMuted,
                    ),
                  ),
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
    List<TransactionEntity> transactions,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionHeader('Aktivitas Terakhir', Icons.receipt_long_rounded),
              Spacer(),
              TextButton(
                onPressed: () => context.push('/history'),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(color: context.colors.primary, fontSize: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (transactions.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text(
                  'Belum ada transaksi',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
            )
          else
            ...transactions.take(10).map((t) {
              final isIncome = t.transactionType == AppConstants.typeIncome;
              final color = isIncome
                  ? context.colors.income
                  : context.colors.expense;
              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
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
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: color,
                        size: 14,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.note.isEmpty
                                ? (isIncome ? 'Pemasukan' : 'Pengeluaran')
                                : t.note,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${DateFormat('dd MMM yyyy').format(t.date)} · ${t.paymentMethod}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: context.colors.textMuted,
                            ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          t.person,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: context.colors.textMuted,
                          ),
                        ),
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
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
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
                    onPressed: () {
                      context.pop();
                      context.go('/add-income');
                    },
                    icon: Icon(Icons.add_rounded),
                    label: const Text('Income'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.income,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.go('/add-expense');
                    },
                    icon: Icon(Icons.remove_rounded),
                    label: const Text('Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.expense,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context.pop();
                context.go('/add-adjustment');
              },
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Penyesuaian Saldo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade800,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity transaction,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Delete Transaction?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: context.colors.expense,
                ),
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
