import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/presentation/team/player_approval_screen.dart';
import 'package:blastix_esports/features/live/presentation/team/register_review_screen.dart';
import 'package:blastix_esports/features/live/presentation/team/roster_change_screen.dart';
import 'package:blastix_esports/features/live/presentation/tournament_detail_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/registration_status_stepper.dart';
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
    final others =
        team.members.where((m) => !(m.isCaptain || m.isManager)).toList();

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
            team.isManagerOwned
                ? 'Transfer management first'
                : 'Transfer captaincy first',
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

    final viewerMember = team.members.firstWhere(
      (m) => m.userId == team.viewerUserId,
      orElse: () => const TeamMemberModel(userId: '', name: ''),
    );
    if ((team.isRegistered || team.registrationState == TeamRegistrationState.confirmed) &&
        !viewerMember.isSubstitute &&
        viewerMember.userId.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Playing Members Cannot Leave', style: AppTextStyles.headingLg),
          content: Text(
            'Playing members of a confirmed team cannot leave directly. Please ask the team owner to replace or remove you.',
            style: AppTextStyles.bodyMd,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final ok = await _confirm(context, 'Leave team?',
        'You will be removed from ${team.name}.', 'Leave');
    if (!ok) return;
    final left =
        await ref.read(teamProvider(tournamentId).notifier).leaveTeam();
    if (left && context.mounted) Navigator.of(context).pop();
  }

  void _showMemberActionsSheet(
    BuildContext context,
    WidgetRef ref,
    TournamentTeamModel team,
    TeamMemberModel member,
  ) {
    final isMain = !member.isSubstitute;
    final notifier = ref.read(teamProvider(tournamentId).notifier);

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
              Text('Manage ${member.name}', style: AppTextStyles.headingLg),
              const SizedBox(height: 4),
              Text(
                'Note: Changing the roster cancels pending approvals.',
                style: AppTextStyles.caption.copyWith(color: AppColors.accentOrange),
              ),
              const SizedBox(height: 16),
              if (isMain && team.substitutes.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded, color: AppColors.primaryNeon),
                  title: Text('Make substitute', style: AppTextStyles.bodyLg),
                  onTap: () async {
                    Navigator.pop(c);
                    final subToPromote = team.substitutes.first;
                    final newMains = team.mainPlayers
                        .map((m) => m.userId == member.userId ? subToPromote.userId : m.userId)
                        .toList();
                    await notifier.updatePlayingRoster(newMains);
                  },
                )
              else if (!isMain)
                ListTile(
                  leading: const Icon(Icons.swap_vert_rounded, color: AppColors.primaryNeon),
                  title: Text('Make main playing player', style: AppTextStyles.bodyLg),
                  onTap: () async {
                    Navigator.pop(c);
                    final mains = team.mainPlayers.map((m) => m.userId).toList();
                    if (mains.length >= team.maxMainPlayers) {
                      mains.removeLast();
                    }
                    mains.add(member.userId);
                    await notifier.updatePlayingRoster(mains);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.person_remove_rounded, color: AppColors.error),
                title: Text('Remove from team', style: AppTextStyles.bodyLg.copyWith(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(c);
                  if (await _confirm(
                    context,
                    'Remove player?',
                    '${member.name} will be removed from the team.',
                    'Remove',
                  )) {
                    notifier.removeMember(member.userId);
                  }
                },
              ),
              if (!member.isCaptain && !member.isManager)
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: AppColors.gold),
                  title: Text(team.isManagerOwned ? 'Make Manager' : 'Make Captain', style: AppTextStyles.bodyLg),
                  onTap: () async {
                    Navigator.pop(c);
                    if (await _confirm(
                      context,
                      team.isManagerOwned ? 'Transfer Management?' : 'Change Captain?',
                      '${member.name} will become the new ${team.isManagerOwned ? "Manager" : "Captain"}.',
                      'Confirm',
                    )) {
                      await notifier.transferCaptain(member.userId);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _onNavigateBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _onNavigateBack(context);
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => _onNavigateBack(context),
            ),
          ),
          body: Center(
            child: s.isLoading
                ? const CircularProgressIndicator(color: AppColors.primary)
                : s.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.error, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              s.error!,
                              style: AppTextStyles.bodyMd,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNeon,
                                foregroundColor: AppColors.bgNavy,
                              ),
                              onPressed: () => notifier.refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Text('No team found', style: AppTextStyles.bodyMd),
          ),
        ),
      );
    }

    final isOwner = team.viewerIsOwner;
    final canEdit = !team.isLocked &&
        !team.isRegistered &&
        team.registrationState != TeamRegistrationState.confirmed &&
        team.registrationState != TeamRegistrationState.waitlisted;
    final mains = team.mainPlayers;
    final subs = team.substitutes;
    final manager = team.manager;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onNavigateBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => _onNavigateBack(context),
          ),
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
              RegistrationStatusStepper(team: team, tournament: tournament),
              const SizedBox(height: 14),
              _statusBanner(team, tournament),
              const SizedBox(height: 14),
              TeamCodeCard(code: team.code, shareText: team.shareText),
              const SizedBox(height: 20),

              // Manager Section (If Manager-created team and not Duo mode)
              if (!team.isDuoMode && team.isManagerOwned && manager != null) ...[
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

              // Owner Join Requests Section (If viewer is owner and requests exist)
              _JoinRequestsSection(
                team: team,
                tournamentId: tournamentId,
              ),

              // Pending Roster Change Card (Post-Confirmation)
              if (team.pendingRosterChange != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.hourglass_top_rounded,
                              color: AppColors.accentOrange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'PENDING ROSTER CHANGE',
                            style: AppTextStyles.headingMd.copyWith(
                              color: AppColors.accentOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('New Players Pending Approval:',
                          style: AppTextStyles.bodySm
                              .copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      for (final p
                          in team.pendingRosterChange!.addedPlayers)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Text(p.name, style: AppTextStyles.bodyMd),
                              const Spacer(),
                              _StatusBadge(status: p.approvalStatus),
                            ],
                          ),
                        ),
                      if (team.pendingRosterChange!.expiresAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Expires at: ${_fmtDate(team.pendingRosterChange!.expiresAt!)}',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                      if (isOwner) ...[
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            minimumSize: const Size.fromHeight(40),
                          ),
                          onPressed: s.isLoading
                              ? null
                              : () => notifier.cancelRosterChange(),
                          child: Text('CANCEL ROSTER CHANGE',
                              style: AppTextStyles.button.copyWith(
                                  color: AppColors.error, fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (isOwner &&
                  (team.isRegistered ||
                      team.registrationState ==
                          TeamRegistrationState.confirmed)) ...[
                if (team.canChangeRoster) ...[
                  CustomButton(
                    text: team.isDuoMode
                        ? 'CHANGE DUO ROSTER'
                        : 'CHANGE PLAYING 4',
                    isOutlined: true,
                    icon: const Icon(Icons.edit_rounded,
                        size: 18, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        FirePageRoute(
                          page: RosterChangeScreen(
                              tournamentId: tournamentId),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock_rounded,
                            color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            team.rosterLockAt != null
                                ? 'Roster locked on ${_fmtDate(team.rosterLockAt!)}'
                                : 'Roster changes locked by time limit',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                  isMe:
                      i < mains.length && mains[i].userId == team.viewerUserId,
                  onRemove: i < mains.length &&
                          isOwner &&
                          canEdit &&
                          !mains[i].isCaptain &&
                          !mains[i].isManager
                      ? () =>
                          _showMemberActionsSheet(context, ref, team, mains[i])
                      : null,
                ),
              const SizedBox(height: 12),

              // Substitute Members Section (Skipped for Duo mode)
              if (!team.isDuoMode && team.maxSubstitutes > 0) ...[
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
                    isMe: i < subs.length &&
                        subs[i].userId == team.viewerUserId,
                    onRemove: i < subs.length && isOwner && canEdit
                        ? () => _showMemberActionsSheet(
                            context, ref, team, subs[i])
                        : null,
                  ),
                const SizedBox(height: 16),
              ],

              // Ownership / Captain Transfer Action
              if (isOwner && canEdit && team.members.length > 1 && !team.isDuoMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CustomButton(
                    text: team.isManagerOwned
                        ? 'TRANSFER MANAGEMENT'
                        : 'CHANGE CAPTAIN',
                    isOutlined: true,
                    icon: const Icon(Icons.swap_horiz_rounded,
                        size: 18, color: Colors.white),
                    onPressed: () => _changeOwner(context, ref, team),
                  ),
                ),
              if (!isOwner || canEdit) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed:
                      s.isLoading ? null : () => _leave(context, ref, team),
                  child: Text('LEAVE TEAM',
                      style: AppTextStyles.button
                          .copyWith(color: AppColors.error)),
                ),
              ],
            ],
          ),
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
    final notifier = ref.read(teamProvider(tournamentId).notifier);
    final confirmedCount = team.confirmedMainCount;
    final slotsNeeded = 4 - confirmedCount;
    final canReg = team.canRegister ?? (confirmedCount >= 4);

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
            // 1. CONFIRMED / Registered -> View Match Lobby & Room
            if (team.isRegistered ||
                team.registrationState == TeamRegistrationState.confirmed) ...[
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
                      page: TournamentDetailScreen(
                        tournamentId: tournamentId,
                        initialTabIndex: 4,
                      ),
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
            // 2. WAITLISTED -> Display position & LEAVE WAITLIST button for owner
            else if (team.registrationState ==
                TeamRegistrationState.waitlisted) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accentOrange.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: AppColors.accentOrange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You are #${team.waitlistPosition ?? 1} of ${team.waitlistSize ?? 1} in the waitlist. We will confirm your slot automatically when one opens.',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.accentOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (await _confirm(
                                context,
                                'Leave Waitlist?',
                                'Are you sure you want to leave the waitlist? Your spot in line will be forfeited.',
                                'Leave Waitlist',
                              )) {
                                notifier.leaveWaitlist();
                              }
                            },
                      child: Text(
                        'LEAVE WAITLIST',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ]
            // 3. PENDING_PLAYER_APPROVAL
            else if (team.registrationState ==
                TeamRegistrationState.pendingPlayerApproval) ...[
              if (team.myPendingApprovalId != null &&
                  team.myPendingApprovalId!.isNotEmpty) ...[
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
                        page: PlayerApprovalScreen(
                          approvalId: team.myPendingApprovalId!,
                          tournamentId: tournamentId,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rate_review_rounded,
                          color: AppColors.bgNavy, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'REVIEW & APPROVE PARTICIPATION',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.bgNavy,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isOwner &&
                  (team.canCancelRegistrationRequest ?? true)) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (await _confirm(
                            context,
                            'Cancel Request?',
                            'Are you sure you want to cancel this registration request?',
                            'Cancel Request',
                          )) {
                            notifier.cancelRegistrationRequest();
                          }
                        },
                  child: Text(
                    'CANCEL REGISTRATION REQUEST',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: AppColors.accentOrange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Waiting for player approvals (${team.registration?.approvedCount ?? 0}/${team.registration?.requiredCount ?? 3})',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]
            // 4. ROSTER_CHANGE_REQUIRED
            else if (team.registrationState ==
                TeamRegistrationState.rosterChangeRequired) ...[
              if (isOwner) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.accentOrange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                final mode = tournament?.mode ?? 'SQUAD';
                                notifier.completeRegistration(mode: mode);
                              },
                        child: Text(
                          'ASK AGAIN',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.accentOrange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.primaryNeon,
                          foregroundColor: AppColors.bgNavy,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            FirePageRoute(
                              page: RegisterReviewScreen(
                                tournamentId: tournamentId,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'CHANGE ROSTER',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.bgNavy,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Waiting for your Leader/Manager to fix the roster',
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ]
            // 5. Not enough main players -> Neutral message (No "waitlist" wording)
            else if (confirmedCount < 4) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group_add_rounded,
                      color: AppColors.accentOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Waiting for $slotsNeeded more player${slotsNeeded == 1 ? '' : 's'} to join',
                            style: AppTextStyles.headingMd.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '4 main playing members are required to register for the tournament.',
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
            // 6. Requirement met & State FORMING -> Register button (Owner) or Waiting for Leader message (Non-owner)
            else if (isOwner && canReg) ...[
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
                onPressed: isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          FirePageRoute(
                            page: RegisterReviewScreen(
                              tournamentId: tournamentId,
                            ),
                          ),
                        );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.bgNavy,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.how_to_reg_rounded,
                              color: AppColors.bgNavy, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'REGISTER FOR TOURNAMENT',
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
            // 7. Non-Owner, requirement met, state FORMING
            else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_top_rounded,
                      color: AppColors.accentOrange,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Waiting for your Leader/Manager to register the team',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
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
    if (team.isRegistered ||
        team.registrationState == TeamRegistrationState.confirmed) {
      color = AppColors.success;
      icon = Icons.verified_rounded;
      text = '🎉 Registered! Team is ready & roster is locked.';
    } else if (team.registrationState == TeamRegistrationState.waitlisted) {
      color = AppColors.warning;
      icon = Icons.schedule_rounded;
      final pos = team.waitlistPosition ?? 1;
      final size = team.waitlistSize ?? 1;
      text = 'You are #$pos of $size in the waitlist. We will confirm your slot automatically when one opens.';
    } else if (team.isLocked) {
      color = AppColors.error;
      icon = Icons.lock_rounded;
      text = 'Registration closed. The roster can no longer be changed.';
    } else if (tournament != null &&
        tournament.status == TournamentStatus.upcoming) {
      color = AppColors.warning;
      icon = Icons.schedule_rounded;
      text = 'Registration opens when tournament goes LIVE on backend.';
    } else if (team.isReady || team.confirmedMainCount >= 4) {
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

class _JoinRequestsSection extends ConsumerWidget {
  const _JoinRequestsSection({
    required this.team,
    required this.tournamentId,
  });

  final TournamentTeamModel team;
  final String tournamentId;

  Future<bool> _confirmReject(BuildContext context, String userName) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Reject Join Request?', style: AppTextStyles.headingLg),
        content: Text(
          'Are you sure you want to reject $userName\'s request to join the team?',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('Reject',
                style: AppTextStyles.button.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!team.viewerIsOwner || team.isLocked || team.isRegistered) {
      return const SizedBox.shrink();
    }

    final requestsState = ref.watch(ownerJoinRequestsProvider(team.id));
    final requests = requestsState.requests;

    if (requests.isEmpty &&
        team.pendingJoinRequestsCount == 0 &&
        !requestsState.isLoading &&
        requestsState.error == null) {
      return const SizedBox.shrink();
    }

    final displayCount =
        requests.isNotEmpty ? requests.length : team.pendingJoinRequestsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_add_rounded,
                color: AppColors.accentOrange, size: 20),
            const SizedBox(width: 8),
            Text(
              'JOIN REQUESTS ($displayCount)',
              style: AppTextStyles.headingMd,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (requestsState.error != null) ...[
          Text(requestsState.error!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
        ],
        for (final req in requests)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceMuted,
                      backgroundImage: req.userProfilePic.isNotEmpty
                          ? NetworkImage(req.userProfilePic)
                          : null,
                      child: req.userProfilePic.isEmpty
                          ? const Icon(Icons.person_rounded,
                              size: 20, color: AppColors.textMuted)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.userName.isNotEmpty ? req.userName : 'User',
                            style: AppTextStyles.bodyLg
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'IGN: ${req.inGameName.isNotEmpty ? req.inGameName : "-"} • UID: ${req.inGameUid.isNotEmpty ? req.inGameUid : "-"}',
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: req.requestedAsSubstitute
                            ? AppColors.textMuted.withValues(alpha: 0.15)
                            : AppColors.primaryNeon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: req.requestedAsSubstitute
                              ? AppColors.textMuted.withValues(alpha: 0.4)
                              : AppColors.primaryNeon.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        req.requestedAsSubstitute ? 'Substitute' : 'Player',
                        style: AppTextStyles.caption.copyWith(
                          color: req.requestedAsSubstitute
                              ? AppColors.textSecondary
                              : AppColors.primaryNeon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: requestsState.actioningRequestId == req.id
                              ? null
                              : () async {
                                  if (await _confirmReject(
                                      context, req.userName)) {
                                    final ok = await ref
                                        .read(ownerJoinRequestsProvider(team.id)
                                            .notifier)
                                        .rejectRequest(req.id);
                                    if (ok && context.mounted) {
                                      ref
                                          .read(teamProvider(tournamentId)
                                              .notifier)
                                          .refresh();
                                    }
                                  }
                                },
                          child: Text(
                            'REJECT',
                            style: AppTextStyles.button
                                .copyWith(color: AppColors.error, fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNeon,
                            foregroundColor: AppColors.bgNavy,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: requestsState.actioningRequestId == req.id
                              ? null
                              : () async {
                                  final ok = await ref
                                      .read(ownerJoinRequestsProvider(team.id)
                                          .notifier)
                                      .approveRequest(req.id);
                                  if (context.mounted) {
                                    if (ok) {
                                      ref
                                          .read(teamProvider(tournamentId)
                                              .notifier)
                                          .refresh();
                                    } else {
                                      final err = ref
                                              .read(ownerJoinRequestsProvider(
                                                  team.id))
                                              .error ??
                                          'Failed to approve request';
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(err)),
                                      );
                                    }
                                  }
                                },
                          child: requestsState.actioningRequestId == req.id
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.bgNavy),
                                )
                              : Text(
                                  'APPROVE',
                                  style: AppTextStyles.button.copyWith(
                                      color: AppColors.bgNavy,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (status) {
      case ApprovalStatus.approved:
        color = AppColors.success;
        label = 'APPROVED';
        break;
      case ApprovalStatus.declined:
        color = AppColors.error;
        label = 'DECLINED';
        break;
      case ApprovalStatus.notRequired:
        color = AppColors.textMuted;
        label = 'NOT REQUIRED';
        break;
      case ApprovalStatus.pending:
        color = AppColors.accentOrange;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
