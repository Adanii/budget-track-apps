import 'package:fin_track/core/theme.dart';
import 'package:fin_track/features/travel_planner/domain/entities/place_details_entity.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/presentation/providers/travel_planner_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Section Widget ─────────────────────────────────────────────────────────────
class TravelPlaceSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<TravelPlaceEntity> places;
  final TravelPlaceEntity? selectedPlace;
  final ValueChanged<TravelPlaceEntity>? onPlaceTap;
  final ValueChanged<TravelPlaceEntity>? onPlaceSelected;
  final String emptyText;

  const TravelPlaceSection({
    super.key,
    required this.title,
    required this.icon,
    required this.places,
    this.selectedPlace,
    this.onPlaceTap,
    this.onPlaceSelected,
    this.emptyText = 'Belum ada rekomendasi.',
  });

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return _EmptyState(icon: icon, text: emptyText);
    }

    return Column(
      children: places.asMap().entries.map((entry) {
        final place = entry.value;
        return TravelPlaceCard(
          rank: entry.key + 1,
          place: place,
          isSelected: selectedPlace?.id == place.id,
          onTap: () {
            onPlaceSelected?.call(place);
            if (onPlaceTap != null) onPlaceTap!(place);
          },
        ).animate().fadeIn(
              delay: Duration(milliseconds: 80 * entry.key),
            ).slideY(begin: 0.1);
      }).toList(),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: context.colors.primary.withValues(alpha: 0.5),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              text,
              style: GoogleFonts.outfit(
                color: context.colors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Place Card ─────────────────────────────────────────────────────────────────
class TravelPlaceCard extends StatefulWidget {
  final int rank;
  final TravelPlaceEntity place;
  final bool isSelected;
  final VoidCallback? onTap;

  const TravelPlaceCard({
    super.key,
    required this.rank,
    required this.place,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<TravelPlaceCard> createState() => _TravelPlaceCardState();
}

class _TravelPlaceCardState extends State<TravelPlaceCard> {
  bool _hovered = false;

  String get _badge {
    if (widget.place.type == TravelPlaceType.hotel) {
      return widget.rank == 1 ? 'Best Value' : '#${widget.rank} Ranked';
    }
    return widget.place.openNow == false ? 'Tutup' : 'Buka';
  }

  Color get _badgeColor {
    if (widget.place.type == TravelPlaceType.hotel) {
      return widget.rank == 1 ? const Color(0xFFFFB300) : Colors.blueGrey;
    }
    return widget.place.openNow == false ? Colors.redAccent : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? context.colors.primary.withValues(alpha: 0.1)
                : context.colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? context.colors.primary
                  : _hovered
                      ? context.colors.primary.withValues(alpha: 0.4)
                      : context.colors.border,
              width: widget.isSelected ? 1.5 : 1,
            ),
            boxShadow: widget.isSelected || _hovered
                ? [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Rank badge + photo stacked
                Stack(
                  children: [
                    _PlacePhoto(place: widget.place, size: 72),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          '#${widget.rank}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.place.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 13, color: Color(0xFFFFB300)),
                          const SizedBox(width: 3),
                          Text(
                            '${widget.place.rating}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: context.colors.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${widget.place.reviewCount} ulasan',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.near_me_rounded,
                              size: 12, color: context.colors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${widget.place.distanceMeters} m',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: context.colors.textMuted,
                            ),
                          ),
                          if (widget.place.priceLabel.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: context.colors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.place.priceLabel,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Right column: badge + maps
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: _badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _badge,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MapsButton(place: widget.place),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Maps Button ────────────────────────────────────────────────────────────────
class _MapsButton extends StatelessWidget {
  final TravelPlaceEntity place;
  const _MapsButton({required this.place});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openMaps(place),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: context.colors.primaryGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.map_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── Place Photo ────────────────────────────────────────────────────────────────
class _PlacePhoto extends StatelessWidget {
  final TravelPlaceEntity place;
  final double size;

  const _PlacePhoto({required this.place, required this.size});

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = place.type == TravelPlaceType.hotel
        ? Icons.hotel_rounded
        : Icons.restaurant_rounded;

    if (place.photoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.primary.withValues(alpha: 0.2),
              context.colors.primary.withValues(alpha: 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(fallbackIcon, color: context.colors.primary, size: 28),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        place.photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.colors.primary.withValues(alpha: 0.2),
                context.colors.primary.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(fallbackIcon, color: context.colors.primary, size: 28),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
Future<void> _openMaps(TravelPlaceEntity place) async {
  final uri = Uri.parse(place.mapsUrl);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

void showTravelPlaceDetail(BuildContext context, TravelPlaceEntity place) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _PlaceDetailSheet(place: place),
  );
}

// ── Detail Bottom Sheet ────────────────────────────────────────────────────────
class _PlaceDetailSheet extends ConsumerWidget {
  final TravelPlaceEntity place;

  const _PlaceDetailSheet({required this.place});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(placeDetailsProvider(place.id));

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero photo
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: place.photoUrl.isEmpty
                        ? _DetailPhotoFallback(place: place)
                        : Image.network(
                            place.photoUrl,
                            height: 230,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _DetailPhotoFallback(
                                  place: place, showLoader: true);
                            },
                            errorBuilder: (_, _, _) =>
                                _DetailPhotoFallback(place: place),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // Name + type badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: context.colors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          place.type == TravelPlaceType.hotel
                              ? 'Hotel'
                              : 'Restoran',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats chips — price from live API
                  detailsAsync.when(
                    loading: () => _StaticChips(place: place, priceLevel: null),
                    error: (_, __) =>
                        _StaticChips(place: place, priceLevel: null),
                    data: (details) => _StaticChips(
                      place: place,
                      priceLevel: details.priceLevel,
                      editorialSummary: details.editorialSummary,
                      address: details.address,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Maps Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _openMaps(place),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text(
                        'Buka di Google Maps',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  // Reviews section
                  const SizedBox(height: 28),
                  detailsAsync.when(
                    loading: () => const _ReviewsLoadingPlaceholder(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (details) => details.reviews.isEmpty
                        ? const SizedBox.shrink()
                        : _ReviewsSection(reviews: details.reviews),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chips Widget ───────────────────────────────────────────────────────────────
class _StaticChips extends StatelessWidget {
  final TravelPlaceEntity place;
  final int? priceLevel;
  final String? editorialSummary;
  final String? address;

  const _StaticChips({
    required this.place,
    required this.priceLevel,
    this.editorialSummary,
    this.address,
  });

  String _priceLabelFrom(int? level) {
    switch (level) {
      case 0:
        return 'Gratis';
      case 1:
        return 'Rp - Murah';
      case 2:
        return 'Rp-Rp - Sedang';
      case 3:
        return 'Rp-Rp-Rp - Mahal';
      case 4:
        return 'Rp-Rp-Rp-Rp - Sangat Mahal';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePrice = priceLevel ?? place.priceLevel;
    final priceStr = _priceLabelFrom(effectivePrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (editorialSummary != null && editorialSummary!.isNotEmpty) ...[
          Text(
            editorialSummary!,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: context.colors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (address != null && address!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded,
                  size: 14, color: context.colors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: context.colors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DetailChip(
              icon: Icons.star_rounded,
              label: '${place.rating} rating',
              iconColor: const Color(0xFFFFB300),
            ),
            _DetailChip(
              icon: Icons.rate_review_rounded,
              label: '${place.reviewCount} ulasan',
            ),
            _DetailChip(
              icon: Icons.near_me_rounded,
              label: '${place.distanceMeters} m',
            ),
            if (place.type == TravelPlaceType.restaurant)
              _DetailChip(
                icon: Icons.schedule_rounded,
                label: place.openNow == false ? 'Tutup' : 'Buka',
                iconColor:
                    place.openNow == false ? Colors.redAccent : Colors.green,
              ),
            if (priceStr.isNotEmpty)
              _DetailChip(
                icon: Icons.payments_rounded,
                label: priceStr,
                iconColor: const Color(0xFF2E7D32),
              ),
          ],
        ),
      ],
    );
  }
}

// ── Reviews Section (with star filter) ───────────────────────────────────────
class _ReviewsSection extends StatefulWidget {
  final List<PlaceReview> reviews;
  const _ReviewsSection({required this.reviews});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  // null = semua, 5/4/3 = filter minimum rating
  int? _filterStars;

  List<PlaceReview> get _filtered {
    if (_filterStars == null) return widget.reviews;
    if (_filterStars! <= 3) {
      return widget.reviews.where((r) => r.rating <= 3).toList();
    }
    return widget.reviews.where((r) => r.rating.round() == _filterStars).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.format_quote_rounded,
                color: context.colors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Ulasan Pengunjung',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${widget.reviews.length}',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Star filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StarFilterChip(
                label: 'Semua',
                isSelected: _filterStars == null,
                onTap: () => setState(() => _filterStars = null),
              ),
              const SizedBox(width: 8),
              _StarFilterChip(
                label: '5 Bintang',
                stars: 5,
                isSelected: _filterStars == 5,
                onTap: () => setState(
                    () => _filterStars = _filterStars == 5 ? null : 5),
              ),
              const SizedBox(width: 8),
              _StarFilterChip(
                label: '4 Bintang',
                stars: 4,
                isSelected: _filterStars == 4,
                onTap: () => setState(
                    () => _filterStars = _filterStars == 4 ? null : 4),
              ),
              const SizedBox(width: 8),
              _StarFilterChip(
                label: '3 ke bawah',
                stars: 3,
                isSelected: _filterStars == 3,
                onTap: () => setState(
                    () => _filterStars = _filterStars == 3 ? null : 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Review cards
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Tidak ada ulasan dengan filter ini.',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: context.colors.textMuted,
                ),
              ),
            ),
          )
        else
          ...filtered.asMap().entries.map(
                (e) => _ReviewCard(review: e.value)
                    .animate(delay: Duration(milliseconds: 50 * e.key))
                    .fadeIn()
                    .slideY(begin: 0.06),
              ),
      ],
    );
  }
}

class _StarFilterChip extends StatelessWidget {
  final String label;
  final int? stars;
  final bool isSelected;
  final VoidCallback onTap;

  const _StarFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB300) : context.colors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFB300)
                : context.colors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stars != null) ...[
              Icon(
                Icons.star_rounded,
                size: 13,
                color: isSelected ? Colors.white : const Color(0xFFFFB300),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PlaceReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar: use Image.network with errorBuilder to handle 429
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.primary.withValues(alpha: 0.15),
                ),
                clipBehavior: Clip.antiAlias,
                child: review.authorPhoto.isNotEmpty
                    ? Image.network(
                        review.authorPhoto,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        // Handle 429 or any network error gracefully
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            review.authorName.isNotEmpty
                                ? review.authorName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          review.authorName.isNotEmpty
                              ? review.authorName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.outfit(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Text(
                      review.relativeTime,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: context.colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: const Color(0xFFFFB300),
                  ),
                ),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.text,
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: context.colors.textSecondary,
                height: 1.5,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsLoadingPlaceholder extends StatelessWidget {
  const _ReviewsLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Memuat ulasan...',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: context.colors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        const LinearProgressIndicator(),
      ],
    );
  }
}

// ── Shared Photo Fallback ──────────────────────────────────────────────────────
class _DetailPhotoFallback extends StatelessWidget {
  final TravelPlaceEntity place;
  final bool showLoader;

  const _DetailPhotoFallback({
    required this.place,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = place.type == TravelPlaceType.hotel
        ? Icons.hotel_rounded
        : Icons.restaurant_rounded;

    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withValues(alpha: 0.2),
            context.colors.primary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: showLoader
            ? CircularProgressIndicator(color: context.colors.primary)
            : Icon(icon, color: context.colors.primary, size: 52),
      ),
    );
  }
}

// ── Detail Chip ────────────────────────────────────────────────────────────────
class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _DetailChip({
    required this.icon,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? context.colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
