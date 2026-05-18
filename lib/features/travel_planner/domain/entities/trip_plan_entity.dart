import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';

class TripPlanEntity {
  final String id;
  final DestinationEntity destination;
  final TravelPlaceEntity selectedHotel;
  final List<TravelPlaceEntity> restaurants;
  final String summary;
  final DateTime createdAt;

  const TripPlanEntity({
    required this.id,
    required this.destination,
    required this.selectedHotel,
    required this.restaurants,
    required this.summary,
    required this.createdAt,
  });
}
