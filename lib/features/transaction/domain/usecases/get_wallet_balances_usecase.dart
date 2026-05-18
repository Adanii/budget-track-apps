import 'package:fin_track/features/transaction/domain/repositories/transaction_repository.dart';

class GetWalletBalancesUseCase {
  final TransactionRepository repository;
  GetWalletBalancesUseCase(this.repository);

  Future<Map<String, int>> call() {
    return repository.getWalletBalances();
  }
}
