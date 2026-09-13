import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/live_provider.dart';
import 'widgets/tournament_card.dart';

/// ============================================================
/// PREMIUM LIVE SCREEN
/// ============================================================
/// Adapted to the EXISTING light/pastel AppColors theme.
/// Features:
///  1. 3D capsule search bar - LIGHT neumorphic style.
///  2. Greeting block that collapses & fades away on scroll.
///  3. Angular-cut tournament cards list with accent glow.
/// ============================================================

class _LocalTokens {
  _LocalTokens._();

  static final LinearGradient primaryGradient = LinearGradient(
    colors: AppColors.primaryGradient,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color searchBarShadowLight = Colors.white;
  static const Color searchBarShadowDark = Color(0xFFE3E3DC);
}

const double _kExpandedHeaderHeight = 150;
const double _kSearchBarHeight = 52;

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  double _collapseFraction = 0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(filteredTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                    const Text(
                      'Live Tournaments',
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
                        gradient: TournamentCardGradients.liveGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${tournaments.where((t) => t.isLive).length} LIVE',
                        style: const TextStyle(
                          color: Colors.white,
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
                            Navigator.of(context).pushNamed(
                              '/tournament-detail',
                              arguments: tournament.id,
                            );
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
          // 1. Background Image (Collapsing)
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
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/top_banner.jpg',
                        fit: BoxFit.cover,
                      ),
                      // Dark Overlay for readability
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Greeting & Profile Icon
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
                      Text(
                        'Hey, $username 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        greetingText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(
                          quote,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Search Bar (Separated below)
          Positioned(
            bottom: 12,
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

class CapsuleSearchBar extends StatelessWidget {
  const CapsuleSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _kSearchBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: _LocalTokens.searchBarShadowDark,
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
          BoxShadow(
            color: _LocalTokens.searchBarShadowLight,
            offset: Offset(-4, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 18),
          ShaderMask(
            shaderCallback: (bounds) =>
                _LocalTokens.primaryGradient.createShader(bounds),
            child: const Icon(Icons.search_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search tournaments, games...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                ),
                isCollapsed: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_esports_rounded,
              color: AppColors.textMuted, size: 48),
          SizedBox(height: 12),
          Text(
            'No tournaments found',
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
