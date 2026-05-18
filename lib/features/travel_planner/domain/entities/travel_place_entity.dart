enum TravelPlaceType { hotel, restaurant }

class TravelPlaceEntity {
  final String id;
  final String name;
  final TravelPlaceType type;
  final double rating;
  final int reviewCount;
  final int distanceMeters;
  final double lat;
  final double lng;
  final bool? openNow;
  final String? photoReference;
  final double score;

  /// Google Places priceLevel: 0 = gratis, 1 = murah, 2 = sedang, 3 = mahal, 4 = sangat mahal
  final int? priceLevel;

  const TravelPlaceEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.rating,
    required this.reviewCount,
    required this.distanceMeters,
    required this.lat,
    required this.lng,
    this.openNow,
    this.photoReference,
    this.score = 0,
    this.priceLevel,
  });

  /// Converts priceLevel to Rupiah symbols (Rp -- RpRpRpRp)
  String get priceLabel {
    if (priceLevel == null) return '';
    switch (priceLevel!) {
      case 0:
        return 'Gratis';
      case 1:
        return 'Rp';
      case 2:
        return 'Rp-Rp';
      case 3:
        return 'Rp-Rp-Rp';
      case 4:
        return 'Rp-Rp-Rp-Rp';
      default:
        return '';
    }
  }

  String get priceLabelFull {
    if (priceLevel == null) return '';
    switch (priceLevel!) {
      case 0:
        return 'Gratis';
      case 1:
        return 'Murah';
      case 2:
        return 'Sedang';
      case 3:
        return 'Mahal';
      case 4:
        return 'Sangat Mahal';
      default:
        return '';
    }
  }

  String get mapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$id';

  String get photoUrl {
    if (photoReference == null || photoReference!.isEmpty) return '';
    final encoded = Uri.encodeComponent(photoReference!);
    return 'https://us-central1-tracker-ayfid.cloudfunctions.net/placePhoto?ref=$encoded';
  }

  TravelPlaceEntity copyWith({double? score}) {
    return TravelPlaceEntity(
      id: id,
      name: name,
      type: type,
      rating: rating,
      reviewCount: reviewCount,
      distanceMeters: distanceMeters,
      lat: lat,
      lng: lng,
      openNow: openNow,
      photoReference: photoReference,
      score: score ?? this.score,
      priceLevel: priceLevel,
    );
  }
}
