import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/repositories/travel_planner_repository.dart';

class SearchDestinationUseCase {
  final TravelPlannerRepository _repository;

  const SearchDestinationUseCase(this._repository);

  Future<DestinationEntity> call(String query) {
    return _repository.searchDestination(query);
  }
}
