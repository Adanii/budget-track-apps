import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';

class GetLatestBalanceUseCase {
  final TransactionRepository repository;
  GetLatestBalanceUseCase(this.repository);

  Future<int> call() {
    return repository.getLatestBalance();
  }
}
