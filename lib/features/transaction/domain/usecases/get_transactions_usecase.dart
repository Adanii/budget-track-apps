import 'package:fin_track/features/transaction/domain/entities/transaction_entity.dart';
import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;
  GetTransactionsUseCase(this.repository);

  Stream<List<TransactionEntity>> call(String month) {
    return repository.streamTransactions(month);
  }
}
