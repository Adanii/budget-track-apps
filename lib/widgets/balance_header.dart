import 'package:flutter/material.dart';
import 'package:fin_track/core/theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class BalanceHeader extends StatelessWidget {
  final int balance;
  final String monthName;

  const BalanceHeader({
    super.key,
    required this.balance,
    required this.monthName,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isNegative = balance < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthName,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.primary.withValues(alpha: 0.6),
                size: 20,
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
            tween: Tween<double>(begin: 0, end: balance.toDouble()),
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
            ],
          ),
        ],
      ),
    );
  }
}
