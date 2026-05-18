import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/trip_plan_entity.dart';

abstract class TravelPlannerRepository {
  Future<DestinationEntity> searchDestination(String query);
  Future<List<TravelPlaceEntity>> searchHotels(DestinationEntity destination);
  Future<List<TravelPlaceEntity>> searchRestaurants(TravelPlaceEntity hotel);
  Future<void> saveTripPlan(TripPlanEntity tripPlan);
}
