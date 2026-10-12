import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for team owners to review the Playing 4 roster and submit for registration/approvals.
class RegisterReviewScreen extends ConsumerStatefulWidget {
  const RegisterReviewScreen({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  @override
  ConsumerState<RegisterReviewScreen> createState() => _RegisterReviewScreenState();
}

class _RegisterReviewScreenState extends ConsumerState<RegisterReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _swapPlayer(
    TournamentTeamModel team,
    TeamMemberModel currentMain,
    TeamMemberModel selectedSub,
  ) async {
    final currentMainIds = team.mainPlayers.map((m) => m.userId).toList();
    final index = currentMainIds.indexOf(currentMain.userId);
    if (index != -1) {
      currentMainIds[index] = selectedSub.userId;
      final ok = await ref
          .read(teamProvider(widget.tournamentId).notifier)
          .updatePlayingRoster(currentMainIds);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Swapped ${currentMain.name} with substitute ${selectedSub.name}.',
            ),
          ),
        );
      }
    }
  }

  void _showSwapBottomSheet(
    TournamentTeamModel team,
    TeamMemberModel currentMain,
  ) {
    final subs = team.substitutes;
    if (subs.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Swap ${currentMain.name}', style: AppTextStyles.headingLg),
              const SizedBox(height: 6),
              Text(
                'Select a substitute to replace this main playing player:',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              for (final sub in subs)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceMuted,
                    backgroundImage:
                        sub.avatarUrl.isNotEmpty ? NetworkImage(sub.avatarUrl) : null,
                    child: sub.avatarUrl.isEmpty
                        ? const Icon(Icons.person_rounded, color: AppColors.textMuted)
                        : null,
                  ),
                  title: Text(sub.name, style: AppTextStyles.bodyLg),
                  subtitle: Text(
                    sub.ign.isNotEmpty ? sub.ign : 'Substitute',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.swap_horiz_rounded,
                    color: AppColors.primaryNeon,
                  ),
                  onTap: () async {
                    Navigator.pop(c);
                    await _swapPlayer(team, currentMain, sub);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRegistration(
    TournamentTeamModel team,
    TournamentModel? tournament,
  ) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final mode = tournament?.mode ?? 'SQUAD';
    final ok = await ref
        .read(teamProvider(widget.tournamentId).notifier)
        .completeRegistration(mode: mode);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (ok) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider(widget.tournamentId));
    final team = teamState.team;
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));

    if (team == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final mains = team.mainPlayers;
    final subs = team.substitutes;
    final isManagerOwned = team.isManagerOwned;
    final responsibleName = isManagerOwned ? team.ownerName : team.captainName;
    final responsibleRole = isManagerOwned ? 'MANAGER' : 'LEADER';

    // Calculate approvers
    final bool requireApprovals =
        team.registration?.requirePlayerApproval ?? true;

    final approverNames = <String>[];
    if (requireApprovals) {
      if (isManagerOwned) {
        // Manager owner -> all playing players approve
        approverNames.addAll(mains.map((m) => m.name));
      } else {
        // Leader owner -> all playing players except Leader approve
        approverNames.addAll(
          mains.where((m) => m.userId != team.captainId).map((m) => m.name),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('REVIEW REGISTRATION', style: AppTextStyles.headingLg),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: CustomButton(
            text: requireApprovals ? 'SEND FOR APPROVAL' : 'REGISTER NOW',
            isLoading: _isSubmitting || teamState.isLoading,
            onPressed: (_isSubmitting || teamState.isLoading)
                ? null
                : () => _submitRegistration(team, tournament),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Tournament & Team Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (tournament?.displayTitle ?? team.tournamentName).toUpperCase(),
                  style: AppTextStyles.headingLg.copyWith(color: AppColors.primaryNeon),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.surfaceMuted,
                      backgroundImage:
                          team.logoUrl.isNotEmpty ? NetworkImage(team.logoUrl) : null,
                      child: team.logoUrl.isEmpty
                          ? const Icon(Icons.groups_rounded, size: 18, color: AppColors.textMuted)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        team.tag.isEmpty
                            ? team.name.toUpperCase()
                            : '[${team.tag}] ${team.name.toUpperCase()}',
                        style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Responsible Person Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.primaryNeon,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESPONSIBLE PERSON',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryNeon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$responsibleName ($responsibleRole)',
                        style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Playing 4 Roster Section
          Row(
            children: [
              Text('PLAYING ROSTER', style: AppTextStyles.headingMd),
              const Spacer(),
              Text(
                '${mains.length}/${team.maxMainPlayers}',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.primaryLight),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < mains.length; i++) ...[
            _PlayingPlayerTile(
              slotLabel: 'P${i + 1}',
              player: mains[i],
              isLeader: mains[i].isCaptain || mains[i].userId == team.captainId,
              isManagerOwned: isManagerOwned,
              hasSubstitutes: subs.isNotEmpty,
              onSwap: () => _showSwapBottomSheet(team, mains[i]),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),

          // Substitutes Section (If any)
          if (subs.isNotEmpty) ...[
            Text('SUBSTITUTES (${subs.length})', style: AppTextStyles.headingMd),
            const SizedBox(height: 8),
            for (final sub in subs)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded,
                        color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${sub.name} (${sub.ign.isNotEmpty ? sub.ign : "SUB"})',
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'SUB',
                        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
          ],

          // Approval Notification Info Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'APPROVAL REQUIREMENTS',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!requireApprovals) ...[
                  Text(
                    'Your team will be registered immediately upon clicking register.',
                    style: AppTextStyles.bodySm,
                  ),
                ] else ...[
                  Text(
                    team.isDuoMode
                        ? 'Your partner will receive an approval request:'
                        : 'Participation approval requests will be sent to:',
                    style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  for (final name in approverNames)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mark_email_unread_rounded,
                            size: 14,
                            color: AppColors.accentOrange,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              name,
                              style: AppTextStyles.bodySm,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayingPlayerTile extends StatelessWidget {
  const _PlayingPlayerTile({
    required this.slotLabel,
    required this.player,
    required this.isLeader,
    required this.isManagerOwned,
    required this.hasSubstitutes,
    required this.onSwap,
  });

  final String slotLabel;
  final TeamMemberModel player;
  final bool isLeader;
  final bool isManagerOwned;
  final bool hasSubstitutes;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    // Rule: Leader must play and cannot be swapped out if leader-owned
    final bool canSwap = hasSubstitutes && (!isLeader || isManagerOwned);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Text(
              slotLabel,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage:
                player.avatarUrl.isNotEmpty ? NetworkImage(player.avatarUrl) : null,
            child: player.avatarUrl.isEmpty
                ? const Icon(Icons.person_rounded, size: 20, color: AppColors.textMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryNeon.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.primaryNeon),
                        ),
                        child: Text(
                          'LEADER',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryNeon,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (player.ign.isNotEmpty)
                  Text(
                    'IGN: ${player.ign}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (canSwap)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primaryNeon),
              tooltip: 'Swap with substitute',
              onPressed: onSwap,
            )
          else if (isLeader && !isManagerOwned && hasSubstitutes)
            Tooltip(
              message: 'Leader must play',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.lock_rounded,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
