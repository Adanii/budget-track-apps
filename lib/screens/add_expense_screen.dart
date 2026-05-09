import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/utils/payment_utils.dart';
import 'package:fin_track/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _person = 'Afid';
  String _paymentMethod = AppConstants.wallets.first;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.parse(ThousandsSeparatorFormatter.toRaw(_amountController.text));
    final expenseType = amount < AppConstants.largeExpenseThreshold
        ? AppConstants.expenseSmall
        : AppConstants.expenseLarge;

    await ref.read(transactionActionProvider.notifier).addTransaction(
          person: _person,
          date: _selectedDate,
          amount: amount,
          transactionType: AppConstants.typeExpense,
          expenseType: expenseType,
          paymentMethod: _paymentMethod,
          note: _noteController.text,
        );

    if (mounted) {
      ref.invalidate(latestBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Pengeluaran berhasil disimpan'),
          backgroundColor: AppColors.expense,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionActionProvider).isLoading;
    final amount = int.tryParse(ThousandsSeparatorFormatter.toRaw(_amountController.text)) ?? 0;
    final isLarge = _amountController.text.isNotEmpty && amount >= AppConstants.largeExpenseThreshold;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.go('/'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.expense.withValues(alpha: 0.3), AppColors.background],
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
                            color: AppColors.expense.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.expense, size: 26),
                        ),
                        const SizedBox(height: 12),
                        Text('Catat Pengeluaran',
                            style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('Kelola pengeluaran Anda dengan bijak',
                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary)),
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
                    // Amount Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isLarge
                              ? AppColors.expense.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NOMINAL', style: GoogleFonts.outfit(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: AppColors.textMuted, letterSpacing: 1.5,
                          )),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: 'Rp ',
                              hintStyle: const TextStyle(color: AppColors.textMuted),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              prefixStyle: GoogleFonts.outfit(
                                fontSize: 28, fontWeight: FontWeight.bold,
                                color: AppColors.expense,
                              ),
                              filled: false,
                            ),
                            style: GoogleFonts.outfit(
                              fontSize: 36, fontWeight: FontWeight.bold,
                              color: AppColors.expense,
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsSeparatorFormatter()],
                            onChanged: (_) => setState(() {}),
                            validator: (v) => v == null || v.isEmpty ? 'Masukkan nominal' : null,
                          ),
                          if (_amountController.text.isNotEmpty) ...[
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  isLarge ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                  color: isLarge ? AppColors.expense : AppColors.income,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isLarge ? 'Pengeluaran Besar (> Rp 200rb)' : 'Pengeluaran Normal',
                                  style: TextStyle(
                                    color: isLarge ? AppColors.expense : AppColors.income,
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                    const SizedBox(height: 24),
                    _sectionLabel('DETAIL TRANSAKSI'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _person,
                            decoration: const InputDecoration(
                              labelText: 'Siapa',
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
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (Opsional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                        hintText: 'Untuk apa?',
                      ),
                      maxLength: 100,
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 24),
                    _sectionLabel('SUMBER SALDO'),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: AppConstants.wallets.map((m) {
                        final isSelected = _paymentMethod == m;
                        final color = PaymentUtils.getPaymentColor(m);
                        return GestureDetector(
                          onTap: () => setState(() => _paymentMethod = m),
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
                                PaymentUtils.getPaymentIcon(m, size: 14),
                                const SizedBox(width: 6),
                                Text(m, style: TextStyle(
                                  color: isSelected ? color : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                )),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                        shadowColor: AppColors.expense.withValues(alpha: 0.4),
                        elevation: 8,
                      ),
                      child: isLoading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan Pengeluaran'),
                    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.outfit(
      fontSize: 11, fontWeight: FontWeight.bold,
      color: AppColors.primary, letterSpacing: 1.5,
    ));
  }
}
