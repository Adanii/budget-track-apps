import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/widgets/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _transactionType = AppConstants.typeExpense;
  String _person = 'Afid';
  String _paymentMethod = 'Cash';
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
    final expenseType = _transactionType == AppConstants.typeIncome
        ? AppConstants.expenseNone
        : (amount < AppConstants.largeExpenseThreshold
              ? AppConstants.expenseSmall
              : AppConstants.expenseLarge);

    await ref
        .read(transactionActionProvider.notifier)
        .addTransaction(
          person: _person,
          date: _selectedDate,
          amount: amount,
          transactionType: _transactionType,
          expenseType: expenseType,
          paymentMethod: _paymentMethod,
          note: _noteController.text,
        );

    if (mounted) {
      ref.invalidate(latestBalanceProvider);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil disimpan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionActionProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: AppConstants.typeExpense,
                      label: Text('Pengeluaran'),
                    ),
                    ButtonSegment(
                      value: AppConstants.typeIncome,
                      label: Text('Pemasukan'),
                    ),
                  ],
                  selected: {_transactionType},
                  onSelectionChanged: (value) =>
                      setState(() => _transactionType = value.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor:
                        _transactionType == AppConstants.typeExpense
                        ? AppColors.expense
                        : AppColors.income,
                    selectedForegroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  initialValue: _person,
                  decoration: const InputDecoration(labelText: 'Person'),
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
                    decoration: const InputDecoration(labelText: 'Tanggal'),
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
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {}),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Wajib diisi' : null,
                ),
                if (_transactionType == AppConstants.typeExpense &&
                    _amountController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final amount =
                          int.tryParse(
                            _amountController.text.replaceAll('.', ''),
                          ) ??
                          0;
                      final isLarge =
                          amount >= AppConstants.largeExpenseThreshold;
                      return Text(
                        isLarge
                            ? '🔴 Pengeluaran Besar'
                            : '🟢 Pengeluaran Kecil',
                        style: TextStyle(
                          color: isLarge ? AppColors.expense : AppColors.income,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Metode Bayar',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: AppConstants.paymentMethods.map((m) {
                    final isSelected = _paymentMethod == m;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(m),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _paymentMethod = m);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (Opsional)',
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
