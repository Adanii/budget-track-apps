import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/transaction/presentation/providers/transaction_providers.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:fin_track/utils/currency_formatter.dart';
import 'package:fin_track/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:fin_track/widgets/main_layout.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _person = 'Afid';
  String? _paymentMethod;
  String? _destinationWallet;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == _destinationWallet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sumber dan Tujuan saldo tidak boleh sama'),
          backgroundColor: context.colors.expense,
        ),
      );
      return;
    }

    final amount = int.parse(
      ThousandsSeparatorFormatter.toRaw(_amountController.text),
    );

    await ref
        .read(transactionActionProvider.notifier)
        .addTransaction(
          person: _person,
          date: _selectedDate,
          amount: amount,
          transactionType: AppConstants.typeTransfer,
          expenseType: AppConstants.expenseNone,
          paymentMethod: _paymentMethod!,
          destinationWallet: _destinationWallet,
          note: _noteController.text.isEmpty
              ? 'Transfer'
              : _noteController.text,
        );

    if (mounted) {
      ref.invalidate(latestBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Transfer berhasil disimpan'),
          backgroundColor: context.colors.primary,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionActionProvider).isLoading;
    final walletBalancesAsync = ref.watch(walletBalancesProvider);
    final walletsAsync = ref.watch(walletsStreamProvider);

    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) {
          return MainLayout(
            title: 'Transfer Saldo',
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // Auto initialize
        if (_paymentMethod == null && wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _paymentMethod = wallets.first.id);
          });
        }
        if (_destinationWallet == null && wallets.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _destinationWallet = wallets.last.id);
          });
        } else if (_destinationWallet == null && wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _destinationWallet = wallets.first.id);
          });
        }

        final selectedWallet = wallets.firstWhere(
          (w) => w.id == _paymentMethod,
          orElse: () => wallets.first,
        );

        return MainLayout(
          title: 'Transfer Saldo',
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: context.colors.background,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.go('/'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.colors.primary.withValues(alpha: 0.3),
                          context.colors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.swap_horiz_rounded,
                                color: context.colors.primary,
                                size: 26,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Transfer Saldo',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pindahkan saldo antar dompet',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner Saldo
                        walletBalancesAsync.when(
                          data: (balances) {
                            if (_paymentMethod == null) {
                              return const SizedBox.shrink();
                            }
                            final balance = balances[_paymentMethod!] ?? 0;
                            final color = PaymentUtils.getPaymentColor(
                              selectedWallet.bank,
                              context,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withValues(alpha: 0.15),
                                    context.colors.card,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: PaymentUtils.getPaymentIcon(
                                      selectedWallet.bank,
                                      context,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo ${selectedWallet.displayName}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'id_ID',
                                          symbol: 'Rp ',
                                          decimalDigits: 0,
                                        ).format(balance),
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.1);
                          },
                          loading: () => Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, st) => const SizedBox.shrink(),
                        ),

                        // Amount Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOMINAL TRANSFER',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textMuted,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  prefixText: 'Rp ',
                                  hintStyle: TextStyle(
                                    color: context.colors.textMuted,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  prefixStyle: GoogleFonts.outfit(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.primary,
                                  ),
                                  filled: false,
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.primary,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  ThousandsSeparatorFormatter(),
                                ],
                                onChanged: (_) => setState(() {}),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Masukkan nominal'
                                    : null,
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 24),
                        _sectionLabel('DARI SUMBER'),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: wallets.map((w) {
                            final isSelected = _paymentMethod == w.id;
                            final color = PaymentUtils.getPaymentColor(
                              w.bank,
                              context,
                            );
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _paymentMethod = w.id),
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
                                    PaymentUtils.getPaymentIcon(
                                      w.bank,
                                      context,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      w.displayName,
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
                        ).animate().fadeIn(delay: 100.ms),

                        SizedBox(height: 24),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color: context.colors.primary,
                              size: 20,
                            ),
                          ).animate().fadeIn(delay: 150.ms),
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel('KE TUJUAN'),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: wallets.map((w) {
                            final isSelected = _destinationWallet == w.id;
                            final color = PaymentUtils.getPaymentColor(
                              w.bank,
                              context,
                            );
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _destinationWallet = w.id),
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
                                    PaymentUtils.getPaymentIcon(
                                      w.bank,
                                      context,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      w.displayName,
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
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 32),
                        _sectionLabel('DETAIL TRANSAKSI'),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _person,
                                decoration: const InputDecoration(
                                  labelText: 'Oleh Siapa',
                                  prefixIcon: Icon(Icons.person_rounded),
                                ),
                                items: ['Afid', 'Ayu']
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(() => _person = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() => _selectedDate = date);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Tanggal',
                                    prefixIcon: Icon(
                                      Icons.calendar_month_rounded,
                                    ),
                                  ),
                                  child: Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_selectedDate),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 250.ms),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            prefixIcon: Icon(Icons.notes_rounded),
                            hintText: 'Biarkan kosong untuk catatan otomatis',
                          ),
                          maxLength: 100,
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 40),

                        ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.primary,
                                shadowColor: context.colors.primary.withValues(
                                  alpha: 0.4,
                                ),
                                elevation: 8,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Simpan Transfer'),
                            )
                            .animate()
                            .fadeIn(delay: 350.ms)
                            .scale(begin: const Offset(0.95, 0.95)),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const MainLayout(
        title: 'Transfer Saldo',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => MainLayout(
        title: 'Error',
        child: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: context.colors.primary,
        letterSpacing: 1.5,
      ),
    );
  }
}
