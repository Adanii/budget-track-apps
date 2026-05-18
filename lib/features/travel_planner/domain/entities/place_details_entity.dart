class PlaceReview {
  final String authorName;
  final String authorPhoto;
  final double rating;
  final String text;
  final String relativeTime;

  const PlaceReview({
    required this.authorName,
    required this.authorPhoto,
    required this.rating,
    required this.text,
    required this.relativeTime,
  });
}

class PlaceDetails {
  final int? priceLevel;
  final String? editorialSummary;
  final String? address;
  final String? website;
  final List<PlaceReview> reviews;

  const PlaceDetails({
    this.priceLevel,
    this.editorialSummary,
    this.address,
    this.website,
    required this.reviews,
  });
}
