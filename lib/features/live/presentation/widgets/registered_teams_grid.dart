import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/team_model.dart';
import '../../providers/live_provider.dart';
import '../../providers/team_provider.dart';

/// Reusable 2-Column Grid of Registered Teams for a Tournament
class RegisteredTeamsGrid extends ConsumerWidget {
  const RegisteredTeamsGrid({
    super.key,
    required this.tournamentId,
    this.accentColor = AppColors.primary,
    this.physics,
    this.shrinkWrap = false,
  });

  final String tournamentId;
  final Color accentColor;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registeredTeamsAsync = ref.watch(registeredTeamsProvider(tournamentId));
    final myTeamState = ref.watch(teamProvider(tournamentId));
    final myTeam = myTeamState.team;

    return registeredTeamsAsync.when(
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
                const Icon(
                  Icons.groups_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 12),
                Text(
                  'No teams registered yet',
                  style: AppTextStyles.headingMd,
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first team to register!',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: shrinkWrap,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          itemCount: teams.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Failed to load registered teams: $err',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
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
