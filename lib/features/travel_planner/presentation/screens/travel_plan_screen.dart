import 'package:fin_track/core/constants.dart';
import 'package:fin_track/core/theme.dart';
import 'package:fin_track/features/travel_planner/presentation/providers/travel_planner_providers.dart';
import 'package:fin_track/features/travel_planner/presentation/widgets/travel_place_section.dart';
import 'package:fin_track/features/travel_planner/presentation/widgets/travel_search_card.dart';
import 'package:fin_track/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TravelPlanScreen extends ConsumerStatefulWidget {
  const TravelPlanScreen({super.key});

  @override
  ConsumerState<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends ConsumerState<TravelPlanScreen> {
  final TextEditingController _destinationController = TextEditingController();
  final List<String> _suggestions = const ['Bandung', 'Bali', 'Malioboro', 'Yogyakarta', 'Raja Ampat'];

  @override
  void initState() {
    super.initState();
    _destinationController.text = 'Bandung';
    Future.microtask(
      () => ref.read(travelPlannerProvider.notifier).search('Bandung'),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelPlannerProvider);
    final notifier = ref.read(travelPlannerProvider.notifier);
    final isMobile =
        MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;
    final isLoading = state.action.isLoading;

    ref.listen(travelPlannerProvider.select((value) => value.action), (
      previous,
      next,
    ) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: context.colors.error,
            ),
          );
        },
      );
    });

    return MainLayout(
      title: 'Travel Plan',
      child: CustomScrollView(
        slivers: [
          // ── Hero Banner ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _TravelHeroBanner(
              destinationName: state.destination?.name,
            ).animate().fadeIn(duration: 400.ms),
          ),

          // ── Search Card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 28,
                0,
                isMobile ? 16 : 28,
                0,
              ),
              child: TravelSearchCard(
                controller: _destinationController,
                selectedDestination: state.destination?.name,
                suggestions: _suggestions,
                onSearch: notifier.search,
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
            ),
          ),

          // ── Hotels Section ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 28,
                24,
                isMobile ? 16 : 28,
                0,
              ),
              child: _SectionHeading(
                icon: Icons.hotel_rounded,
                title: 'Rekomendasi Hotel',
                subtitle: state.hotels.isEmpty
                    ? 'Cari kota untuk melihat hotel terbaik'
                    : '${state.hotels.length} hotel ditemukan',
              ).animate().fadeIn(delay: 250.ms),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 28,
                12,
                isMobile ? 16 : 28,
                32,
              ),
              child: isLoading && state.hotels.isEmpty
                  ? const _ShimmerLoadingCards()
                  : TravelPlaceSection(
                      title: 'Hotel',
                      icon: Icons.hotel_rounded,
                      places: state.hotels,
                      emptyText: 'Cari destinasi untuk melihat hotel.',
                      onPlaceTap: (place) {
                        notifier.selectHotel(place);
                        context.push('/travel-plan/hotel');
                      },
                    ).animate().fadeIn(delay: 300.ms),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Banner ────────────────────────────────────────────────────────────────
class _TravelHeroBanner extends StatelessWidget {
  final String? destinationName;
  const _TravelHeroBanner({this.destinationName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      margin: const EdgeInsets.only(bottom: 0),
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.withValues(alpha: 0.85),
                  const Color(0xFF1A6B4A),
                  const Color(0xFF0D3D2A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 80,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          // Icon background blob
          Positioned(
            right: 24,
            bottom: 32,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          // Text content
          Positioned(
            left: 24,
            bottom: 28,
            right: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '✈️  Travel Planner',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  destinationName != null
                      ? 'Jelajahi\n$destinationName'
                      : 'Rencanakan\nPerjalananmu',
                  maxLines: 2,
                  style: GoogleFonts.outfit(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Hotel & restoran terbaik untukmu',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),

          // Bottom fade overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 50,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    context.colors.background.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Heading ────────────────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: context.colors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.colors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: context.colors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Shimmer Placeholder ───────────────────────────────────────────────────────
class _ShimmerLoadingCards extends StatefulWidget {
  const _ShimmerLoadingCards();

  @override
  State<_ShimmerLoadingCards> createState() => _ShimmerLoadingCardsState();
}

class _ShimmerLoadingCardsState extends State<_ShimmerLoadingCards>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => Opacity(
            opacity: 0.4 + (_animation.value * 0.4),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
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
