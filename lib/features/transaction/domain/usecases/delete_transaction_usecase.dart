import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';

class DeleteTransactionUseCase {
  final TransactionRepository repository;
  DeleteTransactionUseCase(this.repository);

  Future<void> call(String id) {
    return repository.deleteTransaction(id);
  }
}
