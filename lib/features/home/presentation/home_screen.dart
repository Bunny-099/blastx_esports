import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/transitions/fire_page_route.dart';
import '../../live/data/models/tournament_model.dart';
import '../../live/presentation/tournament_detail_screen.dart';
import '../../live/providers/live_provider.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../squad/presentation/my_squad_screen.dart';
import '../data/models/home_data_models.dart';
import '../providers/home_provider.dart';
import '../providers/navigation_provider.dart';

/// ============================================================
/// HOME SCREEN — REDESIGNED BLASTIX ESPORTS LANDING HUB
/// ============================================================
/// Modern dynamic esports landing hub featuring:
/// - Collapsing Header with dynamic greeting & quote
/// - Gamer Profile & Rank/XP Stats Banner
/// - Animated Announcement Ticker
/// - Auto-scrolling Promotional Carousel Banner
/// - Esports Hub Quick Action Grid
/// - Daily Quests & Rewards Teaser Card
/// - Dynamic Sections (Titles & lists shown ONLY when tournaments exist):
///   1. BlastX Live Tournaments
///   2. BlastX Upcoming Tournaments
///   3. Free Fire Official Tournaments
/// - Community Notices & News Board
/// ============================================================

const double _kExpandedHeaderHeight = 140;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _collapseFraction = 0;

  late final PageController _bannerController = PageController();
  late Timer _carouselTimer;
  int _currentBannerIndex = 0;

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
    _startAutoCarousel();
  }

  void _onScroll() {
    if (!mounted) return;
    final offset = _scrollController.offset.clamp(0, _kExpandedHeaderHeight);
    final fraction = offset / _kExpandedHeaderHeight;
    if ((fraction - _collapseFraction).abs() > 0.01) {
      setState(() => _collapseFraction = fraction);
    }
  }

  void _startAutoCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      final banners = ref.read(homeBannersProvider);
      if (banners.isEmpty) return;
      final nextIndex = (_currentBannerIndex + 1) % banners.length;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _carouselTimer.cancel();
    _bannerController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch User Profile for dynamic username
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final profileName = user?.name;
    final displayName = (profileName != null && profileName.trim().isNotEmpty)
        ? profileName.trim()
        : (widget.username != 'Player' ? widget.username : 'Player');

    final banners = ref.watch(homeBannersProvider);
    final announcements = ref.watch(homeAnnouncementsProvider);
    final notices = ref.watch(homeNoticesProvider);

    // Dynamic Tournament Providers
    final blastxLiveTournaments = ref.watch(appLiveTournamentsProvider);
    final blastxUpcomingTournaments = ref.watch(appUpcomingTournamentsProvider);
    final freeFireOfficialTournaments = ref.watch(officialTournamentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Ambient breathing background
          _AmbientBackground(controller: _ambientController),

          // 2. Main Scrollable Content
          SafeArea(
            top: false,
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Top Collapsing Header with Username, Greeting & BlastiX Logo
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CollapsingHeaderDelegate(
                    collapseFraction: _collapseFraction,
                    username: displayName,
                    greetingText: _greetingText,
                    quote: _quote,
                  ),
                ),

                // 2. DAILY ESPORTS QUEST
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: _DailyQuestsTeaserCard(),
                  ),
                ),

                // 3. LIVE TOURNAMENTS
                if (blastxLiveTournaments.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: _SectionHeader(
                        title: '🔴 BLASTX LIVE TOURNAMENTS',
                        actionText: 'Watch All ➔',
                        onTapAction: () {
                          ref.read(navigationIndexProvider.notifier).state = 2; // Live tab
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 215,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: blastxLiveTournaments.length,
                        itemBuilder: (context, index) {
                          final tournament = blastxLiveTournaments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _EsportsTournamentCard(
                              tournament: tournament,
                              badgeText: '🔴 LIVE',
                              badgeColor: AppColors.secondary,
                              buttonText: 'WATCH',
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
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Live Announcement Ticker
                if (announcements.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: _AnnouncementTicker(announcements: announcements),
                    ),
                  ),

                // Promotional Banner Carousel
                if (banners.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: PageView.builder(
                            controller: _bannerController,
                            onPageChanged: (index) {
                              setState(() => _currentBannerIndex = index);
                            },
                            itemCount: banners.length,
                            itemBuilder: (context, index) {
                              final banner = banners[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: _BannerCard(
                                  banner: banner,
                                  onTap: () {
                                    ref
                                        .read(navigationIndexProvider.notifier)
                                        .state = banner.targetTabIndex;
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Indicator dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(banners.length, (index) {
                            final isSelected = _currentBannerIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: isSelected ? 24 : 6,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textMuted.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                // ============================================================
                // DYNAMIC SECTION 2: BLASTX UPCOMING TOURNAMENTS
                // (Only visible when blastxUpcomingTournaments is NOT empty)
                // ============================================================
                if (blastxUpcomingTournaments.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: _SectionHeader(
                        title: '⚡ BLASTX UPCOMING TOURNAMENTS',
                        actionText: 'View All ➔',
                        onTapAction: () {
                          ref.read(navigationIndexProvider.notifier).state = 1; // Tournaments tab
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 215,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: blastxUpcomingTournaments.length,
                        itemBuilder: (context, index) {
                          final tournament = blastxUpcomingTournaments[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _EsportsTournamentCard(
                              tournament: tournament,
                              badgeText: tournament.statusBadgeText.toUpperCase(),
                              badgeColor: tournament.isRegistrationOpen ? AppColors.primaryNeon : AppColors.primary,
                              buttonText: tournament.actionButtonText,
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
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // ============================================================
                // DYNAMIC SECTION 3: FREE FIRE OFFICIAL TOURNAMENTS
                // (Only visible when freeFireOfficialTournaments is NOT empty)
                // ============================================================
                if (freeFireOfficialTournaments.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: _SectionHeader(
                        title: '🔥 FREE FIRE OFFICIAL TOURNAMENTS',
                        actionText: 'View All ➔',
                        onTapAction: () {
                          ref.read(navigationIndexProvider.notifier).state = 2; // Live tab
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 215,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: freeFireOfficialTournaments.length,
                        itemBuilder: (context, index) {
                          final tournament = freeFireOfficialTournaments[index];
                          final isLive = tournament.isLive;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _EsportsTournamentCard(
                              tournament: tournament,
                              badgeText: isLive ? '🔴 FF LIVE' : tournament.statusBadgeText.toUpperCase(),
                              badgeColor: isLive ? AppColors.secondary : AppColors.primaryNeon,
                              buttonText: tournament.actionButtonText,
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
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // Community Announcements & Notice Board
                if (notices.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: AppColors.fireGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('NOTICES & NEWS', style: AppTextStyles.headingMd),
                        ],
                      ),
                    ),
                  ),

                  // Notice Items List
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notice = notices[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NoticeCard(notice: notice)
                                .animate(delay: (80 * index).ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                          );
                        },
                        childCount: notices.length,
                      ),
                    ),
                  ),
                ],

                // ============================================================
                // ESPORTS HUB SHORTCUTS GRID (SABSE NICHE / AT THE VERY BOTTOM)
                // ============================================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: AppColors.fireGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('ESPORTS HUB', style: AppTextStyles.headingMd),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _QuickActionGrid(),
                      ],
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
/// Reusable Section Header with title and View All action
/// ------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onTapAction,
  });

  final String title;
  final String actionText;
  final VoidCallback onTapAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppColors.fireGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.headingMd.copyWith(
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onTapAction,
          child: Text(
            actionText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}



/// ------------------------------------------------------------
/// Daily Quests Teaser Banner Card
/// ------------------------------------------------------------
class _DailyQuestsTeaserCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: AppColors.secondaryLight,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DAILY ESPORTS QUEST',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+200 XP',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 8.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Record & Upload Match Proof to Earn Rewards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ref.read(navigationIndexProvider.notifier).state = 3; // Challenges / Quests tab
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: AppColors.fireGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                'Play',
                style: AppTextStyles.button.copyWith(
                  fontSize: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Collapsing Top Banner Header Delegate
/// ------------------------------------------------------------
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
            top: topPadding + 14,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, -collapseFraction * 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BlastiX App Logo
                      Image.asset(
                        'assets/logos/app_logo.png',
                        height: 36,
                        width: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hey, $username 👋', style: AppTextStyles.headingXl),
                            const SizedBox(height: 2),
                            Text(greetingText, style: AppTextStyles.bodyMd),
                            const SizedBox(height: 4),
                            Text(
                              quote,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySm.copyWith(
                                fontStyle: FontStyle.italic,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _HeaderNotificationBell(),
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

class _HeaderNotificationBell extends ConsumerWidget {
  const _HeaderNotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          FirePageRoute(page: const NotificationsScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.borderCyan,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNeon.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primaryNeon,
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Ambient Background with floating glow circles
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
              top: -60 + (t * 25),
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ambientGlowOrange,
                ),
              ),
            ),
            Positioned(
              bottom: 100 - (t * 20),
              left: -70,
              child: Container(
                width: 280,
                height: 280,
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

/// ------------------------------------------------------------
/// Live Announcement Ticker Bar
/// ------------------------------------------------------------
class _AnnouncementTicker extends StatefulWidget {
  const _AnnouncementTicker({required this.announcements});
  final List<AnnouncementItem> announcements;

  @override
  State<_AnnouncementTicker> createState() => _AnnouncementTickerState();
}

class _AnnouncementTickerState extends State<_AnnouncementTicker> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.announcements.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.announcements[_currentIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.fireGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.campaign_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                item.message,
                key: ValueKey(item.id),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.tag,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.secondaryLight,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Banner Card Component for Carousel
/// ------------------------------------------------------------
class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.banner,
    required this.onTap,
  });

  final BannerItem banner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.surfaceMuted, AppColors.surface],
                  ),
                ),
              ),
            ),

            // Gradient Overlays
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withValues(alpha: 0.85),
                    AppColors.background.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: AppColors.fireGradient,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      banner.badgeText,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.rajdhani(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.buttonText,
                          style: AppTextStyles.button.copyWith(
                            fontSize: 12,
                            color: AppColors.bgNavy,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.bgNavy,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Quick Action Grid (Esports Shortcuts)
/// ------------------------------------------------------------
class _QuickActionGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickActionData(
        title: 'Tournaments',
        subtitle: 'Join & Win',
        icon: Icons.emoji_events_rounded,
        color: AppColors.glowSoft,
        onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
      ),
      _QuickActionData(
        title: 'Live Matches',
        subtitle: 'Watch Streams',
        icon: Icons.live_tv_rounded,
        color: AppColors.primaryNeon,
        onTap: () => ref.read(navigationIndexProvider.notifier).state = 2,
      ),
      _QuickActionData(
        title: 'Daily Quests',
        subtitle: 'Earn Rewards',
        icon: Icons.extension_rounded,
        color: AppColors.primaryDark,
        onTap: () => ref.read(navigationIndexProvider.notifier).state = 3,
      ),
      _QuickActionData(
        title: 'My Squad',
        subtitle: 'Manage Roster',
        icon: Icons.groups_rounded,
        color: AppColors.glowLight,
        onTap: () {
          Navigator.of(context).push(
            FirePageRoute(page: const MySquadScreen()),
          );
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// ------------------------------------------------------------
/// Unified Esports Tournament Horizontal Card Component
/// ------------------------------------------------------------
class _EsportsTournamentCard extends StatelessWidget {
  const _EsportsTournamentCard({
    required this.tournament,
    required this.onTap,
    this.badgeText,
    this.badgeColor,
    this.buttonText,
  });

  final TournamentModel tournament;
  final VoidCallback onTap;
  final String? badgeText;
  final Color? badgeColor;
  final String? buttonText;

  @override
  Widget build(BuildContext context) {
    final title = tournament.displayTitle;
    final isLive = tournament.isLive;
    final prizePool = tournament.formattedPrizePool;
    final bannerUrl = tournament.bannerImageUrl.isNotEmpty
        ? tournament.bannerImageUrl
        : 'assets/images/top_banner.jpg';

    final effectiveBadgeText = badgeText ?? (isLive ? '🔴 LIVE' : tournament.statusBadgeText.toUpperCase());
    final effectiveBadgeColor = badgeColor ?? (isLive ? AppColors.secondary : AppColors.primary);
    final actionBtnText = buttonText ?? tournament.actionButtonText;

    final mapDisplay = tournament.mapName.isNotEmpty ? tournament.mapName : 'Bermuda';
    final gameDisplay = tournament.game.isNotEmpty ? tournament.game : 'Free Fire';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Top Image
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Image.network(
                    bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/top_banner.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.surface.withValues(alpha: 0.95),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Top Left Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: effectiveBadgeColor,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveBadgeColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Text(
                      effectiveBadgeText,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                // Top Right Game/Map Chip
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$gameDisplay • $mapDisplay',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body Information
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headingMd.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PRIZE POOL', style: AppTextStyles.caption.copyWith(fontSize: 9)),
                            ShaderMask(
                              shaderCallback: (bounds) => AppColors.goldGradient
                                  .createShader(Offset.zero & bounds.size),
                              child: Text(
                                prizePool,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: AppColors.fireGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Text(
                            actionBtnText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Community Notice Card Component
/// ------------------------------------------------------------
class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice});
  final NoticeItem notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: notice.isImportant
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notice.isImportant
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              notice.icon,
              color: notice.isImportant ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        notice.category,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${notice.date.day}/${notice.date.month}/${notice.date.year}',
                      style: AppTextStyles.caption.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notice.title,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notice.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
