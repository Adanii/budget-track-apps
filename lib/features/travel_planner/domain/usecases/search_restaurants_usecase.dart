import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/domain/repositories/travel_planner_repository.dart';

class SearchRestaurantsUseCase {
  final TravelPlannerRepository _repository;

  const SearchRestaurantsUseCase(this._repository);

  Future<List<TravelPlaceEntity>> call(TravelPlaceEntity hotel) {
    return _repository.searchRestaurants(hotel);
  }
}
