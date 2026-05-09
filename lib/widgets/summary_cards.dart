import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/models/transaction_model.dart';

class SummaryCardsWidget extends StatelessWidget {
  final List<TransactionModel> transactions;

  const SummaryCardsWidget({
    super.key,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((t) => t.transactionType == AppConstants.typeIncome)
        .fold(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.transactionType == AppConstants.typeExpense)
        .fold(0, (sum, t) => sum + t.amount);

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            label: 'Income',
            amount: income,
            color: AppColors.income,
            icon: Icons.arrow_downward_rounded,
            onTap: () => context.push('/transactions/${AppConstants.typeIncome}/${DateFormat('yyyy-MM').format(DateTime.now())}'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SummaryCard(
            label: 'Expense',
            amount: expense,
            color: AppColors.expense,
            icon: Icons.arrow_upward_rounded,
            onTap: () => context.push('/transactions/${AppConstants.typeExpense}/${DateFormat('yyyy-MM').format(DateTime.now())}'),
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const SummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(amount),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }
}
