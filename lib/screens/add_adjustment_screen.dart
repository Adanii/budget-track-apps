import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:fin_track/utils/currency_formatter.dart';
import 'package:fin_track/providers/wallet_provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AddAdjustmentScreen extends ConsumerStatefulWidget {
  const AddAdjustmentScreen({super.key});

  @override
  ConsumerState<AddAdjustmentScreen> createState() => _AddAdjustmentScreenState();
}

class _AddAdjustmentScreenState extends ConsumerState<AddAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _adjustmentDirection = AppConstants.typeAdjustmentAdd;
  String _person = 'Afid';
  String? _paymentMethod;
  DateTime _selectedDate = DateTime.now();

  // Colors for each direction
  Color get _directionColor =>
      _adjustmentDirection == AppConstants.typeAdjustmentAdd
          ? AppColors.income
          : AppColors.expense;

  IconData get _directionIcon =>
      _adjustmentDirection == AppConstants.typeAdjustmentAdd
          ? Icons.add_circle_rounded
          : Icons.remove_circle_rounded;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.parse(
      ThousandsSeparatorFormatter.toRaw(_amountController.text),
    );

    await ref.read(transactionActionProvider.notifier).addTransaction(
      person: _person,
      date: _selectedDate,
      amount: amount,
      transactionType: _adjustmentDirection,
      expenseType: AppConstants.expenseNone,
      paymentMethod: _paymentMethod!,
      note: _noteController.text.isEmpty ? 'Penyesuaian Saldo' : _noteController.text,
    );

    if (mounted) {
      ref.invalidate(latestBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Penyesuaian saldo berhasil disimpan'),
          backgroundColor: _directionColor,
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
          return const Scaffold(body: Center(child: Text('Loading wallets...')));
        }

        if (_paymentMethod == null && wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _paymentMethod = wallets.first.id);
          });
        }

        final selectedWallet = wallets.firstWhere(
          (w) => w.id == _paymentMethod,
          orElse: () => wallets.first,
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.background,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => context.go('/'),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _directionColor.withValues(alpha: 0.3),
                          AppColors.background,
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
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _directionColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(_directionIcon, color: _directionColor, size: 26),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Penyesuaian Saldo',
                              style: GoogleFonts.outfit(
                                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _adjustmentDirection == AppConstants.typeAdjustmentAdd
                                    ? 'Tambah saldo tanpa mencatat pemasukan'
                                    : 'Kurangi saldo tanpa mencatat pengeluaran',
                                key: ValueKey(_adjustmentDirection),
                                style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
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

              // ── Form ──────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Tambah / Kurangi Toggle ──────────────────────
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              _buildDirectionToggle(
                                AppConstants.typeAdjustmentAdd,
                                Icons.add_rounded,
                                'Tambah Saldo',
                                AppColors.income,
                              ),
                              _buildDirectionToggle(
                                AppConstants.typeAdjustmentSub,
                                Icons.remove_rounded,
                                'Kurangi Saldo',
                                AppColors.expense,
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        // ── Saldo Dompet Banner ──────────────────────────
                        walletBalancesAsync.when(
                          data: (balances) {
                            if (_paymentMethod == null) return const SizedBox.shrink();
                            final balance = balances[_paymentMethod!] ?? 0;
                            final color = PaymentUtils.getPaymentColor(selectedWallet.bank);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.15), AppColors.card],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: PaymentUtils.getPaymentIcon(selectedWallet.bank, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo ${selectedWallet.displayName}',
                                        style: GoogleFonts.outfit(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(balance),
                                        style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.1);
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, st) => const SizedBox.shrink(),
                        ),

                        // ── Nominal ──────────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _directionColor.withValues(alpha: 0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOMINAL PENYESUAIAN',
                                style: GoogleFonts.outfit(
                                  fontSize: 11, fontWeight: FontWeight.bold,
                                  color: AppColors.textMuted, letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _amountController,
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: const TextStyle(color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  prefixStyle: GoogleFonts.outfit(
                                    fontSize: 28, fontWeight: FontWeight.bold, color: _directionColor,
                                  ),
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 36, fontWeight: FontWeight.bold, color: _directionColor,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [ThousandsSeparatorFormatter()],
                                onChanged: (_) => setState(() {}),
                                validator: (v) => v == null || v.isEmpty ? 'Masukkan nominal' : null,
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        // ── Sumber Dompet ─────────────────────────────────
                        _sectionLabel('SUMBER DOMPET'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: wallets.map((w) {
                            final isSelected = _paymentMethod == w.id;
                            final color = PaymentUtils.getPaymentColor(w.bank);
                            return GestureDetector(
                              onTap: () => setState(() => _paymentMethod = w.id),
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
                                    PaymentUtils.getPaymentIcon(w.bank, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      w.displayName,
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
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 32),

                        // ── Detail Transaksi ─────────────────────────────
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
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                                  if (date != null) setState(() => _selectedDate = date);
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Tanggal',
                                    prefixIcon: Icon(Icons.calendar_month_rounded),
                                  ),
                                  child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            prefixIcon: Icon(Icons.notes_rounded),
                            hintText: 'Biarkan kosong untuk catatan otomatis',
                          ),
                          maxLength: 100,
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 40),

                        // ── Submit Button ────────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [_directionColor, _directionColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _directionColor.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: isLoading ? null : _submit,
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(_directionIcon, color: Colors.white, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            _adjustmentDirection == AppConstants.typeAdjustmentAdd
                                                ? 'Tambah Saldo Sekarang'
                                                : 'Kurangi Saldo Sekarang',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 250.ms).scale(begin: const Offset(0.95, 0.95)),

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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildDirectionToggle(String value, IconData icon, String label, Color color) {
    final isSelected = _adjustmentDirection == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _adjustmentDirection = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.5) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 11, fontWeight: FontWeight.bold,
        color: _directionColor, letterSpacing: 1.5,
      ),
    );
  }
}
