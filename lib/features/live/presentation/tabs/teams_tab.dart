import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/transitions/fire_page_route.dart';
import '../../data/models/team_model.dart';
import '../../providers/live_provider.dart';
import '../../providers/team_provider.dart';
import '../team/tournament_match_room_screen.dart';

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

    final registeredTeamsAsync =
        ref.watch(registeredTeamsProvider(widget.tournamentId));
    final myTeamState = ref.watch(teamProvider(widget.tournamentId));
    final myTeam = myTeamState.team;
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));

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
                            page: TournamentMatchRoomScreen(
                              tournamentId: widget.tournamentId,
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
          registeredTeamsAsync.when(
            data: (teams) {
              if (teams.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              size: 40,
                              color: AppColors.accentOrange,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Registered Teams Yet',
                            style: AppTextStyles.headingMd,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete team registration to appear in this tournament list.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.92,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final team = teams[index];
                      final isMyTeam = myTeam != null && team.id == myTeam.id;

                      return _TeamGridCard(
                        team: team,
                        isMyTeam: isMyTeam,
                      );
                    },
                    childCount: teams.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'Failed to load teams: $err',
                    style:
                        AppTextStyles.bodySm.copyWith(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ── 2-Column Team Grid Card Widget ──
class _TeamGridCard extends StatelessWidget {
  const _TeamGridCard({
    required this.team,
    required this.isMyTeam,
  });

  final TournamentTeamModel team;
  final bool isMyTeam;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyTeam ? AppColors.primaryNeon : AppColors.border,
          width: isMyTeam ? 1.8 : 1.0,
        ),
        boxShadow: isMyTeam
            ? [
                BoxShadow(
                  color: AppColors.primaryNeon.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar & My Team badge
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceMuted,
                backgroundImage:
                    team.logoUrl.isNotEmpty ? NetworkImage(team.logoUrl) : null,
                child: team.logoUrl.isEmpty
                    ? const Icon(Icons.shield_rounded,
                        color: AppColors.accentOrange, size: 18)
                    : null,
              ),
              const Spacer(),
              if (isMyTeam)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNeon,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'YOU',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.bgNavy,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),

          const Spacer(),

          // Team Tag & Name
          Text(
            team.tag.isNotEmpty
                ? '[${team.tag}] ${team.name.toUpperCase()}'
                : team.name.toUpperCase(),
            style: AppTextStyles.headingLg.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 2),

          // Captain
          Text(
            'Cap: ${team.captainName.isNotEmpty ? team.captainName : 'Leader'}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Bottom Row: Member Count Badge
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 13,
                color: team.isReady
                    ? AppColors.primaryNeon
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              Text(
                '${team.members.length}/4 Players',
                style: AppTextStyles.caption.copyWith(
                  color: team.isReady
                      ? AppColors.primaryNeon
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
