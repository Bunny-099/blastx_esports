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

/// ============================================================
/// PREMIUM LIVE SCREEN — Free Fire Exclusive Edition
/// ============================================================
/// - Ambient breathing gradient background (orange/red glow blobs)
/// - Real-time Free Fire Live API data stream
/// - Staggered fade+slide entrance for each tournament card
/// - Shimmer skeleton while fetching from backend API
/// - Pull-to-refresh support
/// ============================================================

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    ref.invalidate(apiTournamentsProvider);
    try {
      await ref.read(apiTournamentsProvider.future);
    } catch (_) {
      // Error handled via AsyncValue listener in UI
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch API Async Value and filtered tournaments
    final apiAsync = ref.watch(apiTournamentsProvider);
    final tournaments = ref.watch(filteredOfficialTournamentsProvider);

    // Listen for refresh failures when previous cached data exists
    ref.listen<AsyncValue<dynamic>>(
      apiTournamentsProvider,
      (previous, next) {
        if (next.hasError && !next.isLoading) {
          if (previous?.hasValue == true || (next.hasValue && (next.valueOrNull != null))) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refresh failed'),
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      },
    );

    final isLoading = apiAsync.isLoading && !apiAsync.hasValue;
    final hasErrorNoData = apiAsync.hasError && (!apiAsync.hasValue || tournaments.isEmpty);
    final isEmpty = !isLoading && !hasErrorNoData && tournaments.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _AmbientBackground(controller: _ambientController),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                  else if (hasErrorNoData)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(onRetry: _onRefresh),
                    )
                  else if (isEmpty)
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
                              key: ValueKey(tournament.id),
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
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        child: Container(color: AppColors.background),
        builder: (context, staticBackground) {
          final t = controller.value;
          return Stack(
            children: [
              staticBackground!,
              Positioned(
                top: -80 + (t * 30),
                right: -60,
                child: Opacity(
                  opacity: 0.5,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.ambientGlowOrange,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.primary,
            size: 54,
          ),
          const SizedBox(height: 12),
          Text(
            "Couldn't load tournaments",
            style: AppTextStyles.headingMd,
          ),
          const SizedBox(height: 6),
          Text(
            'Check your connection and try again',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
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
