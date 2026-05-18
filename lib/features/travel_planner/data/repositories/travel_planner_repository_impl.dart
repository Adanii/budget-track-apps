import 'package:fin_track/features/travel_planner/data/datasources/travel_functions_datasource.dart';
import 'package:fin_track/features/travel_planner/data/datasources/trip_plan_remote_datasource.dart';
import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/trip_plan_entity.dart';
import 'package:fin_track/features/travel_planner/domain/repositories/travel_planner_repository.dart';

class TravelPlannerRepositoryImpl implements TravelPlannerRepository {
  final TravelFunctionsDataSource _functionsDataSource;
  final TripPlanRemoteDataSource _remoteDataSource;

  const TravelPlannerRepositoryImpl({
    required TravelFunctionsDataSource functionsDataSource,
    required TripPlanRemoteDataSource remoteDataSource,
  })  : _functionsDataSource = functionsDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<DestinationEntity> searchDestination(String query) {
    return _functionsDataSource.searchDestination(query);
  }

  @override
  Future<List<TravelPlaceEntity>> searchHotels(DestinationEntity destination) async {
    return _functionsDataSource.searchHotels(destination);
  }

  @override
  Future<List<TravelPlaceEntity>> searchRestaurants(TravelPlaceEntity hotel) async {
    return _functionsDataSource.searchRestaurants(hotel);
  }

  @override
  Future<void> saveTripPlan(TripPlanEntity tripPlan) {
    return _remoteDataSource.saveTripPlan(tripPlan);
  }
}
