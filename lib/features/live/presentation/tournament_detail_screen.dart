import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/transitions/fire_page_route.dart';
import '../../../features/squad/presentation/widgets/ask_leader_dialog.dart';
import '../../../features/squad/providers/squad_provider.dart';
import '../data/models/registration_status_helper.dart';
import '../data/models/team_model.dart';
import '../data/models/tournament_model.dart';
import '../providers/live_provider.dart';
import '../providers/team_provider.dart';
import 'tabs/my_lobby_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/roadmap_tab.dart';
import 'tabs/standings_bracket_tab.dart';
import 'tabs/teams_tab.dart';
import 'team/duo_join_screen.dart';
import 'team/join_tournament_screen.dart';
import 'team/player_approval_screen.dart';
import 'team/solo_register_screen.dart';
import 'team/team_lobby_screen.dart';

/// ============================================================
/// TOURNAMENT DETAIL SCREEN — Command Center Tabbed Edition
/// Header (Hero banner -> Title & stats) + Pinned TabBar
/// Tabs: Overview, Roadmap, Teams, Standings/Brackets, and Match (if confirmed)
/// + Sticky bottom action bar (Register / Watch Live)
/// ============================================================

class TournamentDetailScreen extends ConsumerStatefulWidget {
  const TournamentDetailScreen({
    super.key,
    required this.tournamentId,
    this.viewOnly = false,
    this.initialTabIndex = 0,
  });

  final String tournamentId;
  final bool viewOnly;
  final int initialTabIndex;

  @override
  ConsumerState<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState
    extends ConsumerState<TournamentDetailScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  bool _hasCheckedDeepLinkSnackBar = false;

  void _updateTabController(bool isConfirmed) {
    final newLength = isConfirmed ? 5 : 4;
    if (_tabController == null || _tabController!.length != newLength) {
      _tabController?.dispose();

      int initialIndex = widget.initialTabIndex;

      if (widget.initialTabIndex == 4 && !isConfirmed) {
        initialIndex = 0; // Fallback to Overview
        if (!_hasCheckedDeepLinkSnackBar) {
          _hasCheckedDeepLinkSnackBar = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Match tab is only available for confirmed registered teams.',
                  ),
                ),
              );
            }
          });
        }
      }

      final clampedIndex = initialIndex.clamp(0, newLength - 1);
      _tabController = TabController(
        length: newLength,
        vsync: this,
        initialIndex: clampedIndex,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Color _accentColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(tournamentByIdProvider(widget.tournamentId));

    if (t == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
            child: Text('Tournament not found', style: AppTextStyles.bodyMd)),
      );
    }

    final teamState = ref.watch(teamProvider(widget.tournamentId));
    final team = teamState.team;

    final isConfirmed = t.myRegistration?.state == MyRegistrationState.confirmed ||
        t.effectiveIsRegistered ||
        team?.isRegistered == true ||
        team?.registrationState == TeamRegistrationState.confirmed;

    _updateTabController(isConfirmed);

    final accent = _accentColor(t.accentColorHex);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _BottomCta(
        tournament: t,
        viewOnly: widget.viewOnly,
        isRegistered: isConfirmed,
        onNavigateToMatchTab: isConfirmed
            ? () {
                _tabController?.animateTo(4);
              }
            : null,
      ),
      body: NestedScrollView(
        physics: const BouncingScrollPhysics(),
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildAppBar(context, t, accent),
            SliverToBoxAdapter(child: _buildHeader(t, accent)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedTabBarDelegate(
                tabBar: TabBar(
                  controller: _tabController,
                  isScrollable: isConfirmed,
                  labelColor: AppColors.accentOrange,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: AppTextStyles.button.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  indicatorColor: AppColors.accentOrange,
                  indicatorWeight: 3.0,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(
                      color: AppColors.accentOrange,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  tabs: [
                    const Tab(text: 'Overview'),
                    const Tab(text: 'Roadmap'),
                    const Tab(text: 'Teams'),
                    const Tab(text: 'Standings / Brackets'),
                    if (isConfirmed) const Tab(text: 'Match'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            OverviewTab(
              tournament: t,
              accentColor: accent,
              viewOnly: widget.viewOnly,
            ),
            RoadmapTab(
              tournament: t,
              accentColor: accent,
            ),
            TeamsTab(
              tournamentId: t.id,
            ),
            StandingsBracketTab(
              tournamentId: t.id,
              accentColor: accent,
            ),
            if (isConfirmed)
              MyLobbyTab(
                tournamentId: t.id,
                accentColor: accent,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- App bar / banner ----------------
  SliverAppBar _buildAppBar(
      BuildContext context, TournamentModel t, Color accent) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 260,
      stretchTriggerOffset: 140,
      backgroundColor: AppColors.background,
      leading: _GlassIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.of(context).pop(),
      ),
      actions: [
        _GlassIconButton(icon: Icons.favorite_border_rounded, onTap: () {}),
        _GlassIconButton(icon: Icons.share_rounded, onTap: () {}),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'tournament-banner-${t.id}',
              child: Image.network(
                t.bannerImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: AppColors.surface),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.background.withValues(alpha: 0.4),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: 0.22), Colors.transparent],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),
            Positioned(top: 100, left: 20, child: _StatusPill(t.status)),
          ],
        ),
      ),
    );
  }

  // ---------------- Title / organizer / prize / quick stats ----------------
  Widget _buildHeader(TournamentModel t, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: _Chip(text: t.game, color: accent),
                    ),
                    if (t.tournamentCode.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '#${t.tournamentCode}',
                          style: AppTextStyles.caption,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.remove_red_eye_rounded,
                    color: AppColors.textSecondary,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${t.formattedViewers} watching',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Hero(
            tag: 'tournament-title-${t.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(t.displayTitle, style: AppTextStyles.headingXl),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Organized by ${t.organizer}',
                  style: AppTextStyles.bodySm,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (t.organizerVerified) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified_rounded, size: 15, color: accent),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _GlassPrizeCard(accent: accent, tournament: t),
          const SizedBox(height: 14),
          _QuickStats(t: t, accent: accent),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// ============================================================
/// PINNED TAB BAR DELEGATE
/// ============================================================

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabBarDelegate({required this.tabBar});

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height + 8;
  @override
  double get maxExtent => tabBar.preferredSize.height + 8;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return oldDelegate.tabBar != tabBar;
  }
}

/// ============================================================
/// STICKY BOTTOM ACTION BAR (CTA)
/// ============================================================

class _BottomCta extends ConsumerStatefulWidget {
  const _BottomCta({
    required this.tournament,
    this.viewOnly = false,
    this.isRegistered = false,
    this.onNavigateToMatchTab,
  });
  final TournamentModel tournament;
  final bool viewOnly;
  final bool isRegistered;
  final VoidCallback? onNavigateToMatchTab;

  @override
  ConsumerState<_BottomCta> createState() => _BottomCtaState();
}

class _BottomCtaState extends ConsumerState<_BottomCta> {
  Timer? _timer;
  bool _isRefreshingStatus = false;

  @override
  void initState() {
    super.initState();
    _checkTimerNeeded();
  }

  @override
  void didUpdateWidget(covariant _BottomCta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tournament.status != widget.tournament.status ||
        oldWidget.tournament.effectiveStartsAt != widget.tournament.effectiveStartsAt) {
      _checkTimerNeeded();
    }
  }

  void _checkTimerNeeded() {
    _timer?.cancel();
    if (widget.tournament.status == TournamentStatus.upcoming) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() {});
        final diff = widget.tournament.effectiveStartsAt.difference(DateTime.now());
        if (diff.inSeconds <= 0 && !_isRefreshingStatus) {
          _refreshTournamentStatus();
        }
      });
    }
  }

  Future<void> _refreshTournamentStatus() async {
    _isRefreshingStatus = true;
    try {
      await ref.read(tournamentDetailApiProvider(widget.tournament.id).future);
      ref.invalidate(blastxLiveTournamentsApiProvider);
      ref.invalidate(blastxUpcomingTournamentsApiProvider);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRefreshingStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatLiveCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.inSeconds <= 0) {
      return 'Checking Live Status...';
    }
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    final secs = diff.inSeconds % 60;

    if (days > 0) {
      return 'Opens in ${days}d ${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m';
    }
    return 'Opens in ${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tournament;
    final teamState = ref.watch(teamProvider(t.id));
    final team = teamState.team;

    final ctaState = getCtaState(t, team);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: _buildCtaContent(context, t, team, ctaState),
      ),
    );
  }

  Widget _buildCtaContent(
    BuildContext context,
    TournamentModel t,
    TournamentTeamModel? team,
    CtaState ctaState,
  ) {
    switch (ctaState.type) {
      // 1. Completed
      case CtaType.completed:
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: ctaState.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ctaState.icon != null) ...[
                Icon(ctaState.icon, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                ctaState.label,
                style: TextStyle(
                  color: ctaState.textColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );

      // 2. Upcoming Countdown
      case CtaType.upcomingCountdown:
        final isZero = t.effectiveStartsAt.difference(DateTime.now()).inSeconds <= 0;
        final countdownText = _isRefreshingStatus || isZero
            ? 'VERIFYING BACKEND STATUS...'
            : 'REGISTRATION OPENS WHEN LIVE • ${_formatLiveCountdown(t.effectiveStartsAt)}';

        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: ctaState.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isRefreshingStatus || isZero
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentOrange,
                      ),
                    )
                  : Icon(ctaState.icon, color: AppColors.accentOrange, size: 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  countdownText,
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        );

      // 3. Confirmed
      case CtaType.confirmed:
        return GestureDetector(
          onTap: () {
            if (widget.onNavigateToMatchTab != null) {
              widget.onNavigateToMatchTab!();
            } else {
              Navigator.of(context).push(
                FirePageRoute(
                  page: TeamLobbyScreen(tournamentId: t.id),
                ),
              );
            }
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: ctaState.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryNeon.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctaState.icon != null) ...[
                  Icon(ctaState.icon, color: ctaState.textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  ctaState.label,
                  style: TextStyle(
                    color: ctaState.textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      // 4. Waitlisted
      case CtaType.waitlisted:
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              FirePageRoute(
                page: TeamLobbyScreen(tournamentId: t.id),
              ),
            );
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: ctaState.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentOrange.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctaState.icon != null) ...[
                  Icon(ctaState.icon, color: ctaState.textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  ctaState.label,
                  style: TextStyle(
                    color: ctaState.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      // 5. Approve Participation
      case CtaType.approveParticipation:
        final approvalId = t.myRegistration?.myPendingApprovalId ?? team?.myPendingApprovalId ?? '';
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              FirePageRoute(
                page: PlayerApprovalScreen(
                  approvalId: approvalId,
                  tournamentId: t.id,
                ),
              ),
            );
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: ctaState.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNeon.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctaState.icon != null) ...[
                  Icon(ctaState.icon, color: ctaState.textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  ctaState.label,
                  style: TextStyle(
                    color: ctaState.textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      // 6. Waiting Approvals
      case CtaType.waitingApprovals:
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              FirePageRoute(
                page: TeamLobbyScreen(tournamentId: t.id),
              ),
            );
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: ctaState.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentOrange.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctaState.icon != null) ...[
                  Icon(ctaState.icon, color: ctaState.textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  ctaState.label,
                  style: TextStyle(
                    color: ctaState.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      // 7. Roster Change Required
      case CtaType.rosterChangeRequired:
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              FirePageRoute(
                page: TeamLobbyScreen(tournamentId: t.id),
              ),
            );
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: ctaState.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctaState.icon != null) ...[
                  Icon(ctaState.icon, color: ctaState.textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  ctaState.label,
                  style: TextStyle(
                    color: ctaState.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      // 8. Forming (Team exists)
      case CtaType.forming:
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              FirePageRoute(
                page: TeamLobbyScreen(tournamentId: t.id),
              ),
            );
          },
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: ctaState.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNeon.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (ctaState.icon != null) ...[
                  Icon(ctaState.icon, color: ctaState.textColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  ctaState.label,
                  style: TextStyle(
                    color: ctaState.textColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );

      // 9 & 10. Live Full / Live Join Now
      case CtaType.liveFullNoRegistration:
      case CtaType.liveJoinNow:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                final modeUpper = t.mode.trim().toUpperCase();
                if (modeUpper == 'SOLO' || modeUpper.contains('SOLO')) {
                  Navigator.of(context).push(
                    FirePageRoute(
                      page: SoloRegisterScreen(tournamentId: t.id),
                    ),
                  );
                } else if (modeUpper == 'DUO' || modeUpper.contains('DUO')) {
                  Navigator.of(context).push(
                    FirePageRoute(
                      page: DuoJoinScreen(tournamentId: t.id),
                    ),
                  );
                } else {
                  final squadState = ref.read(squadProvider);
                  if (squadState.hasSquad && !squadState.isOwner) {
                    showAskLeaderDialog(context);
                  } else {
                    Navigator.of(context).push(
                      FirePageRoute(
                        page: JoinTournamentScreen(tournamentId: t.id),
                      ),
                    );
                  }
                }
              },
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.fireGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (ctaState.icon != null) ...[
                      Icon(ctaState.icon, color: AppColors.bgNavy, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      ctaState.label,
                      style: const TextStyle(
                        color: AppColors.bgNavy,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (ctaState.subNote != null) ...[
              const SizedBox(height: 6),
              Text(
                ctaState.subNote!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accentOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
    }
  }
}

/// ============================================================
/// SMALL REUSABLE HEADER WIDGETS
/// ============================================================

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.t, required this.accent});
  final TournamentModel t;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      (Icons.groups_rounded, 'Teams', t.teamsFilled),
      if (t.mode.isNotEmpty) (Icons.sports_esports_rounded, 'Mode', t.mode),
      if (t.mapName.isNotEmpty) (Icons.map_rounded, 'Map', t.mapName),
      if (t.matchType.isNotEmpty) (Icons.bolt_rounded, 'Type', t.matchType),
      (Icons.confirmation_number_rounded, 'Entry', t.formattedEntryFee),
      (Icons.schedule_rounded, 'Starts', _fmt(t.startTime)),
    ];

    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map((i) => SizedBox(
          width: w,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(i.$1, color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i.$2, style: AppTextStyles.caption),
                      Text(i.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ))
            .toList(),
      );
    });
  }

  String _fmt(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${m[d.month - 1]}, $h:$min $ap';
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color, width: 1),
    ),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(color: color),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
  );
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: Colors.white, size: 17),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final TournamentStatus status;

  @override
  Widget build(BuildContext context) {
    final live = status == TournamentStatus.live;
    final label = switch (status) {
      TournamentStatus.live => 'LIVE NOW',
      TournamentStatus.upcoming => 'UPCOMING',
      TournamentStatus.completed => 'COMPLETED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: live ? AppColors.fireGradient : null,
        color: live ? null : Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: live ? null : Border.all(color: Colors.white24),
        boxShadow: live
            ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.5), blurRadius: 12)]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            const Icon(Icons.circle, color: Colors.white, size: 8),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GlassPrizeCard extends StatelessWidget {
  const _GlassPrizeCard({required this.accent, required this.tournament});
  final Color accent;
  final TournamentModel tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(1.2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: AppColors.glassBorder(accent),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(gradient: AppColors.glassFill),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (b) => AppColors.goldGradient.createShader(b),
                  child: const Icon(Icons.emoji_events_rounded,
                      color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Prize Pool', style: AppTextStyles.bodySm),
                      const SizedBox(height: 2),
                      Text(
                        tournament.formattedPrizePool,
                        style: AppTextStyles.headingLg
                            .copyWith(color: AppColors.gold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
