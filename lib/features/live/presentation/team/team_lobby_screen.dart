import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/presentation/team/tournament_match_room_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/team_code_card.dart';
import 'package:blastix_esports/features/live/presentation/widgets/team_member_card.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main team-management screen.
class TeamLobbyScreen extends ConsumerWidget {
  const TeamLobbyScreen({super.key, required this.tournamentId});
  final String tournamentId;

  Future<bool> _confirm(
      BuildContext context, String title, String body, String action) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.headingLg),
        content: Text(body, style: AppTextStyles.bodyMd),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true), child: Text(action)),
        ],
      ),
    );
    return r == true;
  }

  Future<void> _changeOwner(
      BuildContext context, WidgetRef ref, TournamentTeamModel team) async {
    final isManager = team.isManagerOwned;
    final others = team.members.where((m) => !(m.isCaptain || m.isManager)).toList();

    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other members available in team.')),
      );
      return;
    }

    final picked = await showModalBottomSheet<TeamMemberModel>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isManager ? 'Select new Manager' : 'Select new Captain',
                style: AppTextStyles.headingLg,
              ),
            ),
            ...others.map((m) => ListTile(
                  leading: const Icon(Icons.person_rounded,
                      color: AppColors.textSecondary),
                  title: Text(m.name, style: AppTextStyles.bodyLg),
                  subtitle: Text(m.ign, style: AppTextStyles.caption),
                  onTap: () => Navigator.pop(c, m),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    final ok = await _confirm(
        context,
        isManager ? 'Transfer Management?' : 'Change Captain?',
        '${picked.name} will become the new ${isManager ? "Manager" : "Captain"}.',
        'Confirm');
    if (ok) {
      await ref
          .read(teamProvider(tournamentId).notifier)
          .transferCaptain(picked.userId);
    }
  }

  Future<void> _leave(
      BuildContext context, WidgetRef ref, TournamentTeamModel team) async {
    if (team.viewerIsOwner) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            team.isManagerOwned ? 'Transfer management first' : 'Transfer captaincy first',
            style: AppTextStyles.headingLg,
          ),
          content: Text(
            team.isManagerOwned
                ? 'The manager cannot leave without transferring management. Use "Transfer Management" first.'
                : 'The captain cannot leave without transferring captaincy. Use "Change Captain" first.',
            style: AppTextStyles.bodyMd,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
      return;
    }
    final ok = await _confirm(context, 'Leave team?',
        'You will be removed from ${team.name}.', 'Leave');
    if (!ok) return;
    final left = await ref.read(teamProvider(tournamentId).notifier).leaveTeam();
    if (left && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<TeamState>(teamProvider(tournamentId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    final s = ref.watch(teamProvider(tournamentId));
    final team = s.team;
    final notifier = ref.read(teamProvider(tournamentId).notifier);
    final tournament = ref.watch(tournamentByIdProvider(tournamentId));

    if (team == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
          child: s.isLoading
              ? const CircularProgressIndicator(color: AppColors.primary)
              : Text('No team found', style: AppTextStyles.bodyMd),
        ),
      );
    }

    final isOwner = team.viewerIsOwner;
    final canEdit = !team.isLocked && !team.isRegistered;
    final mains = team.mainPlayers;
    final subs = team.substitutes;
    final manager = team.manager;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('TEAM LOBBY', style: AppTextStyles.headingLg),
      ),
      bottomNavigationBar: _buildStickyBottomBar(
        context: context,
        ref: ref,
        team: team,
        tournament: tournament,
        isLoading: s.isLoading,
        isOwner: isOwner,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
          children: [
            _header(team),
            const SizedBox(height: 14),
            _statusBanner(team, tournament),
            const SizedBox(height: 14),
            TeamCodeCard(code: team.code, shareText: team.shareText),
            const SizedBox(height: 20),

            // Manager Section (If Manager-created team)
            if (team.isManagerOwned && manager != null) ...[
              Row(
                children: [
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: AppColors.primaryNeon, size: 20),
                  const SizedBox(width: 8),
                  Text('MANAGED BY', style: AppTextStyles.headingMd),
                ],
              ),
              const SizedBox(height: 6),
              TeamMemberCard(
                slotLabel: 'MGR',
                member: manager,
                isMe: manager.userId == team.viewerUserId,
              ),
              const SizedBox(height: 16),
            ],

            // Main Playing Members Section
            Row(
              children: [
                Text('MAIN PLAYERS', style: AppTextStyles.headingMd),
                const Spacer(),
                Text('${team.confirmedMainCount}/${team.maxMainPlayers}',
                    style: AppTextStyles.headingMd
                        .copyWith(color: AppColors.primaryLight)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: team.confirmedMainCount / team.maxMainPlayers,
                minHeight: 6,
                backgroundColor: AppColors.surfaceMuted,
                color: team.isReady ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < team.maxMainPlayers; i++)
              TeamMemberCard(
                slotLabel: '${i + 1}',
                member: i < mains.length ? mains[i] : null,
                isMe: i < mains.length && mains[i].userId == team.viewerUserId,
                onRemove: i < mains.length &&
                        isOwner &&
                        canEdit &&
                        !mains[i].isCaptain &&
                        !mains[i].isManager
                    ? () async {
                        if (await _confirm(
                            context,
                            'Remove player?',
                            '${mains[i].name} will be removed from the team.',
                            'Remove')) {
                          notifier.removeMember(mains[i].userId);
                        }
                      }
                    : null,
              ),
            const SizedBox(height: 12),

            // Substitute Members Section
            Row(
              children: [
                Text('SUBSTITUTES', style: AppTextStyles.headingMd),
                const Spacer(),
                Text('${team.substituteCount}/${team.maxSubstitutes}',
                    style: AppTextStyles.headingMd
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Optional • up to ${team.maxSubstitutes}',
                style: AppTextStyles.bodySm),
            const SizedBox(height: 10),
            if (isOwner && canEdit && team.isMainFull)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primaryNeon,
                title: Text('Accept substitutes', style: AppTextStyles.bodyLg),
                subtitle: Text(
                    'Players joining with your code become substitutes.',
                    style: AppTextStyles.bodySm),
                value: team.acceptingSubstitutes,
                onChanged: s.isLoading
                    ? null
                    : (v) => notifier.setAcceptingSubstitutes(v),
              ),
            for (var i = 0; i < team.maxSubstitutes; i++)
              TeamMemberCard(
                slotLabel: 'S${i + 1}',
                member: i < subs.length ? subs[i] : null,
                isMe: i < subs.length && subs[i].userId == team.viewerUserId,
                onRemove: i < subs.length && isOwner && canEdit
                    ? () async {
                        if (await _confirm(
                            context,
                            'Remove substitute?',
                            '${subs[i].name} will be removed from the team.',
                            'Remove')) {
                          notifier.removeMember(subs[i].userId);
                        }
                      }
                    : null,
              ),
            const SizedBox(height: 16),

            // Ownership / Captain Transfer Action
            if (isOwner && canEdit && team.members.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomButton(
                  text: team.isManagerOwned ? 'TRANSFER MANAGEMENT' : 'CHANGE CAPTAIN',
                  isOutlined: true,
                  icon: const Icon(Icons.swap_horiz_rounded,
                      size: 18, color: Colors.white),
                  onPressed: () => _changeOwner(context, ref, team),
                ),
              ),
            if (canEdit) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed:
                    s.isLoading ? null : () => _leave(context, ref, team),
                child: Text('LEAVE TEAM',
                    style:
                        AppTextStyles.button.copyWith(color: AppColors.error)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ── Sticky Floating Bottom Section ──
  Widget _buildStickyBottomBar({
    required BuildContext context,
    required WidgetRef ref,
    required TournamentTeamModel team,
    required TournamentModel? tournament,
    required bool isLoading,
    required bool isOwner,
  }) {
    final confirmedCount = team.confirmedMainCount;
    final slotsNeeded = 4 - confirmedCount;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Registered -> Go to Match Room Button
            if (team.isRegistered) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primaryNeon,
                  foregroundColor: AppColors.bgNavy,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    FirePageRoute(
                      page: TournamentMatchRoomScreen(
                          tournamentId: tournamentId),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded,
                        color: AppColors.bgNavy, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'REGISTERED • VIEW MATCH LOBBY & ROOM',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.bgNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // 2. Not Registered: Fewer than 4 confirmed main playing members -> Floating Waiting Banner
            else if (confirmedCount < 4) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentOrange.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: AppColors.accentOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting for $slotsNeeded player${slotsNeeded == 1 ? '' : 's'} to register',
                            style: AppTextStyles.headingMd.copyWith(
                              color: AppColors.accentOrange,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '4 main playing members are compulsory to register for tournament',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]
            // 3. Not Registered: Exactly 4 playing members confirmed -> Floating Register Button
            else ...[
              CustomButton(
                text: tournament == null
                    ? 'REGISTER TOURNAMENT'
                    : 'REGISTER TOURNAMENT • ${tournament.formattedEntryFee}',
                isLoading: isLoading,
                onPressed: (tournament != null &&
                        tournament.status != TournamentStatus.live)
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Registration status LIVE hone par hi shuru hoti hai.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    : () async {
                        final mode = tournament?.mode ?? 'SQUAD';
                        final ok = await ref
                            .read(teamProvider(tournamentId).notifier)
                            .completeRegistration(mode: mode);

                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🎉 Registration successful! Your squad is registered for tournament.',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );

                          // Open Match Room & Registered Teams Screen
                          Navigator.of(context).pushReplacement(
                            FirePageRoute(
                              page: TournamentMatchRoomScreen(
                                tournamentId: tournamentId,
                              ),
                            ),
                          );
                        }
                      },
              ),
              if (!isOwner) ...[
                const SizedBox(height: 6),
                Text(
                  'Waiting for the team leader/manager to click Register.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(TournamentTeamModel team) => Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.surfaceMuted,
            backgroundImage:
                team.logoUrl.isNotEmpty ? NetworkImage(team.logoUrl) : null,
            child: team.logoUrl.isEmpty
                ? const Icon(Icons.groups_rounded,
                    color: AppColors.textMuted, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    team.tag.isEmpty
                        ? team.name.toUpperCase()
                        : '[${team.tag}] ${team.name.toUpperCase()}',
                    style: AppTextStyles.headingXl),
                Text(
                  team.isManagerOwned
                      ? 'Manager: ${team.ownerName}'
                      : 'Captain: ${team.captainName}',
                  style: AppTextStyles.bodyMd,
                ),
                if (team.tournamentName.isNotEmpty)
                  Text(team.tournamentName, style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      );

  Widget _statusBanner(
      TournamentTeamModel team, TournamentModel? tournament) {
    late final Color color;
    late final IconData icon;
    late final String text;
    if (team.isRegistered) {
      color = AppColors.success;
      icon = Icons.verified_rounded;
      text = 'Registered. Roster is locked.';
    } else if (team.isLocked) {
      color = AppColors.error;
      icon = Icons.lock_rounded;
      text = 'Registration closed. The roster can no longer be changed.';
    } else if (tournament != null &&
        tournament.status == TournamentStatus.upcoming) {
      color = AppColors.warning;
      icon = Icons.schedule_rounded;
      text = 'Registration opens when tournament goes LIVE on backend.';
    } else if (team.isReady) {
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
      text = 'Team is ready! 4/4 main playing members confirmed.';
    } else {
      color = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
      text =
          'Waiting for ${team.mainSlotsLeft} more main player${team.mainSlotsLeft == 1 ? '' : 's'}.';
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMd)),
        ],
      ),
    );
  }
}
