import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/presentation/widgets/player_info_form.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows the team found by code. The player adds their Free Fire
/// details and joins directly (no captain approval).
class TeamPreviewScreen extends ConsumerStatefulWidget {
  const TeamPreviewScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<TeamPreviewScreen> createState() => _TeamPreviewScreenState();
}

class _TeamPreviewScreenState extends ConsumerState<TeamPreviewScreen> {
  final _player = TextEditingController();
  final _ign = TextEditingController();
  final _uid = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    for (final c in [_player, _ign, _uid]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _join() async {
    final err = PlayerInfoForm.validate(_player.text, _ign.text, _uid.text);
    setState(() => _localError = err);
    if (err != null) return;
    final ok = await ref.read(teamProvider(widget.tournamentId).notifier).joinTeam(
      playerName: _player.text.trim(),
      ign: _ign.text.trim(),
      uid: _uid.text.trim(),
    );
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(teamProvider(widget.tournamentId));
    final team = s.previewTeam;

    if (team == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(child: Text('Team not found', style: AppTextStyles.bodyMd)),
      );
    }

    String? blocked;
    if (team.isLocked) {
      blocked = 'Registration for this tournament has ended.';
    } else if (team.isMainFull && !team.canJoinAsSubstitute) {
      blocked = 'This team is full.';
    }
    final asSub = team.isMainFull && team.canJoinAsSubstitute;
    final error = _localError ?? s.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(team),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PLAYERS', style: AppTextStyles.overline),
                  const SizedBox(height: 8),
                  ...team.members.map((m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                            m.isCaptain
                                ? Icons.workspace_premium_rounded
                                : Icons.person_rounded,
                            size: 18,
                            color: m.isCaptain
                                ? AppColors.gold
                                : AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(m.name, style: AppTextStyles.bodyLg),
                        if (m.isSubstitute)
                          Text('  (SUB)', style: AppTextStyles.caption),
                      ],
                    ),
                  )),
                  const Divider(color: AppColors.border, height: 24),
                  Text('${team.mainCount} / ${team.maxMainPlayers} Main Players',
                      style: AppTextStyles.headingMd
                          .copyWith(color: AppColors.primaryLight)),
                  const SizedBox(height: 2),
                  Text(
                      team.isMainFull
                          ? 'Main roster full • ${team.maxSubstitutes - team.substituteCount} substitute slot(s) left'
                          : '${team.mainSlotsLeft} slot(s) available',
                      style: AppTextStyles.bodySm),
                ],
              ),
            ),
            if (blocked != null) ...[
              const SizedBox(height: 18),
              Text(blocked,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.error)),
            ] else ...[
              const SizedBox(height: 22),
              Text('YOUR FREE FIRE DETAILS', style: AppTextStyles.headingMd),
              PlayerInfoForm(
                  nameController: _player,
                  ignController: _ign,
                  uidController: _uid),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error,
                    style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 22),
              CustomButton(
                text: asSub ? 'JOIN AS SUBSTITUTE' : 'JOIN TEAM',
                isLoading: s.isLoading,
                onPressed: _join,
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
            Text(team.name.toUpperCase(), style: AppTextStyles.display),
            Text('Captain: ${team.captainName}', style: AppTextStyles.bodyMd),
            if (team.tournamentName.isNotEmpty)
              Text(team.tournamentName, style: AppTextStyles.bodySm),
          ],
        ),
      ),
    ],
  );
}