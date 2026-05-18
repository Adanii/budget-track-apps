import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';

class AddTransactionUseCase {
  final TransactionRepository repository;
  AddTransactionUseCase(this.repository);

  Future<void> call(TransactionEntity transaction) {
    return repository.addTransaction(transaction);
  }
}
