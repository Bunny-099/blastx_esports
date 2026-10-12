import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/transitions/fire_page_route.dart';
import '../../providers/live_provider.dart';
import '../../providers/team_provider.dart';
import '../tournament_detail_screen.dart';
import '../widgets/registered_teams_grid.dart';

/// ============================================================
/// TEAMS TAB
/// Displays 2-column Grid of registered teams in the tournament
/// ============================================================

class TeamsTab extends ConsumerStatefulWidget {
  const TeamsTab({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends ConsumerState<TeamsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final myTeamState = ref.watch(teamProvider(widget.tournamentId));
    final myTeam = myTeamState.team;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(registeredTeamsProvider(widget.tournamentId));
        await ref.read(teamProvider(widget.tournamentId).notifier).refresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header Summary / Room Quick Link
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REGISTERED TEAMS', style: AppTextStyles.headingLg),
                      const SizedBox(height: 2),
                      Text(
                        'Grid View • Squad Roster of 4',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  if (myTeam != null && myTeam.isRegistered)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNeon,
                        foregroundColor: AppColors.bgNavy,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          FirePageRoute(
                            page: TournamentDetailScreen(
                              tournamentId: widget.tournamentId,
                              initialTabIndex: 4,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.vpn_key_rounded, size: 16),
                      label: Text(
                        'ROOM LOBBY',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.bgNavy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Registered Teams Grid (2 Columns)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
            sliver: SliverToBoxAdapter(
              child: RegisteredTeamsGrid(
                tournamentId: widget.tournamentId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
