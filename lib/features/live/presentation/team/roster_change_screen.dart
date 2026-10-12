import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';

/// Screen for team owner to request a post-confirmation roster change.
class RosterChangeScreen extends ConsumerStatefulWidget {
  const RosterChangeScreen({
    super.key,
    required this.tournamentId,
  });

  final String tournamentId;

  @override
  ConsumerState<RosterChangeScreen> createState() => _RosterChangeScreenState();
}

class _RosterChangeScreenState extends ConsumerState<RosterChangeScreen> {
  final Set<String> _selectedMainUserIds = {};
  final Set<String> _removeUserIds = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final team = ref.read(teamProvider(widget.tournamentId)).team;
    if (team != null) {
      for (final m in team.mainPlayers) {
        _selectedMainUserIds.add(m.userId);
      }
    }
  }

  void _togglePlayer(TeamMemberModel m, TournamentTeamModel team) {
    // Leader must stay in playing set if leader-owned
    if (m.isCaptain && !team.isManagerOwned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The team leader must be in the playing roster.')),
      );
      return;
    }
    // Manager cannot be in playing roster
    if (m.isManager) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manager cannot be in the playing roster.')),
      );
      return;
    }

    setState(() {
      if (_selectedMainUserIds.contains(m.userId)) {
        if (_selectedMainUserIds.length <= 1) return;
        _selectedMainUserIds.remove(m.userId);
      } else {
        if (_selectedMainUserIds.length >= team.maxMainPlayers) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum ${team.maxMainPlayers} playing members allowed.',
              ),
            ),
          );
          return;
        }
        _selectedMainUserIds.add(m.userId);
        _removeUserIds.remove(m.userId);
      }
    });
  }

  void _toggleRemoval(TeamMemberModel m) {
    if (_selectedMainUserIds.contains(m.userId)) return;
    setState(() {
      if (_removeUserIds.contains(m.userId)) {
        _removeUserIds.remove(m.userId);
      } else {
        _removeUserIds.add(m.userId);
      }
    });
  }

  Future<void> _submit(TournamentTeamModel team) async {
    if (_selectedMainUserIds.length != team.maxMainPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select exactly ${team.maxMainPlayers} playing members.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final ok = await ref.read(teamProvider(widget.tournamentId).notifier).requestRosterChange(
          mainUserIds: _selectedMainUserIds.toList(),
          removeUserIds: _removeUserIds.isNotEmpty ? _removeUserIds.toList() : null,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Roster change request submitted!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider(widget.tournamentId));
    final team = teamState.team;

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

    final allMembers = team.members.where((m) => !m.isManager).toList();
    final nonSelectedMembers = allMembers.where((m) => !_selectedMainUserIds.contains(m.userId)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('CHANGE PLAYING ROSTER', style: AppTextStyles.headingLg),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: CustomButton(
            text: 'SEND FOR APPROVAL',
            isLoading: _isSubmitting || teamState.isLoading,
            onPressed: (_isSubmitting || teamState.isLoading)
                ? null
                : () => _submit(team),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.accentOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your slot and room access stay the same until the new player approves.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Playing Roster Selection
          Row(
            children: [
              Text('SELECT PLAYING MEMBERS', style: AppTextStyles.headingMd),
              const Spacer(),
              Text(
                '${_selectedMainUserIds.length}/${team.maxMainPlayers}',
                style: AppTextStyles.headingMd.copyWith(
                  color: _selectedMainUserIds.length == team.maxMainPlayers
                      ? AppColors.primaryNeon
                      : AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          for (final m in allMembers) ...[
            _MemberSelectTile(
              member: m,
              isSelected: _selectedMainUserIds.contains(m.userId),
              isLeader: m.isCaptain && !team.isManagerOwned,
              onTap: () => _togglePlayer(m, team),
            ),
            const SizedBox(height: 8),
          ],

          if (nonSelectedMembers.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('REMOVE UNSELECTED MEMBERS? (OPTIONAL)', style: AppTextStyles.headingMd),
            const SizedBox(height: 4),
            Text(
              'Select members to remove from team entirely when change is approved:',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),

            for (final m in nonSelectedMembers) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.error,
                title: Text(m.name, style: AppTextStyles.bodyMd),
                subtitle: Text(
                  m.ign.isNotEmpty ? 'IGN: ${m.ign}' : 'Member',
                  style: AppTextStyles.caption,
                ),
                value: _removeUserIds.contains(m.userId),
                onChanged: (_) => _toggleRemoval(m),
              ),
            ],
          ],

          if (teamState.error != null) ...[
            const SizedBox(height: 16),
            Text(
              teamState.error!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberSelectTile extends StatelessWidget {
  const _MemberSelectTile({
    required this.member,
    required this.isSelected,
    required this.isLeader,
    required this.onTap,
  });

  final TeamMemberModel member;
  final bool isSelected;
  final bool isLeader;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryNeon.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNeon : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceMuted,
              backgroundImage: member.avatarUrl.isNotEmpty
                  ? NetworkImage(member.avatarUrl)
                  : null,
              child: member.avatarUrl.isEmpty
                  ? const Icon(Icons.person_rounded,
                      size: 20, color: AppColors.textMuted)
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
                          member.name,
                          style: AppTextStyles.bodyLg
                              .copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLeader) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNeon.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
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
                  if (member.ign.isNotEmpty)
                    Text(
                      'IGN: ${member.ign}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primaryNeon : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
