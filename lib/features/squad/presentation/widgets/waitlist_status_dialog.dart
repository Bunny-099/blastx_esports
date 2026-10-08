import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../live/data/models/team_member_model.dart';
import '../../../live/data/models/tournament_model.dart';
import '../../../live/providers/live_provider.dart';
import '../../../live/providers/team_provider.dart';
import '../../data/models/squad_model.dart';
import '../../providers/squad_provider.dart';

/// Shows the detailed Waitlist Status modal for squad tournaments.
void showWaitlistModal(BuildContext context, WidgetRef ref, SquadModel squad) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _WaitlistContent(squad: squad),
  );
}

class _WaitlistContent extends ConsumerStatefulWidget {
  const _WaitlistContent({required this.squad});
  final SquadModel squad;

  @override
  ConsumerState<_WaitlistContent> createState() => _WaitlistContentState();
}

class _WaitlistContentState extends ConsumerState<_WaitlistContent> {
  int _selectedTournamentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tournaments = ref.watch(appTournamentsProvider);
    final squadState = ref.watch(squadProvider);
    final viewerUserId = squadState.viewerUserId;

    if (tournaments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('WAITLIST STATUS', style: AppTextStyles.headingXl),
            const SizedBox(height: 12),
            Text(
              'No active tournaments joined by your squad yet.',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final safeIndex = _selectedTournamentIndex.clamp(0, tournaments.length - 1);
    final selectedTournament = tournaments[safeIndex];

    final teamState = ref.watch(teamProvider(selectedTournament.id));
    final team = teamState.team;

    // Use team members or fall back to squad main members
    final mainMembers = team?.mainPlayers ??
        widget.squad.mainPlayers
            .map(
              (m) => TeamMemberModel(
                userId: m.userId,
                name: m.name,
                ign: m.ign,
                uid: m.uid,
                role: m.isLeader ? TeamRole.captain : (m.isManager ? TeamRole.manager : TeamRole.member),
                rosterType: RosterType.main,
                status: m.userId == widget.squad.leaderId
                    ? TeamMemberStatus.confirmed
                    : TeamMemberStatus.pending,
              ),
            )
            .toList();

    final confirmedCount = mainMembers.where((m) => m.isConfirmed).length;
    final pendingCount = mainMembers.where((m) => m.isPending).length;
    final neededCount = (4 - confirmedCount).clamp(0, 4);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Icon(Icons.hourglass_empty_rounded, color: AppColors.accentOrange, size: 22),
                const SizedBox(width: 8),
                Text('TOURNAMENT WAITLIST', style: AppTextStyles.headingXl),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Select a tournament to view your team\'s member request acceptance status:',
              style: AppTextStyles.bodySm,
            ),
            const SizedBox(height: 14),

            // Tournament Selector Tabs if multiple tournaments
            if (tournaments.length > 1) ...[
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: tournaments.length,
                  itemBuilder: (ctx, i) {
                    final t = tournaments[i];
                    final isSelected = i == safeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTournamentIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryNeon : AppColors.surfaceNavy,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryNeon : AppColors.borderSubtle,
                          ),
                        ),
                        child: Text(
                          t.name,
                          style: GoogleFonts.rajdhani(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.bgNavy : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Active Summary Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: neededCount > 0
                    ? AppColors.accentOrange.withValues(alpha: 0.12)
                    : AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: neededCount > 0
                      ? AppColors.accentOrange.withValues(alpha: 0.5)
                      : AppColors.success.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    neededCount > 0 ? Icons.hourglass_top_rounded : Icons.verified_rounded,
                    color: neededCount > 0 ? AppColors.accentOrange : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      neededCount > 0
                          ? 'Waiting for $neededCount more main player${neededCount == 1 ? '' : 's'} to accept the request.'
                          : 'All 4 main players accepted! Squad waitlist registration complete ✓',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: neededCount > 0 ? AppColors.accentOrange : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text('PLAYER ACCEPTANCE STATUS', style: AppTextStyles.headingMd),
            const SizedBox(height: 10),

            // Roster Members Acceptance List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 4,
                itemBuilder: (ctx, index) {
                  final member = index < mainMembers.length ? mainMembers[index] : null;

                  if (member == null) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceNavy.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Slot ${index + 1}: Empty Slot', style: AppTextStyles.bodySm),
                    );
                  }

                  final isConfirmed = member.isConfirmed;
                  final isMePending = member.isPending && member.userId == viewerUserId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isConfirmed
                            ? AppColors.primaryNeon.withValues(alpha: 0.4)
                            : AppColors.accentOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surfaceElevated,
                          child: Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : 'P',
                            style: GoogleFonts.rajdhani(
                              fontWeight: FontWeight.bold,
                              color: isConfirmed ? AppColors.primaryNeon : AppColors.accentOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: GoogleFonts.rajdhani(
                                  fontSize: 15,
                                  fontWeight: isConfirmed ? FontWeight.w900 : FontWeight.w500,
                                  color: isConfirmed ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isConfirmed
                                    ? '✓ Accepted & Confirmed'
                                    : 'Waiting from this player to accept the request',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: isConfirmed ? FontWeight.bold : FontWeight.w500,
                                  color: isConfirmed ? AppColors.success : AppColors.accentOrange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isConfirmed) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'ACCEPTED',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isMePending) ...[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNeon,
                              foregroundColor: AppColors.bgNavy,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              // Accept request for viewer
                              final updatedMembers = mainMembers.map((m) {
                                if (m.userId == viewerUserId) {
                                  return m.copyWith(status: TeamMemberStatus.confirmed);
                                }
                                return m;
                              }).toList();

                              if (team != null) {
                                ref.read(teamProvider(selectedTournament.id).notifier).refresh();
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request accepted! Status updated to bold ✓'),
                                  backgroundColor: AppColors.primaryNeon,
                                ),
                              );
                              setState(() {});
                            },
                            child: Text(
                              'ACCEPT',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.bgNavy,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
