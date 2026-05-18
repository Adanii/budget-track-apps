import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/domain/repositories/travel_planner_repository.dart';

class SearchHotelsUseCase {
  final TravelPlannerRepository _repository;

  const SearchHotelsUseCase(this._repository);

  Future<List<TravelPlaceEntity>> call(DestinationEntity destination) {
    return _repository.searchHotels(destination);
  }
}
