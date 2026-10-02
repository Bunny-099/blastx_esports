import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/transitions/fire_page_route.dart';
import '../data/models/tournament_model.dart';
import '../providers/live_provider.dart';
import 'tournament_detail_screen.dart';
import 'widgets/tournament_card.dart';

/// ============================================================
/// PREMIUM LIVE SCREEN — Free Fire Exclusive Edition
/// ============================================================
/// - Ambient breathing gradient background
/// - Real-time Free Fire Live API data stream
/// - Collapsible search bar with 300ms debounce
/// - Horizontally scrollable status filter chips with counts
/// - Smart default status filter selection
/// - Staggered fade+slide entrance for each tournament card
/// - Shimmer skeleton while fetching from backend API
/// - AnimatedSwitcher list transitions & pull-to-refresh support
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

  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  Timer? _searchDebounce;
  bool _isSearchOpen = false;

  bool _hasAutoSelectedFilter = false;
  bool _userManuallySelectedFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).state = val;
    });
    setState(() {}); // Update local clear button state
  }

  void _toggleSearch() {
    setState(() {
      _isSearchOpen = !_isSearchOpen;
      if (!_isSearchOpen) {
        _searchDebounce?.cancel();
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {});
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
    // Watch API Async Value, filtered tournaments, status filter, search query, and counts
    final apiAsync = ref.watch(apiTournamentsProvider);
    final tournaments = ref.watch(visibleTournamentsProvider);
    final currentFilter = ref.watch(statusFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final counts = ref.watch(tournamentCountsProvider);
    final liveCount = counts[TournamentStatusFilter.live] ?? 0;

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

    // Smart default filter: Default to Live, but if after the first successful load there are 0 live tournaments
    // and the user has not manually picked a chip, auto-select Upcoming (or All if upcoming is also 0). Done once per screen open.
    if (!isLoading && apiAsync.hasValue && !_hasAutoSelectedFilter && !_userManuallySelectedFilter) {
      _hasAutoSelectedFilter = true;
      final allTournaments = apiAsync.value ?? [];
      final liveTournamentsCount = allTournaments.where((t) => t.status == TournamentStatus.live).length;
      if (liveTournamentsCount == 0) {
        final upcomingTournamentsCount = allTournaments.where((t) => t.status == TournamentStatus.upcoming).length;
        final targetFilter = upcomingTournamentsCount > 0
            ? TournamentStatusFilter.upcoming
            : TournamentStatusFilter.all;
        if (currentFilter != targetFilter) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_userManuallySelectedFilter) {
              ref.read(statusFilterProvider.notifier).state = targetFilter;
            }
          });
        }
      }
    }

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
                  // 1. Header with Title, Search Toggle, and Live Badge
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                                  color: _isSearchOpen ? AppColors.accentOrange : AppColors.textPrimary,
                                  size: 22,
                                ),
                                onPressed: _toggleSearch,
                                tooltip: _isSearchOpen ? 'Close search' : 'Search tournaments',
                              ),
                              const SizedBox(width: 4),
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
                                  '$liveCount LIVE',
                                  style: AppTextStyles.caption
                                      .copyWith(color: Colors.white, letterSpacing: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Collapsible Search Bar
                  SliverToBoxAdapter(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: _isSearchOpen
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        onChanged: _onSearchChanged,
                                        style: AppTextStyles.bodyLg,
                                        cursorColor: AppColors.primary,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Search title, organizer, map...',
                                          hintStyle: AppTextStyles.bodyMd
                                              .copyWith(color: AppColors.textMuted),
                                          isCollapsed: true,
                                        ),
                                      ),
                                    ),
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded,
                                            size: 18, color: AppColors.textMuted),
                                        onPressed: _clearSearch,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  // 3. Status Filter Chips (Live | Upcoming | Completed | All)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            TournamentStatusFilter.live,
                            TournamentStatusFilter.upcoming,
                            TournamentStatusFilter.completed,
                            TournamentStatusFilter.all,
                          ].map((filter) {
                            final isSelected = currentFilter == filter;
                            final count = counts[filter] ?? 0;
                            final label = switch (filter) {
                              TournamentStatusFilter.live => 'Live $count',
                              TournamentStatusFilter.upcoming => 'Upcoming $count',
                              TournamentStatusFilter.completed => 'Completed $count',
                              TournamentStatusFilter.all => 'All $count',
                            };

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  _userManuallySelectedFilter = true;
                                  ref.read(statusFilterProvider.notifier).state = filter;
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.orangeTint
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.accentOrange.withValues(alpha: 0.6)
                                          : AppColors.border,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    label,
                                    style: AppTextStyles.bodySm.copyWith(
                                      color: isSelected
                                          ? AppColors.accentOrange
                                          : AppColors.textSecondary,
                                      fontWeight:
                                          isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // 4. Content Area with AnimatedSwitcher
                  SliverFillRemaining(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: isLoading
                          ? ListView.builder(
                              key: const ValueKey('loading'),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: 3,
                              itemBuilder: (context, index) => const Padding(
                                padding: EdgeInsets.only(bottom: 18),
                                child: _CardShimmer(),
                              ),
                            )
                          : hasErrorNoData
                              ? _ErrorState(
                                  key: const ValueKey('error'),
                                  onRetry: _onRefresh,
                                )
                              : isEmpty
                                  ? _EmptyState(
                                      key: ValueKey(
                                          'empty_${currentFilter.name}_$searchQuery'),
                                      onRefresh: _onRefresh,
                                      filter: currentFilter,
                                      searchQuery: searchQuery,
                                    )
                                  : ListView.builder(
                                      key: ValueKey(
                                          'list_${currentFilter.name}_$searchQuery'),
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                      itemCount: tournaments.length,
                                      itemBuilder: (context, index) {
                                        final tournament = tournaments[index];
                                        return Padding(
                                          key: ValueKey(tournament.id),
                                          padding: const EdgeInsets.only(bottom: 18),
                                          child: TournamentCard(
                                            tournament: tournament,
                                            viewOnly: true,
                                            onTap: () {
                                              Navigator.of(context).push(
                                                FirePageRoute(
                                                  page: TournamentDetailScreen(
                                                    tournamentId: tournament.id,
                                                    viewOnly: true,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                            .animate(delay: (60 * index).ms)
                                            .fadeIn(
                                                duration: 420.ms,
                                                curve: Curves.easeOut)
                                            .slideY(
                                              begin: 0.12,
                                              end: 0,
                                              duration: 420.ms,
                                              curve: Curves.easeOutCubic,
                                            );
                                      },
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
  const _EmptyState({
    super.key,
    required this.onRefresh,
    required this.filter,
    required this.searchQuery,
  });

  final Future<void> Function() onRefresh;
  final TournamentStatusFilter filter;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final String titleText;
    if (searchQuery.trim().isNotEmpty) {
      titleText = 'No tournaments found for "${searchQuery.trim()}"';
    } else {
      titleText = switch (filter) {
        TournamentStatusFilter.live => 'No live tournaments',
        TournamentStatusFilter.upcoming => 'No upcoming tournaments',
        TournamentStatusFilter.completed => 'No completed tournaments',
        TournamentStatusFilter.all => 'No tournaments found',
      };
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
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
              titleText,
              style: AppTextStyles.headingMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Check back soon or pull down to refresh',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
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
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.onRetry});

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
