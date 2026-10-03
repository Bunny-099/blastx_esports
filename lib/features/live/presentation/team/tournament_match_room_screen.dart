import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../challenges/providers/challenges_provider.dart';
import '../../data/models/team_model.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/live_provider.dart';
import '../../providers/team_provider.dart';
import '../widgets/room_details_card.dart';

/// ============================================================
/// TOURNAMENT MATCH & ROOM SCREEN
/// Shows status banner, Room ID/Pass, Start Match + Recording Button,
/// and 2-Column Grid of all Registered Teams.
/// ============================================================

class TournamentMatchRoomScreen extends ConsumerStatefulWidget {
  const TournamentMatchRoomScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<TournamentMatchRoomScreen> createState() =>
      _TournamentMatchRoomScreenState();
}

class _TournamentMatchRoomScreenState
    extends ConsumerState<TournamentMatchRoomScreen> {
  bool _isStartingMatch = false;

  Future<void> _handleStartMatch(TournamentModel? tournament) async {
    setState(() => _isStartingMatch = true);

    try {
      final recordingService = ref.read(screenRecordingServiceProvider);
      final gameLauncher = ref.read(gameLauncherServiceProvider);

      // Check game installation first
      final installedPkg = await gameLauncher.getInstalledPackageName();

      // 1. Start 480p Match Screen Recording FIRST
      final recordingStarted = await recordingService.startRecording(
        challengeId: widget.tournamentId,
      );

      if (recordingStarted) {
        ref.read(activeRecordingChallengeIdProvider.notifier).state =
            widget.tournamentId;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primaryNeon, width: 1.5),
              ),
              content: const Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.red, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '480p Screen Recording Active! Launching Free Fire...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }

        // 2. Launch Free Fire game SECOND
        if (installedPkg != null) {
          await gameLauncher.launchGame(packageName: installedPkg);
        } else {
          // Attempt fallback launch
          await gameLauncher.launchGame(packageName: 'com.dts.freefiremax');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text(
                'Screen recording permission required to record your tournament match.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Failed to start match: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingMatch = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final registeredTeamsAsync =
        ref.watch(registeredTeamsProvider(widget.tournamentId));
    final myTeamState = ref.watch(teamProvider(widget.tournamentId));
    final myTeam = myTeamState.team;

    final accentColor = tournament != null
        ? _parseColor(tournament.accentColorHex)
        : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tournament?.name.toUpperCase() ?? 'MATCH LOBBY',
              style: AppTextStyles.headingLg,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Tournament Match & Registered Teams',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(registeredTeamsProvider(widget.tournamentId));
          ref.invalidate(roomDetailsProvider(widget.tournamentId));
          await ref.read(teamProvider(widget.tournamentId).notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Countdown Banner / Status
              _LiveStatusBanner(
                tournament: tournament,
                accentColor: accentColor,
              ),

              const SizedBox(height: 16),

              // 2. Room Details Card
              if (tournament != null)
                RoomDetailsCard(
                  tournament: tournament,
                  accentColor: accentColor,
                ),

              // 3. START MATCH & RECORD BUTTON
              if (tournament != null && tournament.isLive) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryNeon,
                      foregroundColor: AppColors.bgNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 6,
                      shadowColor: AppColors.primaryNeon.withValues(alpha: 0.5),
                    ),
                    onPressed: _isStartingMatch
                        ? null
                        : () => _handleStartMatch(tournament),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isStartingMatch)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.bgNavy,
                            ),
                          )
                        else ...[
                          const Icon(Icons.videocam_rounded,
                              color: AppColors.bgNavy, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'START MATCH & RECORDING',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.bgNavy,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              // 4. Registered Teams Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REGISTERED TEAMS',
                        style: AppTextStyles.headingXl,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Grid View • 2 Columns',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  registeredTeamsAsync.when(
                    data: (teams) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '${teams.length} Teams',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryNeon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. 2-COLUMN GRID OF REGISTERED TEAMS
              registeredTeamsAsync.when(
                data: (teams) {
                  if (teams.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.groups_outlined,
                              size: 40, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No teams registered yet',
                            style: AppTextStyles.headingMd,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first team to register!',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: teams.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.92,
                    ),
                    itemBuilder: (context, index) {
                      final team = teams[index];
                      final isMyTeam = myTeam != null && team.id == myTeam.id;

                      return _TeamGridCard(
                        team: team,
                        isMyTeam: isMyTeam,
                        accentColor: accentColor,
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Failed to load registered teams: $err',
                          style: AppTextStyles.bodySm
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

/// ── Live Status Banner Header ──
class _LiveStatusBanner extends StatelessWidget {
  const _LiveStatusBanner({
    required this.tournament,
    required this.accentColor,
  });

  final TournamentModel? tournament;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (tournament == null) return const SizedBox.shrink();

    final isLive = tournament!.isLive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.primaryNeon.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? AppColors.primaryNeon : AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLive
                  ? AppColors.primaryNeon.withValues(alpha: 0.2)
                  : AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLive ? Icons.sensors_rounded : Icons.schedule_rounded,
              color: isLive ? AppColors.primaryNeon : AppColors.accentOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive ? 'TOURNAMENT IS LIVE' : 'TOURNAMENT UPCOMING',
                  style: AppTextStyles.headingMd.copyWith(
                    color: isLive ? AppColors.primaryNeon : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLive
                      ? 'Copy Room ID & Password below to join custom match'
                      : 'Room ID & Pass will reveal when tournament goes LIVE',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textSecondary,
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

/// ── 2-Column Team Grid Card Widget ──
class _TeamGridCard extends StatelessWidget {
  const _TeamGridCard({
    required this.team,
    required this.isMyTeam,
    required this.accentColor,
  });

  final TournamentTeamModel team;
  final bool isMyTeam;
  final Color accentColor;

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
