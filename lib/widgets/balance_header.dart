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

    return Column(
      children: [
        Text(
          monthName,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: balance.toDouble()),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutExpo,
          builder: (context, value, child) {
            return Text(
              currencyFormat.format(value.toInt()),
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            );
          },
        ),
      ],
    );
  }
}
