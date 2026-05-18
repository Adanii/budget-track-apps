import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/transaction/presentation/providers/transaction_providers.dart';
import 'package:fin_track/widgets/transaction_card.dart';
import 'package:fin_track/widgets/empty_state.dart';
import 'package:fin_track/widgets/loading_shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/widgets/main_layout.dart';

class FilteredTransactionsScreen extends ConsumerWidget {
  final String type; // 'income' or 'expense'
  final String month; // 'yyyy-MM'

  const FilteredTransactionsScreen({
    super.key,
    required this.type,
    required this.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsStreamProvider(month));
    final isIncome = type == AppConstants.typeIncome;
    final title = isIncome ? 'Pemasukan' : 'Pengeluaran';
    
    final date = DateFormat('yyyy-MM').parse(month);
    final monthName = DateFormat('MMMM yyyy').format(date);

    return MainLayout(
      title: '$title $monthName',
      child: transactionsAsync.when(
        data: (transactions) {
          final filtered = transactions.where((t) => t.transactionType == type).toList();
          
          if (filtered.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'Belum ada $title',
              subtitle: 'Tidak ada catatan $title di bulan ini.',
            ).animate().fadeIn();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final transaction = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TransactionCard(
                  transaction: transaction,
                  onDelete: () => _handleDelete(context, ref, transaction),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05),
              );
            },
          );
        },
        loading: () => const LoadingShimmer(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, TransactionEntity transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Transaksi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Anda yakin ingin menghapus transaksi ini?', style: GoogleFonts.outfit(color: context.colors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.outfit(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.expense,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(transactionActionProvider.notifier).deleteTransaction(transaction.id);
    }
  }
}
