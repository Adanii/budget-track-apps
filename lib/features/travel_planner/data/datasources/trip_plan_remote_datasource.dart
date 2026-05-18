import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fin_track/core/constants.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/trip_plan_entity.dart';

class TripPlanRemoteDataSource {
  final FirebaseFirestore _db;

  const TripPlanRemoteDataSource(this._db);

  Future<void> saveTripPlan(TripPlanEntity tripPlan) async {
    await _db.collection(AppConstants.tripPlansCollection).add({
      'destination': {
        'name': tripPlan.destination.name,
        'lat': tripPlan.destination.lat,
        'lng': tripPlan.destination.lng,
      },
      'selectedHotel': _placeToMap(tripPlan.selectedHotel),
      'restaurants': tripPlan.restaurants.map(_placeToMap).toList(),
      'summary': tripPlan.summary,
      'createdAt': Timestamp.fromDate(tripPlan.createdAt),
    });
  }

  Map<String, dynamic> _placeToMap(TravelPlaceEntity place) {
    return {
      'id': place.id,
      'name': place.name,
      'rating': place.rating,
      'reviewCount': place.reviewCount,
      'distance': place.distanceMeters,
      'lat': place.lat,
      'lng': place.lng,
      'score': place.score,
      'openNow': place.openNow,
      'photoReference': place.photoReference,
    };
  }
}
