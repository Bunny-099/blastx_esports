import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/transitions/fire_page_route.dart';
import '../../live/data/models/tournament_model.dart';
import '../../live/providers/live_provider.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../squad/presentation/my_squad_screen.dart';
import '../../tournaments/presentation/widgets/blastix_tournament_card.dart';
import '../data/models/home_data_models.dart';
import '../providers/home_provider.dart';
import '../providers/navigation_provider.dart';

/// ============================================================
/// HOME SCREEN — BLASTIX ARENA ESPORTS LANDING HUB
/// ============================================================
/// Redesigned landing hub according to exact visual specifications:
/// 1. Top Header App Bar (BlastX Arena Logo & Notifications)
/// 2. Hero Banner Slider Carousel (Dynamic Admin Sync Ready)
/// 3. User Profile Greeting Card (Positioned below Hero Banner with Crown Badge)
/// 4. Quick Action Grid (2x2 Grid Cards: Tournaments, Live Matches, Daily Quests, My Squad)
/// 5. Live Tournaments Section (BLASTIX ARENA stream card with live viewers chip)
/// 6. Our Partners Section (Brand partner logos)
/// 7. Partner With Us CTA Banner & Interactive Inquiry Dialog
/// ============================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _bannerController = PageController();
  late final PageController _streamController = PageController();
  late Timer _carouselTimer;

  int _currentBannerIndex = 0;
  int _currentStreamIndex = 0;

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _startAutoCarousel();
  }

  void _startAutoCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final featuredTournaments = ref.read(homeFeaturedTournamentsProvider);
      final banners = ref.read(homeBannersProvider).value ?? [];
      final count = featuredTournaments.isNotEmpty ? featuredTournaments.length : banners.length;
      if (count == 0) return;
      final nextIndex = (_currentBannerIndex + 1) % count;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _bannerController.dispose();
    _streamController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(homeBannersProvider);
    ref.invalidate(liveStreamsProvider);
    ref.invalidate(partnersProvider);
    ref.invalidate(blastxTournamentsApiProvider);
    ref.invalidate(blastxLiveTournamentsApiProvider);
    ref.invalidate(blastxUpcomingTournamentsApiProvider);
    await ref.read(profileProvider.notifier).loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    // Watch profile for dynamic username & avatar
    final profileState = ref.watch(profileProvider);
    final user = profileState.user;
    final profileName = user?.name;
    final displayName = (profileName != null && profileName.trim().isNotEmpty)
        ? profileName.trim()
        : (widget.username.isNotEmpty ? widget.username : 'Player');

    final featuredTournaments = ref.watch(homeFeaturedTournamentsProvider);
    final banners = ref.watch(homeBannersProvider).value ?? [];
    final liveStreams = ref.watch(liveStreamsProvider).value ?? [];
    final partners = ref.watch(partnersProvider).value ?? [];

    final showCrownBadge = user?.isVip == true || user?.crownBadgeUnlocked == true || true;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17), // Deep Dark Charcoal/Black
      body: Stack(
        children: [
          // Ambient breathing background glows
          _AmbientBackground(controller: _ambientController),

          SafeArea(
            child: RefreshIndicator(
              color: const Color(0xFF00F5FF),
              backgroundColor: const Color(0xFF101722),
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER / APP BAR
                  const _TopHeaderAppBar(),
                  const SizedBox(height: 12),

                  // 2. FEATURED EVENT BANNER SLIDER (HERO BANNER)
                  if (banners.isNotEmpty) ...[
                    _HeroBannerCarousel(
                      banners: banners,
                      controller: _bannerController,
                      currentIndex: _currentBannerIndex,
                      onPageChanged: (index) {
                        setState(() => _currentBannerIndex = index);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 3. USER PROFILE GREETING CARD (POSITIONED BELOW HERO BANNER)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _UserProfileGreetingCard(
                      displayName: displayName,
                      userAvatarUrl: user?.profilePic,
                      showCrownBadge: showCrownBadge,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. QUICK ACTION GRID (2x2 GRID CARDS)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const _QuickActionGrid(),
                  ),
                  const SizedBox(height: 24),

                  // 5. LIVE TOURNAMENTS SECTION [BLASTIX ARENA] - REUSING BLASTIX TOURNAMENT CARD
                  _LiveTournamentsSection(
                    tournaments: featuredTournaments,
                    streams: liveStreams,
                    controller: _streamController,
                    currentIndex: _currentStreamIndex,
                    onPageChanged: (index) {
                      setState(() => _currentStreamIndex = index);
                    },
                  ),
                  const SizedBox(height: 24),

                  // 6. OUR PARTNERS SECTION
                  _OurPartnersSection(partners: partners),
                  const SizedBox(height: 24),

                  // 7. PARTNER WITH US CALL-TO-ACTION BANNER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const _PartnerWithUsBanner(),
                  ),
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

/// ------------------------------------------------------------
/// 1. TOP HEADER APP BAR
/// ------------------------------------------------------------
class _TopHeaderAppBar extends StatelessWidget {
  const _TopHeaderAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: BlastX Arena Logo & Styled Uppercase Branding
          Expanded(
            child: Row(
              children: [
                Image.asset(
                  'assets/logos/app_logo.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.bolt_rounded,
                    color: Color(0xFF00F5FF),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'BLASTIX ',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF00F5FF),
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextSpan(
                            text: 'ARENA',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: Notification Bell Icon
          const _HeaderNotificationBell(),
        ],
      ),
    );
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFF121B28),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF00F5FF),
              size: 22,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2D55),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
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
/// 2. FEATURED EVENT BANNER SLIDER (HERO BANNER)
/// ------------------------------------------------------------
class _HeroBannerCarousel extends ConsumerWidget {
  const _HeroBannerCarousel({
    required this.banners,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<BannerItem> banners;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    ref.read(navigationIndexProvider.notifier).state =
                        banner.targetTabIndex;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF00F5FF).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F5FF).withValues(alpha: 0.1),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Graphic Image
                        (banner.imageUrl.startsWith('http'))
                            ? Image.network(
                                banner.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset('assets/images/top_banner.jpg', fit: BoxFit.cover),
                              )
                            : Image.asset(
                                banner.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(color: const Color(0xFF141F30)),
                              ),

                        // Gradient Overlays
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.4),
                                Colors.black.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                          ),
                        ),

                        // Banner Content Layout
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Row: Tagline & Top Right Brand Badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      banner.tagline,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.rajdhani(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFFD200),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF00F5FF)
                                            .withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt_rounded,
                                            color: Color(0xFF00F5FF), size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          banner.brandBadge,
                                          style: GoogleFonts.orbitron(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Middle Title & Subtitle Stack
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    banner.title,
                                    style: GoogleFonts.orbitron(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      shadows: [
                                        const Shadow(
                                          color: Color(0xFF00F5FF),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    banner.subtitle,
                                    style: GoogleFonts.rajdhani(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFCBD5E1),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                              // Bottom CTA Pill Button
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD200),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD200)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        banner.buttonText,
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (index) {
              final isSelected = currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: isSelected ? 20 : 6,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00F5FF)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// ------------------------------------------------------------
/// 3. USER PROFILE GREETING CARD (POSITIONED BELOW HERO BANNER)
/// ------------------------------------------------------------
class _UserProfileGreetingCard extends StatelessWidget {
  const _UserProfileGreetingCard({
    required this.displayName,
    this.userAvatarUrl,
    this.showCrownBadge = true,
  });

  final String displayName;
  final String? userAvatarUrl;
  final bool showCrownBadge;

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning! Stay in the zone. 🎮';
    if (hour < 17) return 'Good Afternoon! Stay in the zone. 🎮';
    return 'Good Evening! Stay in the zone. 🎮';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Avatar Circle with Gold Crown Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF00F5FF),
                    width: 2,
                  ),
                  color: const Color(0xFF1E293B),
                ),
                child: ClipOval(
                  child: (userAvatarUrl != null && userAvatarUrl!.isNotEmpty)
                      ? Image.network(
                          userAvatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person_rounded,
                                  color: Color(0xFF94A3B8), size: 30),
                        )
                      : const Icon(Icons.person_rounded,
                          color: Color(0xFF94A3B8), size: 30),
                ),
              ),

              // Gold Crown Badge (attached to bottom right of avatar)
              if (showCrownBadge)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD200),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD200).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Text(
                        '👑',
                        style: TextStyle(fontSize: 10, height: 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // User Name & Greeting Text Stack
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Hey, $displayName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rajdhani(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _greetingText,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Play  •  Compete  •  Earn  •  Be Part of the Community',
                  style: GoogleFonts.rajdhani(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.3,
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
/// 4. QUICK ACTION GRID (2x2 GRID CARDS)
/// ------------------------------------------------------------
class _QuickActionGrid extends ConsumerWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QuickCardData(
        title: 'Tournaments',
        subtitle: 'Join & Compete',
        icon: Icons.emoji_events_rounded,
        accentColor: const Color(0xFF00F5FF), // Cyan
        onTap: () => ref.read(navigationIndexProvider.notifier).state = 1,
      ),
      _QuickCardData(
        title: 'Live Matches',
        subtitle: 'Watch Official\nTournaments',
        icon: Icons.sensors_rounded,
        accentColor: const Color(0xFFFF2D55), // Red
        onTap: () => ref.read(navigationIndexProvider.notifier).state = 2,
      ),
      _QuickCardData(
        title: 'Daily Quests',
        subtitle: 'Earn Rewards',
        icon: Icons.star_rounded,
        accentColor: const Color(0xFFFFD200), // Gold/Yellow
        onTap: () => ref.read(navigationIndexProvider.notifier).state = 3,
      ),
      _QuickCardData(
        title: 'My Squad',
        subtitle: 'Create or Join',
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFFA855F7), // Purple
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
        childAspectRatio: 1.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF101722),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: item.accentColor.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.accentColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Custom Colored Icon
                Icon(item.icon, color: item.accentColor, size: 28),

                // Bottom Row: Title, Subtitle & Arrow Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            item.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Circular Arrow Button
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: item.accentColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: item.accentColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  _QuickCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}

/// ------------------------------------------------------------
/// 5. LIVE TOURNAMENTS SECTION [BLASTIX ARENA] - REUSING BLASTIX TOURNAMENT CARD
/// ------------------------------------------------------------
class _LiveTournamentsSection extends ConsumerWidget {
  const _LiveTournamentsSection({
    this.tournaments = const [],
    this.streams = const [],
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final List<TournamentModel> tournaments;
  final List<LiveStreamCardItem> streams;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTournaments = tournaments.isNotEmpty;
    final hasStreams = streams.isNotEmpty;

    if (!hasTournaments && !hasStreams) return const SizedBox.shrink();

    final totalCount = hasTournaments ? tournaments.length : streams.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.sensors_rounded,
                        color: Color(0xFFFF2D55), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'LIVE TOURNAMENTS ',
                                style: GoogleFonts.orbitron(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              TextSpan(
                                text: '[BLASTIX ARENA]',
                                style: GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFD200),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ref.read(navigationIndexProvider.notifier).state = 1; // Tournaments tab
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF00F5FF),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF00F5FF), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Carousel (Reusing BlastIXTournamentCard for Tournaments)
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: totalCount,
            itemBuilder: (context, index) {
              if (hasTournaments) {
                final tournament = tournaments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BlastIXTournamentCard(
                    tournament: tournament,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/tournament-detail',
                        arguments: tournament.id,
                      );
                    },
                  ),
                );
              }

              final stream = streams[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF101722),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF00F5FF).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        stream.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: const Color(0xFF1E293B)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF2D55),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 3,
                                        backgroundColor: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'LIVE',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.remove_red_eye_rounded,
                                          color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        stream.viewerCount,
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stream.title,
                                  style: GoogleFonts.orbitron(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${stream.subtitle}  •  Live from ${stream.location}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00F5FF)
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: const Color(0xFF00F5FF)
                                                    .withValues(alpha: 0.5),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              '🛡️ Official Tournament',
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF00F5FF),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '📍 ${stream.location}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.rajdhani(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        ref
                                            .read(navigationIndexProvider.notifier)
                                            .state = 2; // Live tab
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD200),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFFD200)
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          stream.ctaText,
                                          style: GoogleFonts.rajdhani(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
            },
          ),
        ),
        const SizedBox(height: 8),

        // Indicator Dots
        if (totalCount > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCount, (index) {
              final isSelected = currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 5,
                width: isSelected ? 16 : 5,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00F5FF)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// 6. OUR PARTNERS SECTION
/// ------------------------------------------------------------
class _OurPartnersSection extends StatelessWidget {
  const _OurPartnersSection({required this.partners});

  final List<PartnerItem> partners;

  @override
  Widget build(BuildContext context) {
    if (partners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('🤝', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OUR PARTNERS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.orbitron(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'View All →',
                style: GoogleFonts.rajdhani(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF00F5FF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Row of Partner Brand Cards
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final partner = partners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF101722),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (partner.logoUrl != null && partner.logoUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          partner.logoUrl!,
                          height: 22,
                          width: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.handshake_rounded,
                                  color: Color(0xFF00F5FF), size: 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else if (partner.icon != null) ...[
                      Icon(partner.icon, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(Icons.handshake_rounded,
                          color: Color(0xFF00F5FF), size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      partner.name,
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// 7. PARTNER WITH US CALL-TO-ACTION BANNER
/// ------------------------------------------------------------
class _PartnerWithUsBanner extends StatelessWidget {
  const _PartnerWithUsBanner();

  void _showPartnerInquiryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _PartnerInquiryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A131F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F5FF).withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Title
          Text(
            'JOIN US AS A PARTNER',
            style: GoogleFonts.orbitron(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00F5FF),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),

          // 3 Feature Pillars Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _FeaturePillar(
                iconText: '📊',
                title: 'Brand\nVisibility',
              ),
              _FeaturePillar(
                iconText: '👥',
                title: 'Community\nEngagement',
              ),
              _FeaturePillar(
                iconText: '👑',
                title: 'On-Ground &\nDigital Presence',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CTA Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPartnerInquiryDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00F5FF),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF00F5FF).withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Partner With Us',
                    style: GoogleFonts.rajdhani(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePillar extends StatelessWidget {
  const _FeaturePillar({
    required this.iconText,
    required this.title,
  });

  final String iconText;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(iconText, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFCBD5E1),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// INTERACTIVE PARTNER INQUIRY DIALOG
/// ------------------------------------------------------------
class _PartnerInquiryDialog extends ConsumerStatefulWidget {
  const _PartnerInquiryDialog();

  @override
  ConsumerState<_PartnerInquiryDialog> createState() =>
      __PartnerInquiryDialogState();
}

class __PartnerInquiryDialogState
    extends ConsumerState<_PartnerInquiryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _brandNameController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();

  final String _selectedPartnershipType = 'Sponsorship';

  @override
  void dispose() {
    _brandNameController.dispose();
    _contactNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitInquiry() async {
    if (!_formKey.currentState!.validate()) return;

    final inquiry = PartnerInquiry(
      brandName: _brandNameController.text.trim(),
      contactName: _contactNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      partnershipType: _selectedPartnershipType,
      message: _messageController.text.trim(),
    );

    final success = await ref
        .read(partnerInquiryProvider.notifier)
        .submitInquiry(inquiry);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Partner inquiry submitted! Our esports team will contact you shortly.'
                : 'Failed to submit inquiry. Please try again.',
            style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold, fontSize: 13),
          ),
          backgroundColor:
              success ? const Color(0xFF00F5FF) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerInquiryProvider);

    return Dialog(
      backgroundColor: const Color(0xFF101722),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF00F5FF), width: 1.2),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PARTNER WITH US',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF00F5FF),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                'Join forces with BlastX Arena to reach thousands of passionate gamers.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),

              _InputField(
                controller: _brandNameController,
                label: 'Brand / Company Name',
                icon: Icons.business_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              _InputField(
                controller: _contactNameController,
                label: 'Contact Person Name',
                icon: Icons.person_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              _InputField(
                controller: _emailController,
                label: 'Work Email Address',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 10),

              _InputField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),

              _InputField(
                controller: _messageController,
                label: 'Partnership Goals / Message',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : _submitInquiry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00F5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          'Submit Inquiry',
                          style: GoogleFonts.rajdhani(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
        prefixIcon: Icon(icon, color: const Color(0xFF00F5FF), size: 18),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: const Color(0xFF00F5FF).withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF00F5FF), width: 1.2),
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
            Container(color: const Color(0xFF0B0F17)),
            Positioned(
              top: -60 + (t * 25),
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.ambientGlowCyan,
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
                  gradient: AppColors.ambientGlowCyan,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
