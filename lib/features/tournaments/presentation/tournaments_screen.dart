import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../live/providers/live_provider.dart';
import '../../live/presentation/widgets/capsule_search_bar.dart';
import 'widgets/blastx_tournament_card.dart';
import 'widgets/upcoming_tournament_card.dart';

class TournamentsScreen extends ConsumerStatefulWidget {
  const TournamentsScreen({super.key, this.username = 'Player'});

  final String username;

  @override
  ConsumerState<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends ConsumerState<TournamentsScreen> with TickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _AmbientBackground(controller: _ambientController),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('BlastX Tournaments', style: AppTextStyles.headingLg),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surface,
                        child: const Icon(Icons.person_outline, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: CapsuleSearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      ref.read(upcomingSearchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'LIVE'),
                    Tab(text: 'UPCOMING'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TournamentsList(isLive: true),
                      _TournamentsList(isLive: false),
                    ],
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

class _TournamentsList extends ConsumerWidget {
  final bool isLive;
  const _TournamentsList({required this.isLive});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = isLive 
        ? ref.watch(filteredAppLiveTournamentsProvider)
        : ref.watch(filteredUpcomingTournamentsProvider);

    if (tournaments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLive ? Icons.videocam_off_outlined : Icons.event_busy_rounded,
              color: AppColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              isLive ? 'No live tournaments now' : 'No upcoming tournaments',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      itemCount: tournaments.length,
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return isLive 
            ? BlastXTournamentCard(
                tournament: tournament,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/tournament-detail',
                    arguments: tournament.id,
                  );
                },
              ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0)
            : UpcomingTournamentCard(
                tournament: tournament,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/tournament-detail',
                    arguments: tournament.id,
                  );
                },
              ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0);
      },
    );
  }
}

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
          ],
        );
      },
    );
  }
}
