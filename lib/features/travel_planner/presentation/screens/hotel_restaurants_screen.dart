import 'dart:ui';

import 'package:fin_track/core/theme.dart';
import 'package:fin_track/features/travel_planner/domain/entities/travel_place_entity.dart';
import 'package:fin_track/features/travel_planner/presentation/providers/travel_planner_providers.dart';
import 'package:fin_track/features/travel_planner/presentation/widgets/travel_place_section.dart';
import 'package:fin_track/features/travel_planner/presentation/widgets/trip_plan_summary_card.dart';
import 'package:fin_track/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

enum RestaurantFilter { all, cafe }

class HotelRestaurantsScreen extends ConsumerStatefulWidget {
  const HotelRestaurantsScreen({super.key});

  @override
  ConsumerState<HotelRestaurantsScreen> createState() =>
      _HotelRestaurantsScreenState();
}

class _HotelRestaurantsScreenState
    extends ConsumerState<HotelRestaurantsScreen> {
  RestaurantFilter _filter = RestaurantFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelPlannerProvider);
    final notifier = ref.read(travelPlannerProvider.notifier);
    final hotel = state.selectedHotel;

    if (hotel == null) {
      return MainLayout(
        title: 'Detail Hotel',
        child: Center(
          child: FilledButton.icon(
            onPressed: () => context.go('/travel-plan'),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Pilih hotel dulu'),
          ),
        ),
      );
    }

    final restaurants = _filteredRestaurants(state.restaurants);
    final isLoadingRestaurants =
        state.action.isLoading && state.restaurants.isEmpty;

    return MainLayout(
      title: hotel.name,
      child: CustomScrollView(
        slivers: [
          // ── Hero Header ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HotelHeroHeader(
              hotel: hotel,
              onBack: () => context.go('/travel-plan'),
            ).animate().fadeIn(duration: 350.ms),
          ),

          // ── Section: Restaurant Title ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: _RestaurantSectionHeader(
                filter: _filter,
                restaurantCount: restaurants.length,
                onFilterChanged: (v) => setState(() => _filter = v),
              ).animate().fadeIn(delay: 150.ms),
            ),
          ),

          // ── Restaurant Cards ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: isLoadingRestaurants
                  ? const _LoadingRestaurants()
                  : TravelPlaceSection(
                      title: _filter == RestaurantFilter.cafe
                          ? 'Cafe Terdekat'
                          : 'Restoran Terdekat',
                      icon: _filter == RestaurantFilter.cafe
                          ? Icons.local_cafe_rounded
                          : Icons.restaurant_rounded,
                      places: restaurants,
                      emptyText: _filter == RestaurantFilter.cafe
                          ? 'Tidak ada cafe ditemukan dari hasil Places.'
                          : 'Restoran terdekat belum ditemukan.',
                      onPlaceTap: (place) =>
                          showTravelPlaceDetail(context, place),
                    ).animate().fadeIn(delay: 200.ms),
            ),
          ),

          // ── Trip Summary ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: TripPlanSummaryCard(
                summary: state.summary,
                isSaving:
                    state.action.isLoading && state.restaurants.isNotEmpty,
                onSave: notifier.save,
              ).animate().fadeIn(delay: 300.ms),
            ),
          ),
        ],
      ),
    );
  }

  List<TravelPlaceEntity> _filteredRestaurants(
    List<TravelPlaceEntity> restaurants,
  ) {
    final sorted = [...restaurants]
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    if (_filter == RestaurantFilter.all) return sorted;

    return sorted.where((place) {
      final name = place.name.toLowerCase();
      return name.contains('cafe') ||
          name.contains('coffee') ||
          name.contains('kopi') ||
          name.contains('kafe');
    }).toList();
  }
}

// ── Hotel Hero Header ──────────────────────────────────────────────────────────
class _HotelHeroHeader extends ConsumerWidget {
  final TravelPlaceEntity hotel;
  final VoidCallback onBack;

  const _HotelHeroHeader({required this.hotel, required this.onBack});

  String _priceLabelFrom(int level) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(placeDetailsProvider(hotel.id));
    final livePrice = detailsAsync.whenOrNull(data: (d) => d.priceLevel);
    final effectivePrice = livePrice ?? hotel.priceLevel;
    return Stack(
      children: [
        // Photo
        SizedBox(
          height: 300,
          width: double.infinity,
          child: hotel.photoUrl.isEmpty
              ? _HeroPhotoFallback()
              : Image.network(
                  hotel.photoUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _HeroPhotoFallback(),
                ),
        ),

        // Gradient overlay bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
        ),

        // Gradient overlay top (for back button contrast)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 90,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 16,
          left: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: onBack,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Hotel info bottom-left
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.name,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10)
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _GlassChip(
                      icon: Icons.star_rounded,
                      label: '${hotel.rating}',
                      iconColor: const Color(0xFFFFB300),
                    ),
                    _GlassChip(
                      icon: Icons.rate_review_rounded,
                      label: '${hotel.reviewCount} ulasan',
                    ),
                    _GlassChip(
                      icon: Icons.near_me_rounded,
                      label: '${hotel.distanceMeters} m',
                    ),
                    if (effectivePrice != null)
                      _GlassChip(
                        icon: Icons.payments_rounded,
                        label: _priceLabelFrom(effectivePrice),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Maps button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(hotel.mapsUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.map_rounded, size: 16),
                          label: const Text(
                            'Google Maps',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1A6B4A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Lihat Harga & Ulasan button
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              showTravelPlaceDetail(context, hotel),
                          icon: const Icon(
                              Icons.rate_review_rounded,
                              size: 16),
                          label: const Text(
                            'Harga & Ulasan',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.4)),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _GlassChip({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: iconColor ?? Colors.white),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPhotoFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.primary.withValues(alpha: 0.8),
            const Color(0xFF0D3D2A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(
        Icons.hotel_rounded,
        color: Colors.white,
        size: 64,
      ),
    );
  }
}

// ── Restaurant Section Header ──────────────────────────────────────────────────
class _RestaurantSectionHeader extends StatelessWidget {
  final RestaurantFilter filter;
  final int restaurantCount;
  final ValueChanged<RestaurantFilter> onFilterChanged;

  const _RestaurantSectionHeader({
    required this.filter,
    required this.restaurantCount,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B6B),
                    const Color(0xFFFF8E53),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                filter == RestaurantFilter.cafe
                    ? Icons.local_cafe_rounded
                    : Icons.restaurant_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter == RestaurantFilter.cafe
                      ? 'Cafe Terdekat'
                      : 'Restoran Terdekat',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  restaurantCount > 0
                      ? '$restaurantCount tempat ditemukan'
                      : 'Memuat data...',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: context.colors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Filter toggles
        Row(
          children: [
            _FilterChip(
              label: 'Semua Restoran',
              icon: Icons.restaurant_rounded,
              isSelected: filter == RestaurantFilter.all,
              onTap: () => onFilterChanged(RestaurantFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Cafe / Kopi',
              icon: Icons.local_cafe_rounded,
              isSelected: filter == RestaurantFilter.cafe,
              onTap: () => onFilterChanged(RestaurantFilter.cafe),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : context.colors.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : context.colors.textSecondary,
            ),
            const SizedBox(width: 6),
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

// ── Loading placeholder ────────────────────────────────────────────────────────
class _LoadingRestaurants extends StatefulWidget {
  const _LoadingRestaurants();

  @override
  State<_LoadingRestaurants> createState() => _LoadingRestaurantsState();
}

class _LoadingRestaurantsState extends State<_LoadingRestaurants>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Opacity(
            opacity: 0.35 + _anim.value * 0.35,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 82,
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
