import 'package:flutter/material.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/models/transaction_model.dart';
import 'package:fin_track/core/constants.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/models/wallet_model.dart';
import 'package:fin_track/providers/wallet_provider.dart';

class TransactionCard extends ConsumerWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsStreamProvider).value ?? [];
    final wallet = wallets.firstWhere((w) => w.id == transaction.paymentMethod, orElse: () => WalletModel(id: transaction.paymentMethod, bank: transaction.paymentMethod, name: '', createdAt: DateTime.now()));
    final destinationWallet = transaction.destinationWallet != null 
        ? wallets.firstWhere((w) => w.id == transaction.destinationWallet, orElse: () => WalletModel(id: transaction.destinationWallet!, bank: transaction.destinationWallet!, name: '', createdAt: DateTime.now()))
        : null;

    final isIncome = transaction.transactionType == AppConstants.typeIncome;
    final isTransfer = transaction.transactionType == AppConstants.typeTransfer;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isTransfer ? Icons.swap_horiz_rounded : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                          size: 16,
                          color: isTransfer ? AppColors.primary : (isIncome ? AppColors.income : AppColors.expense),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          transaction.person,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      DateFormat('dd MMM yyyy').format(transaction.date),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (transaction.note.isNotEmpty) ...[
                  Text(
                    transaction.note,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _getPaymentIcon(transaction.paymentMethod),
                        const SizedBox(width: 6),
                        Text(
                          isTransfer ? '${wallet.displayName} → ${destinationWallet?.displayName ?? transaction.destinationWallet}' : wallet.displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Text(
                      '${isTransfer ? '' : (isIncome ? '+' : '-')} ${currencyFormat.format(transaction.amount)}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isTransfer ? AppColors.primary : (isIncome ? AppColors.income : AppColors.expense),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash': return const Icon(Icons.money, color: AppColors.warning, size: 16);
      case 'QR': return const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 16);
      case 'Debit': return const Icon(Icons.credit_card, color: Colors.purple, size: 16);
      default: return const Icon(Icons.payment, size: 16);
    }
  }
}
