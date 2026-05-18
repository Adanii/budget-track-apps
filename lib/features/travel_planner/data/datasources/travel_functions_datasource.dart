import 'package:cloud_functions/cloud_functions.dart';
import 'package:fin_track/features/travel_planner/domain/entities/destination_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/place_details_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';

class TravelFunctionsDataSource {
  final FirebaseFunctions _functions;

  const TravelFunctionsDataSource(this._functions);

  Future<DestinationEntity> searchDestination(String query) async {
    final result = await _functions.httpsCallable('searchDestination').call({
      'query': query,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return DestinationEntity(
      name: data['name'] as String,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
    );
  }

  Future<List<TravelPlaceEntity>> searchHotels(
    DestinationEntity destination,
  ) async {
    final result = await _functions.httpsCallable('searchHotels').call({
      'destination': destination.name,
      'lat': destination.lat,
      'lng': destination.lng,
    });
    return _placesFrom(result.data, TravelPlaceType.hotel);
  }

  Future<List<TravelPlaceEntity>> searchRestaurants(
    TravelPlaceEntity hotel,
  ) async {
    final result = await _functions.httpsCallable('searchRestaurants').call({
      'hotelId': hotel.id,
      'hotelName': hotel.name,
      'lat': hotel.lat,
      'lng': hotel.lng,
    });
    return _placesFrom(result.data, TravelPlaceType.restaurant);
  }

  Future<PlaceDetails> getPlaceDetails(String placeId) async {
    final result = await _functions.httpsCallable('getPlaceReviews').call({
      'placeId': placeId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);

    final rawReviews = (data['reviews'] as List?) ?? [];
    final reviews = rawReviews.map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      return PlaceReview(
        authorName: m['authorName'] as String? ?? '',
        authorPhoto: m['authorPhoto'] as String? ?? '',
        rating: (m['rating'] as num?)?.toDouble() ?? 0,
        text: m['text'] as String? ?? '',
        relativeTime: m['relativeTime'] as String? ?? '',
      );
    }).toList();

    return PlaceDetails(
      priceLevel: (data['priceLevel'] as num?)?.toInt(),
      editorialSummary: data['editorialSummary'] as String?,
      address: data['address'] as String?,
      website: data['website'] as String?,
      reviews: reviews,
    );
  }

  List<TravelPlaceEntity> _placesFrom(Object? raw, TravelPlaceType type) {
    final items = (raw as List).cast<Map<Object?, Object?>>();
    return items.map((item) {
      final data = Map<String, dynamic>.from(item);
      return TravelPlaceEntity(
        id: data['id'] as String,
        name: data['name'] as String,
        type: type,
        rating: (data['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
        distanceMeters: (data['distance'] as num?)?.toInt() ?? 0,
        lat: (data['lat'] as num).toDouble(),
        lng: (data['lng'] as num).toDouble(),
        openNow: data['openNow'] as bool?,
        photoReference: data['photoReference'] as String?,
        score: (data['score'] as num?)?.toDouble() ?? 0,
        priceLevel: (data['priceLevel'] as num?)?.toInt(),
      );
    }).toList();
  }
}
