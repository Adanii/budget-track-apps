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

class AddIncomeScreen extends ConsumerStatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  ConsumerState<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends ConsumerState<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _noteController = TextEditingController();

  String _person = 'Afid';
  String? _paymentMethod;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.parse(
      ThousandsSeparatorFormatter.toRaw(_amountController.text),
    );

    await ref
        .read(transactionActionProvider.notifier)
        .addTransaction(
          person: _person,
          date: _selectedDate,
          amount: amount,
          transactionType: AppConstants.typeIncome,
          expenseType: AppConstants.expenseNone,
          paymentMethod: _paymentMethod!,
          note:
              '${_sourceController.text}${_noteController.text.isNotEmpty ? ' - ${_noteController.text}' : ''}',
        );

    if (mounted) {
      ref.invalidate(latestBalanceProvider);
      ref.invalidate(walletBalancesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Income saved successfully'),
          backgroundColor: context.colors.income,
        ),
      );
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionActionProvider).isLoading;
    final walletsAsync = ref.watch(walletsStreamProvider);

    return walletsAsync.when(
      data: (wallets) {
        if (wallets.isEmpty) {
          return MainLayout(
            title: 'Tambah Pemasukan',
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // Auto initialize
        if (_paymentMethod == null && wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _paymentMethod = wallets.first.id);
          });
        }

        return MainLayout(
          title: 'Tambah Pemasukan',
          child: CustomScrollView(
            slivers: [
              // Gradient Header SliverAppBar
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
                          context.colors.income.withValues(alpha: 0.25),
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
                                color: context.colors.income.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.add_chart_rounded,
                                color: context.colors.income,
                                size: 26,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Catat Pemasukan',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Catat sumber penghasilan Anda',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: context.colors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Form Content
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
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: context.colors.income.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOMINAL PEMASUKAN',
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
                                    color: context.colors.income,
                                  ),
                                  filled: false,
                                ),
                                style: GoogleFonts.outfit(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.income,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  ThousandsSeparatorFormatter(),
                                ],
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Masukkan nominal'
                                    : null,
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1),

                        const SizedBox(height: 24),
                        _sectionLabel('DETAIL PEMASUKAN'),
                        const SizedBox(height: 12),

                        // Person & Date Row
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
                                  decoration: const InputDecoration(
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
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _sourceController,
                          decoration: const InputDecoration(
                            labelText: 'Sumber Pemasukan',
                            hintText: 'mis. Gaji, Bonus, Freelance',
                            prefixIcon: Icon(Icons.source_rounded),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Wajib diisi' : null,
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            prefixIcon: Icon(Icons.notes_rounded),
                          ),
                          maxLength: 100,
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),
                        _sectionLabel('MASUK KE'),
                        const SizedBox(height: 12),

                        // Wallet Chips
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
                        ).animate().fadeIn(delay: 250.ms),

                        SizedBox(height: 40),

                        ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.income,
                                shadowColor: context.colors.income.withValues(
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
                                  : const Text('Simpan Pemasukan'),
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
        title: 'Tambah Pemasukan',
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
