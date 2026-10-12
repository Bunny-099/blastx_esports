import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/presentation/team/join_request_sent_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/player_info_form.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/profile/providers/profile_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows privacy-safe team preview found by code.
/// The user inputs their Free Fire details and either joins directly
/// or submits a join request based on require_join_approval.
class TeamPreviewScreen extends ConsumerStatefulWidget {
  const TeamPreviewScreen({super.key, required this.tournamentId});
  final String tournamentId;

  @override
  ConsumerState<TeamPreviewScreen> createState() => _TeamPreviewScreenState();
}

class _TeamPreviewScreenState extends ConsumerState<TeamPreviewScreen> {
  final _player = TextEditingController();
  final _uid = TextEditingController();
  String? _localError;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_prefillFromProfile);
  }

  void _prefillFromProfile() {
    final user = ref.read(profileProvider).user;
    if (user != null) {
      if (_player.text.trim().isEmpty && user.name.isNotEmpty) {
        _player.text = user.name;
      }
      if (_uid.text.trim().isEmpty) {
        final existingUid = user.gameProfile?.inGameUid;
        if (existingUid != null && existingUid.isNotEmpty) {
          _uid.text = existingUid;
        }
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _uid.dispose();
    super.dispose();
  }

  Future<void> _handleJoinOrRequest() async {
    final playerName = _player.text.trim();
    final uid = _uid.text.trim();

    final err = PlayerInfoForm.validate(playerName, uid);
    setState(() => _localError = err);
    if (err != null) return;

    final result = await ref.read(teamProvider(widget.tournamentId).notifier).joinTeam(
          playerName: playerName,
          ign: playerName,
          uid: uid,
        );

    if (result != null && mounted) {
      ref.read(profileProvider.notifier).updateFullProfile(
            name: playerName.isNotEmpty ? playerName : (ref.read(profileProvider).user?.name ?? ''),
            freeFireUid: uid,
            inGameName: playerName,
          );

      if (result.status == JoinResultStatus.pending) {
        final preview = ref.read(teamProvider(widget.tournamentId)).previewTeam;
        final sent = await Navigator.of(context).push<bool>(
          FirePageRoute(
            page: JoinRequestSentScreen(
              tournamentId: widget.tournamentId,
              requestId: result.request?.id ?? '',
              teamName: preview?.name ?? '',
              teamLogoUrl: preview?.logoUrl ?? '',
              ownerName: preview?.responsiblePerson?.name ?? 'Leader',
              tournamentName: preview?.tournamentName ?? '',
            ),
          ),
        );
        if (sent == true && mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _cancelMyPendingRequest(String requestId) async {
    setState(() => _isCancelling = true);
    final ok = await ref.read(myPendingRequestsProvider.notifier).cancelRequest(requestId);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request cancelled.')),
      );
      // Refresh preview to update status
      final team = ref.read(teamProvider(widget.tournamentId)).previewTeam;
      if (team != null) {
        ref.read(teamProvider(widget.tournamentId).notifier).lookupTeam(team.code);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.user != null) {
        _prefillFromProfile();
      }
    });

    final s = ref.watch(teamProvider(widget.tournamentId));
    final team = s.previewTeam;

    if (team == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(child: Text('Team not found', style: AppTextStyles.bodyMd)),
      );
    }

    final isSub = team.isMainFull && team.canJoinAsSubstitute;
    final isLocked = team.rosterLocked || team.registrationState == TeamRegistrationState.confirmed;
    final isFull = !team.slotsAvailable || (team.isMainFull && !team.canJoinAsSubstitute);
    final isPending = team.myRequestStatus == JoinRequestStatus.pending;
    final isMember = team.isMember;

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

            // Privacy-Safe Players List Card
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
                  if (team.members.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('No members listed yet.', style: AppTextStyles.bodySm),
                    )
                  else
                    ...team.members.map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.surfaceMuted,
                              backgroundImage: m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
                              child: m.avatarUrl.isEmpty
                                  ? Icon(
                                      m.role == 'LEADER' || m.role == 'CAPTAIN'
                                          ? Icons.workspace_premium_rounded
                                          : Icons.person_rounded,
                                      size: 16,
                                      color: m.role == 'LEADER' || m.role == 'CAPTAIN'
                                          ? AppColors.gold
                                          : AppColors.textMuted,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                m.name,
                                style: AppTextStyles.bodyLg,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (m.role == 'LEADER' || m.role == 'CAPTAIN')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'LEADER',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                                ),
                              )
                            else if (m.role == 'MANAGER')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNeon.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  'MANAGER',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                                ),
                              )
                            else if (m.isSubstitute)
                              Text(' (SUB)', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ),
                  const Divider(color: AppColors.border, height: 24),
                  Text(
                    '${team.mainCount} / ${team.maxMain} Main Players',
                    style: AppTextStyles.headingMd.copyWith(color: AppColors.primaryLight),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    team.isMainFull
                        ? 'Main roster full • ${team.maxSubstitutes - team.substituteCount} substitute slot(s) left'
                        : '${team.mainSlotsLeft} slot(s) available',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // States: Member, Pending Request, Locked, Full, or Join Form
            if (isMember) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You are already a member of this team.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'OPEN TEAM LOBBY',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ] else if (isPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: AppColors.accentOrange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Request pending. Waiting for team owner to approve.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.accentOrange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'CANCEL REQUEST',
                isOutlined: true,
                isLoading: _isCancelling,
                onPressed: () {
                  // Find pending request ID if known or cancel via myPendingRequests
                  final pendingList = ref.read(myPendingRequestsProvider).pendingRequests;
                  final match = pendingList.firstWhere(
                    (r) => r.teamId == team.id || r.tournamentId == widget.tournamentId,
                    orElse: () => const JoinRequest(id: '', teamId: ''),
                  );
                  if (match.id.isNotEmpty) {
                    _cancelMyPendingRequest(match.id);
                  }
                },
              ),
            ] else if (isLocked) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Team registration is locked.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const CustomButton(
                text: 'TEAM REGISTRATION IS LOCKED',
                onPressed: null,
              ),
            ] else if (isFull) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This team is full.',
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const CustomButton(
                text: 'TEAM IS FULL',
                onPressed: null,
              ),
            ] else ...[
              Text('YOUR FREE FIRE DETAILS', style: AppTextStyles.headingMd),
              const SizedBox(height: 8),
              PlayerInfoForm(
                nameController: _player,
                uidController: _uid,
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error, style: AppTextStyles.bodySm.copyWith(color: AppColors.error)),
              ],
              const SizedBox(height: 22),
              CustomButton(
                text: team.requireJoinApproval
                    ? (isSub ? 'REQUEST TO JOIN AS SUBSTITUTE' : 'REQUEST TO JOIN')
                    : (isSub ? 'JOIN AS SUBSTITUTE' : 'JOIN TEAM'),
                isLoading: s.isLoading,
                onPressed: _handleJoinOrRequest,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(TeamPreview team) {
    final resp = team.responsiblePerson;
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.surfaceMuted,
          backgroundImage: team.logoUrl.isNotEmpty ? NetworkImage(team.logoUrl) : null,
          child: team.logoUrl.isEmpty
              ? const Icon(Icons.groups_rounded, color: AppColors.textMuted, size: 28)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.tag.isNotEmpty ? '[${team.tag}] ${team.name.toUpperCase()}' : team.name.toUpperCase(),
                style: AppTextStyles.display,
              ),
              if (resp != null)
                Text(
                  '${resp.role == "MANAGER" ? "Manager" : "Leader"}: ${resp.name}',
                  style: AppTextStyles.bodyMd,
                ),
              if (team.tournamentName.isNotEmpty)
                Text(team.tournamentName, style: AppTextStyles.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}
