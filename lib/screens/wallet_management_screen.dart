import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/models/wallet_model.dart';
import 'package:fin_track/providers/wallet_provider.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class WalletManagementScreen extends ConsumerWidget {
  const WalletManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsStreamProvider);
    final balancesAsync = ref.watch(walletBalancesProvider);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Manajemen Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return const Center(child: Text('Belum ada wallet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final balance = balancesAsync.when(
                data: (b) => b[wallet.id] ?? 0,
                loading: () => 0,
                error: (_, x) => 0,
              );
              final color = PaymentUtils.getPaymentColor(wallet.bank);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PaymentUtils.getPaymentIcon(wallet.bank, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(balance),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary),
                      onPressed: () => _showAddEditDialog(context, ref, wallet: wallet),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: AppColors.expense.withValues(alpha: 0.8)),
                      onPressed: () => _showDeleteDialog(context, ref, wallet, balance),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Tambah Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, WalletModel wallet, int balance) {
    final hasBalance = balance != 0;
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.expense.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Hapus Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus wallet:',
              style: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              wallet.displayName,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (hasBalance) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wallet ini masih memiliki saldo ${currencyFormat.format(balance)}. Riwayat transaksi akan tetap ada.',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Aksi ini tidak dapat dibatalkan.',
              style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.outfit(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(walletActionProvider.notifier).deleteWallet(wallet.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wallet "${wallet.displayName}" telah dihapus'),
                    backgroundColor: AppColors.expense,
                  ),
                );
              }
            },
            child: Text('Hapus', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref, {WalletModel? wallet}) {
    final isEdit = wallet != null;
    String selectedBank = wallet?.bank ?? AppConstants.banks.first;
    final nameController = TextEditingController(text: wallet?.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Wallet' : 'Tambah Wallet',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PILIH BANK / TIPE',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.banks.map((bank) {
                      final isSelected = selectedBank == bank;
                      final color = PaymentUtils.getPaymentColor(bank);
                      return GestureDetector(
                        onTap: () => setState(() => selectedBank = bank),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PaymentUtils.getPaymentIcon(bank, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                bank,
                                style: TextStyle(
                                  color: isSelected ? color : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'NAMA TAMBAHAN (OPSIONAL)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Misal: Afid, Ayu, atau Tabungan',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final newWallet = WalletModel(
                          id: isEdit ? wallet.id : const Uuid().v4(),
                          bank: selectedBank,
                          name: nameController.text.trim(),
                          createdAt: isEdit ? wallet.createdAt : DateTime.now(),
                        );

                        if (isEdit) {
                          await ref.read(walletActionProvider.notifier).updateWallet(newWallet);
                        } else {
                          await ref.read(walletActionProvider.notifier).addWallet(newWallet);
                        }

                        // Invalidate balances because display names might change, but wait, 
                        // balances map uses id. The UI needs to redraw.
                        // Since we listen to streamWallets, UI will redraw.
                        if (context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wallet berhasil disimpan')),
                          );
                        }
                      },
                      child: Text(
                        'Simpan Wallet',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
