import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/providers/wallet_provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class BalanceHeader extends ConsumerStatefulWidget {
  final int balance;
  final String monthName;
  final Map<String, int>? walletBalances;

  const BalanceHeader({
    super.key,
    required this.balance,
    required this.monthName,
    this.walletBalances,
  });

  @override
  ConsumerState<BalanceHeader> createState() => _BalanceHeaderState();
}

class _BalanceHeaderState extends ConsumerState<BalanceHeader>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _animController;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _expandAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isNegative = widget.balance < 0;
    final walletsAsync = ref.watch(walletsStreamProvider);
    final balances = widget.walletBalances ?? {};

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: _expanded ? 0.35 : 0.25),
              AppColors.card,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: _expanded ? 0.35 : 0.2),
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.monthName,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    size: 22,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Total Saldo',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.balance.toDouble()),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutExpo,
              builder: (context, value, _) {
                return Text(
                  currencyFormat.format(value.toInt()),
                  style: GoogleFonts.outfit(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: isNegative ? AppColors.expense : AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: isNegative ? AppColors.expense : AppColors.income,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isNegative ? 'Saldo negatif' : 'Saldo tersedia',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: isNegative ? AppColors.expense : AppColors.income,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _expanded ? 'Tutup rincian' : 'Lihat rincian',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            // ── Expandable Wallet Breakdown ──────────────────────────────
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1,
              child: walletsAsync.when(
                data: (wallets) {
                  final nonZeroWallets = wallets.where((w) => (balances[w.id] ?? 0) != 0).toList();
                  final allWallets = nonZeroWallets.isNotEmpty ? nonZeroWallets : wallets;
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...allWallets.asMap().entries.map((entry) {
                        final i = entry.key;
                        final wallet = entry.value;
                        final walletBalance = balances[wallet.id] ?? 0;
                        final color = PaymentUtils.getPaymentColor(wallet.bank);
                        final pct = widget.balance != 0
                            ? (walletBalance / widget.balance).clamp(0.0, 1.0)
                            : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: PaymentUtils.getPaymentIcon(wallet.bank, size: 14),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          wallet.displayName,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          currencyFormat.format(walletBalance),
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct.toDouble(),
                                        minHeight: 4,
                                        backgroundColor: Colors.white.withValues(alpha: 0.07),
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: 0.05),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
