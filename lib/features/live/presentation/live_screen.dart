import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/transitions/fire_page_route.dart';
import '../providers/live_provider.dart';
import 'tournament_detail_screen.dart';
import 'widgets/tournament_card.dart';
import 'widgets/capsule_search_bar.dart';

/// ============================================================
/// PREMIUM LIVE SCREEN — "Sexy" Free Fire Theme
/// ============================================================
/// - Ambient breathing gradient background (orange/red glow blobs)
/// - Glassmorphism collapsing header + frosted search bar
/// - Staggered fade+slide entrance for each tournament card
/// - Shimmer skeleton while the list "loads"
/// - Cinematic push transition into the detail screen (FirePageRoute)
/// ============================================================

const double _kExpandedHeaderHeight = 150;
const double _kSearchBarHeight = 52;

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  double _collapseFraction = 0;
  bool _isLoading = true;

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  static const List<String> _motivationalQuotes = [
    "Champions aren't made in comfort zones. Go clutch it. 🔥",
    "Every match is a new chance to prove yourself. 🎮",
    "Grind now, flex later.",
    "Your next win starts with your next click.",
    "Play like the finals are today.",
  ];

  late final String _quote =
  _motivationalQuotes[DateTime.now().second % _motivationalQuotes.length];

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Brief simulated load so the shimmer skeleton gets a moment to show.
    // Safe to remove once tournaments come from a real async source
    // (the provider itself should expose its own loading state then).
    Future.delayed(const Duration(milliseconds: 700), ( ) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset.clamp(0, _kExpandedHeaderHeight);
    final fraction = offset / _kExpandedHeaderHeight;
    if ((fraction - _collapseFraction).abs() > 0.01) {
      setState(() => _collapseFraction = fraction);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(filteredTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _AmbientBackground(controller: _ambientController),
          SafeArea(
            top: false,
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CollapsingHeaderDelegate(
                    collapseFraction: _collapseFraction,
                    username: widget.username,
                    greetingText: _greetingText,
                    quote: _quote,
                    searchController: _searchController,
                    onSearchChanged: (value) {
                      ref.read(tournamentSearchQueryProvider.notifier).state =
                          value;
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Live Tournaments', style: AppTextStyles.headingLg),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppColors.fireGradient,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            '${tournaments.where((t) => t.isLive).length} LIVE',
                            style: AppTextStyles.caption
                                .copyWith(color: Colors.white, letterSpacing: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => const Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: _CardShimmer(),
                        ),
                        childCount: 3,
                      ),
                    ),
                  )
                else if (tournaments.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final tournament = tournaments[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: TournamentCard(
                              tournament: tournament,
                              onTap: () {
                                Navigator.of(context).push(
                                  FirePageRoute(
                                    page: TournamentDetailScreen(
                                      tournamentId: tournament.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                              .animate(delay: (60 * index).ms)
                              .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                              .slideY(
                            begin: 0.12,
                            end: 0,
                            duration: 420.ms,
                            curve: Curves.easeOutCubic,
                          );
                        },
                        childCount: tournaments.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Ambient breathing background — two soft glow blobs that
/// slowly drift, giving the dark background depth instead of
/// being flat black.
/// ------------------------------------------------------------

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            Container(color: AppColors.background),
            Positioned(
              top: -80 + (t * 30),
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ambientGlowOrange,
                ),
              ),
            ),
            Positioned(
              bottom: 40 - (t * 20),
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ambientGlowRed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CollapsingHeaderDelegate({
    required this.collapseFraction,
    required this.username,
    required this.greetingText,
    required this.quote,
    required this.searchController,
    required this.onSearchChanged,
  });

  final double collapseFraction;
  final String username;
  final String greetingText;
  final String quote;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  double get minExtent => _kSearchBarHeight + 24;

  @override
  double get maxExtent => _kExpandedHeaderHeight + _kSearchBarHeight + 32;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final opacity = (1 - (collapseFraction * 1.5)).clamp(0.0, 1.0);
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // 1. Background image (collapsing, cinematic dark overlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -collapseFraction * 40),
                child: Container(
                  height: _kExpandedHeaderHeight + topPadding - 20,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/top_banner.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.surface),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.background.withOpacity(0.15),
                              AppColors.background.withOpacity(0.9),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.18),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Greeting block
          Positioned(
            top: topPadding + 16,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -collapseFraction * 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey, $username 👋', style: AppTextStyles.headingXl),
                      const SizedBox(height: 4),
                      Text(greetingText, style: AppTextStyles.bodyMd),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(
                          quote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySm.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Search Bar (Pinned at bottom)
          Positioned(
            left: 20,
            right: 20,
            bottom: 12,
            child: CapsuleSearchBar(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CollapsingHeaderDelegate oldDelegate) {
    return oldDelegate.collapseFraction != collapseFraction ||
        oldDelegate.username != username ||
        oldDelegate.greetingText != greetingText ||
        oldDelegate.quote != quote;
  }
}

class _CardShimmer extends StatelessWidget {
  const _CardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceMuted,
      child: Container(
        height: 168,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_esports_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No tournaments found', style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}