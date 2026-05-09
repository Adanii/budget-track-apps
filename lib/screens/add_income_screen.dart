import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/providers/transaction_provider.dart';
import 'package:fin_track/widgets/main_layout.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
  String _paymentMethod = 'Cash';
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

    final amount = int.parse(_amountController.text.replaceAll('.', ''));

    await ref.read(transactionActionProvider.notifier).addTransaction(
          person: _person,
          date: _selectedDate,
          amount: amount,
          transactionType: AppConstants.typeIncome,
          expenseType: AppConstants.expenseNone,
          paymentMethod: _paymentMethod,
          note: '${_sourceController.text}${_noteController.text.isNotEmpty ? ' - ${_noteController.text}' : ''}',
        );

    if (mounted) {
      ref.invalidate(latestBalanceProvider);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(transactionActionProvider).isLoading;

    return MainLayout(
      title: 'Add Income',
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.income.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.add_chart_rounded, color: AppColors.income, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Record Income',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ).animate().fadeIn().slideX(begin: -0.1),
              const SizedBox(height: 40),
              
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _person,
                decoration: const InputDecoration(
                  labelText: 'Who received it?',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                items: ['Afid', 'Ayu']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _person = value!),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'Source of Income',
                  hintText: 'e.g. Salary, Bonus, Freelance',
                  prefixIcon: Icon(Icons.source_rounded),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 200.ms),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Transaction Details'),
              const SizedBox(height: 16),
              Row(
                children: [
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
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: 'Rp ',
                  prefixIcon: Icon(Icons.account_balance_wallet_rounded),
                ),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.income),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ).animate().fadeIn(delay: 400.ms),
              
              const SizedBox(height: 24),
              const Text('Payment Method', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: AppConstants.paymentMethods.map((m) {
                  final isSelected = _paymentMethod == m;
                  return ChoiceChip(
                    label: Text(m),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _paymentMethod = m);
                    },
                    selectedColor: AppColors.income.withValues(alpha: 0.2),
                    side: BorderSide(color: isSelected ? AppColors.income : Colors.white10),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.income : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  shadowColor: AppColors.income.withValues(alpha: 0.4),
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Income'),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
        letterSpacing: 1.5,
      ),
    );
  }
}
