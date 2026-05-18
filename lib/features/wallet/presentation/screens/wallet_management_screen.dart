import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/wallet/domain/entities/wallet_entity.dart';
import 'package:fin_track/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:fin_track/features/transaction/presentation/providers/transaction_providers.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:fin_track/widgets/main_layout.dart';

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

    return MainLayout(
      title: 'Manajemen Wallet',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(context, ref),
        backgroundColor: context.colors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Tambah Wallet', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      child: walletsAsync.when(
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
              final color = PaymentUtils.getPaymentColor(wallet.bank, context);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PaymentUtils.getPaymentIcon(wallet.bank, context, size: 28),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.displayName,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
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
                      icon: Icon(
                        Icons.edit_rounded,
                        color: context.colors.textSecondary,
                      ),
                      onPressed: () =>
                          _showAddEditDialog(context, ref, wallet: wallet),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.expense.withValues(alpha: 0.8),
                      ),
                      onPressed: () =>
                          _showDeleteDialog(context, ref, wallet, balance),
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
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    WalletEntity wallet,
    int balance,
  ) {
    final hasBalance = balance != 0;
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.expense.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: context.colors.expense,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Hapus Wallet',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin menghapus wallet:',
              style: GoogleFonts.outfit(
                color: context.colors.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Text(
              wallet.displayName,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (hasBalance) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.colors.warning,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Wallet ini masih memiliki saldo ${currencyFormat.format(balance)}. Riwayat transaksi akan tetap ada.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: context.colors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 8),
            Text(
              'Aksi ini tidak dapat dibatalkan.',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.outfit(color: context.colors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.expense,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(walletActionProvider.notifier)
                  .deleteWallet(wallet.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Wallet "${wallet.displayName}" telah dihapus',
                    ),
                    backgroundColor: context.colors.expense,
                  ),
                );
              }
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
    BuildContext context,
    WidgetRef ref, {
    WalletEntity? wallet,
  }) {
    final isEdit = wallet != null;
    String selectedBank = wallet?.bank ?? AppConstants.banks.first;
    final nameController = TextEditingController(text: wallet?.name ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
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
                          color: context.colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded),
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
                      color: context.colors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.banks.map((bank) {
                      final isSelected = selectedBank == bank;
                      final color = PaymentUtils.getPaymentColor(bank, context);
                      return GestureDetector(
                        onTap: () => setState(() => selectedBank = bank),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.15)
                                : context.colors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.white12,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PaymentUtils.getPaymentIcon(bank, context, size: 14),
                              SizedBox(width: 6),
                              Text(
                                bank,
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : context.colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'NAMA TAMBAHAN (OPSIONAL)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
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
                        backgroundColor: context.colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () async {
                        final newWallet = WalletEntity(
                          id: isEdit ? wallet.id : const Uuid().v4(),
                          bank: selectedBank,
                          name: nameController.text.trim(),
                          createdAt: isEdit ? wallet.createdAt : DateTime.now(),
                        );

                        if (isEdit) {
                          await ref
                              .read(walletActionProvider.notifier)
                              .updateWallet(newWallet);
                        } else {
                          await ref
                              .read(walletActionProvider.notifier)
                              .addWallet(newWallet);
                        }

                        // Invalidate balances because display names might change, but wait,
                        // balances map uses id. The UI needs to redraw.
                        // Since we listen to streamWallets, UI will redraw.
                        if (context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Wallet berhasil disimpan'),
                            ),
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
