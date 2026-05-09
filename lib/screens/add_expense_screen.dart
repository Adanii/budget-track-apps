import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/widgets/main_layout.dart';
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

    final amount = int.parse(_amountController.text.replaceAll('.', ''));
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
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengeluaran berhasil disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionActionProvider).isLoading;

    return MainLayout(
      title: 'Tambah Pengeluaran',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.remove_circle, color: AppColors.expense, size: 32),
                  SizedBox(width: 12),
                  Text(
                    'Catat Pengeluaran',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              DropdownButtonFormField<String>(
                initialValue: _person,
                decoration: const InputDecoration(
                  labelText: 'Siapa yang mengeluarkan?',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: ['Afid', 'Ayu']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _person = value!),
              ),
              const SizedBox(height: 16),
              InkWell(
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
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy').format(_selectedDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              if (_amountController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final amount = int.tryParse(
                          _amountController.text.replaceAll('.', ''),
                        ) ??
                        0;
                    final isLarge =
                        amount >= AppConstants.largeExpenseThreshold;
                    return Text(
                      isLarge ? '🔴 Pengeluaran Besar' : '🟢 Pengeluaran Kecil',
                      style: TextStyle(
                        color: isLarge
                            ? AppColors.expense
                            : AppColors.income,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Sumber Saldo',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.wallets.map((m) {
                  final isSelected = _paymentMethod == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _paymentMethod = m);
                    },
                    selectedColor: AppColors.expense,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.expense,
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
                    : const Text('Simpan Pengeluaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
