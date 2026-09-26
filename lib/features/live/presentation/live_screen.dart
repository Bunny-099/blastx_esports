import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/transitions/fire_page_route.dart';
import '../../profile/providers/profile_provider.dart';
import '../providers/live_provider.dart';
import 'tournament_detail_screen.dart';
import 'widgets/tournament_card.dart';

/// ============================================================
/// PREMIUM LIVE SCREEN — Free Fire Exclusive Edition
/// ============================================================
/// - Ambient breathing gradient background (orange/red glow blobs)
/// - Glassmorphism collapsing header + dynamic user profile name
/// - Real-time Free Fire Live API data stream
/// - Staggered fade+slide entrance for each tournament card
/// - Shimmer skeleton while fetching from backend API
/// - Pull-to-refresh support
/// ============================================================

const double _kExpandedHeaderHeight = 150;

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  double _collapseFraction = 0;

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  static const List<String> _motivationalQuotes = [
    "Booyah! Show them who's the real survivor. 🔥",
    "Stay in the zone, stay in the game. 🎮",
    "One tap, one kill. The peak of skill.",
    "Bermuda is yours to conquer today.",
    "Squad up and dominate the battlefield.",
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
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(apiTournamentsProvider);
    await ref.read(apiTournamentsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    // Watch User Profile for real dynamic name
    final profileState = ref.watch(profileProvider);
    final profileName = profileState.user?.name;
    final displayName = (profileName != null && profileName.trim().isNotEmpty)
        ? profileName.trim()
        : (widget.username != 'Player' ? widget.username : 'Player');

    // Watch API Async Value and filtered tournaments
    final apiAsync = ref.watch(apiTournamentsProvider);
    final tournaments = ref.watch(filteredOfficialTournamentsProvider);

    final isLoading = apiAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _AmbientBackground(controller: _ambientController),
          SafeArea(
            top: false,
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
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
                      username: displayName,
                      greetingText: _greetingText,
                      quote: _quote,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 6),
                              Text('Free Fire Live', style: AppTextStyles.headingLg),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: AppColors.fireGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
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
                  if (isLoading)
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
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(onRefresh: _onRefresh),
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
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Ambient breathing background
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
  });

  final double collapseFraction;
  final String username;
  final String greetingText;
  final String quote;

  @override
  double get minExtent => 60; // Just enough for status bar + small padding

  @override
  double get maxExtent => _kExpandedHeaderHeight + 20;

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
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: AppColors.surface),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.background.withValues(alpha: 0.15),
                              AppColors.background.withValues(alpha: 0.9),
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
                              AppColors.primary.withValues(alpha: 0.18),
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
        height: 178,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.primary,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            'No Live Free Fire Tournaments',
            style: AppTextStyles.headingMd,
          ),
          const SizedBox(height: 6),
          Text(
            'Check back soon or pull down to refresh',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
