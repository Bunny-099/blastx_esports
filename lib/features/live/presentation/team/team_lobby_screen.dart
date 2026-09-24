import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
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

  Future<void> _changeCaptain(
      BuildContext context, WidgetRef ref, TournamentTeamModel team) async {
    final others = team.members.where((m) => !m.isCaptain).toList();
    final picked = await showModalBottomSheet<TeamMemberModel>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Select new captain', style: AppTextStyles.headingLg),
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
        'Change captain?',
        '${picked.name} will become captain and you will become a normal member.',
        'Confirm');
    if (ok) {
      await ref
          .read(teamProvider(tournamentId).notifier)
          .transferCaptain(picked.userId);
    }
  }

  Future<void> _leave(
      BuildContext context, WidgetRef ref, TournamentTeamModel team) async {
    if (team.viewerIsCaptain) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Transfer captaincy first', style: AppTextStyles.headingLg),
          content: Text(
              'The captain cannot leave the team. Use "Change Captain" first, then you can leave.',
              style: AppTextStyles.bodyMd),
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

    final isCaptain = team.viewerIsCaptain;
    final canEdit = !team.isLocked && !team.isRegistered;
    final mains = team.mainPlayers;
    final subs = team.substitutes;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('TEAM LOBBY', style: AppTextStyles.headingLg),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: notifier.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _header(team),
            const SizedBox(height: 14),
            _statusBanner(team),
            const SizedBox(height: 14),
            TeamCodeCard(code: team.code, shareText: team.shareText),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('MAIN PLAYERS', style: AppTextStyles.headingMd),
                const Spacer(),
                Text('${team.mainCount}/${team.maxMainPlayers}',
                    style: AppTextStyles.headingMd
                        .copyWith(color: AppColors.primaryLight)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: team.mainCount / team.maxMainPlayers,
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
                    isCaptain &&
                    canEdit &&
                    !mains[i].isCaptain
                    ? () async {
                  if (await _confirm(context, 'Remove player?',
                      '${mains[i].name} will be removed from the team.',
                      'Remove')) {
                    notifier.removeMember(mains[i].userId);
                  }
                }
                    : null,
              ),
            const SizedBox(height: 12),
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
            if (isCaptain && canEdit && team.isMainFull)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primaryNeon,
                title: Text('Accept substitutes', style: AppTextStyles.bodyLg),
                subtitle: Text('Players joining with your code become substitutes.',
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
                onRemove: i < subs.length && isCaptain && canEdit
                    ? () async {
                  if (await _confirm(context, 'Remove substitute?',
                      '${subs[i].name} will be removed from the team.',
                      'Remove')) {
                    notifier.removeMember(subs[i].userId);
                  }
                }
                    : null,
              ),
            const SizedBox(height: 16),
            if (isCaptain && canEdit && team.members.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CustomButton(
                  text: 'CHANGE CAPTAIN',
                  isOutlined: true,
                  icon: const Icon(Icons.swap_horiz_rounded,
                      size: 18, color: Colors.white),
                  onPressed: () => _changeCaptain(context, ref, team),
                ),
              ),
            if (isCaptain && canEdit && team.isReady)
              CustomButton(
                text: tournament == null
                    ? 'COMPLETE REGISTRATION'
                    : 'COMPLETE REGISTRATION • ${tournament.formattedEntryFee}',
                isLoading: s.isLoading,
                onPressed: () async {
                  final ok = await notifier.completeRegistration();
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            '🎉 Registration successful! Your roster is registered.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              ),
            if (!isCaptain && canEdit && team.isReady)
              Text('Waiting for the captain to complete registration.',
                  textAlign: TextAlign.center, style: AppTextStyles.bodySm),
            if (canEdit) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: s.isLoading ? null : () => _leave(context, ref, team),
                child: Text('LEAVE TEAM',
                    style: AppTextStyles.button.copyWith(color: AppColors.error)),
              ),
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
            Text('Captain: ${team.captainName}', style: AppTextStyles.bodyMd),
            if (team.tournamentName.isNotEmpty)
              Text(team.tournamentName, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    ],
  );

  Widget _statusBanner(TournamentTeamModel team) {
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
    } else if (team.isReady) {
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
      text = 'Team is ready! 4/4 main players.';
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