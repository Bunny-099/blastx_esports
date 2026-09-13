import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../live/presentation/live_screen.dart'; // To reuse CapsuleSearchBar and Header components if possible
import '../../live/providers/live_provider.dart';
import 'widgets/upcoming_tournament_card.dart';

class UpcomingTournamentsScreen extends ConsumerStatefulWidget {
  const UpcomingTournamentsScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<UpcomingTournamentsScreen> createState() => _UpcomingTournamentsScreenState();
}

class _UpcomingTournamentsScreenState extends ConsumerState<UpcomingTournamentsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  double _collapseFraction = 0;

  static const List<String> _upcomingQuotes = [
    "Preparation is the key to success. 🏆",
    "Upcoming battles, legendary rewards.",
    "Mark your calendars, the arena awaits.",
    "Greatness is coming. Are you ready?",
    "Next level gaming starts here.",
  ];

  late final String _quote =
  _upcomingQuotes[DateTime.now().second % _upcomingQuotes.length];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;
    const double expandedHeight = 100;
    final offset = _scrollController.offset.clamp(0.0, expandedHeight);
    final fraction = offset / expandedHeight;
    if ((fraction - _collapseFraction).abs() > 0.01) {
      setState(() => _collapseFraction = fraction);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(filteredUpcomingTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _UpcomingHeaderDelegate(
                collapseFraction: _collapseFraction,
                username: widget.username,
                quote: _quote,
                searchController: _searchController,
                onSearchChanged: (value) {
                  ref.read(upcomingSearchQueryProvider.notifier).state = value;
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Upcoming Battles',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '${tournaments.length} EVENTS',
                        style: const TextStyle(
                          color: AppColors.secondaryDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (tournaments.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyUpcomingState(),
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
                        child: UpcomingTournamentCard(
                          tournament: tournament,
                          onTap: () {
                            // Detail screen logic
                          },
                        ),
                      );
                    },
                    childCount: tournaments.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _UpcomingHeaderDelegate({
    required this.collapseFraction,
    required this.username,
    required this.quote,
    required this.searchController,
    required this.onSearchChanged,
  });

  final double collapseFraction;
  final String username;
  final String quote;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  static const double _kSearchBarHeight = 52;
  static const double _kExpandedHeaderHeight = 100;

  @override
  double get minExtent => _kSearchBarHeight + 16;

  @override
  double get maxExtent => _kExpandedHeaderHeight + _kSearchBarHeight + 16;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final opacity = (1 - collapseFraction).clamp(0.0, 1.0);

    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CapsuleSearchBar(
                controller: searchController,
                onChanged: onSearchChanged,
              ),
            ),
          ),
          Positioned(
            top: _kSearchBarHeight + 16,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -collapseFraction * 20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ready for more, $username?',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Explore what\'s next in the arena',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondaryDark,
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
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
  bool shouldRebuild(covariant _UpcomingHeaderDelegate oldDelegate) {
    return oldDelegate.collapseFraction != collapseFraction ||
        oldDelegate.username != username ||
        oldDelegate.quote != quote;
  }
}

class _EmptyUpcomingState extends StatelessWidget {
  const _EmptyUpcomingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded,
              color: AppColors.textMuted, size: 48),
          SizedBox(height: 12),
          Text(
            'No upcoming tournaments',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
