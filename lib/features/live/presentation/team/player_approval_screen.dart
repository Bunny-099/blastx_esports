import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/core/transitions/fire_page_route.dart';
import 'package:blastix_esports/features/live/data/models/registration_approval_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/presentation/team/team_lobby_screen.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/profile/providers/profile_provider.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:blastix_esports/shared/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for playing players to review and respond to a tournament registration approval request.
class PlayerApprovalScreen extends ConsumerStatefulWidget {
  const PlayerApprovalScreen({
    super.key,
    required this.approvalId,
    this.tournamentId,
    this.initialApproval,
  });

  final String approvalId;
  final String? tournamentId;
  final RegistrationApproval? initialApproval;

  @override
  ConsumerState<PlayerApprovalScreen> createState() => _PlayerApprovalScreenState();
}

class _PlayerApprovalScreenState extends ConsumerState<PlayerApprovalScreen> {
  RegistrationApproval? _approval;
  bool _isLoading = true;
  String? _error;
  bool _isActioning = false;
  String? _actionSuccessMessage;

  @override
  void initState() {
    super.initState();
    _approval = widget.initialApproval;
    _fetchApprovalDetail();
  }

  Future<void> _fetchApprovalDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(teamRepositoryProvider);
      final detail = await repo.approvalDetail(widget.approvalId);
      if (mounted) {
        setState(() {
          _approval = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'This request is no longer valid because the roster changed or the registration is no longer pending.';
        });
      }
    }
  }

  Future<bool> _confirmDecline() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Decline Participation?', style: AppTextStyles.headingLg),
        content: Text(
          'Are you sure you want to decline? This will reject the team\'s registration request and return the team to forming state.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
    return res == true;
  }

  Future<void> _onApprove() async {
    setState(() {
      _isActioning = true;
    });

    final ok = await ref.read(approvalsProvider.notifier).approve(widget.approvalId);

    if (mounted) {
      setState(() {
        _isActioning = false;
      });

      if (ok) {
        final tid = _approval?.tournamentId ?? widget.tournamentId ?? '';
        if (tid.isNotEmpty) {
          ref.read(teamProvider(tid).notifier).refresh();
        }

        setState(() {
          _actionSuccessMessage = 'Approved! Waiting for the other players to approve.';
        });
      } else {
        final err = ref.read(approvalsProvider).error ?? 'Failed to approve request.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  Future<void> _onDecline() async {
    if (!await _confirmDecline()) return;

    setState(() {
      _isActioning = true;
    });

    final ok = await ref.read(approvalsProvider.notifier).decline(widget.approvalId);

    if (mounted) {
      setState(() {
        _isActioning = false;
      });

      if (ok) {
        final tid = _approval?.tournamentId ?? widget.tournamentId ?? '';
        if (tid.isNotEmpty) {
          ref.read(teamProvider(tid).notifier).refresh();
        }

        setState(() {
          _actionSuccessMessage = 'Declined. Team roster change required.';
        });
      } else {
        final err = ref.read(approvalsProvider).error ?? 'Failed to decline request.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  void _navigateToLobby() {
    final tid = _approval?.tournamentId ?? widget.tournamentId ?? '';
    if (tid.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        FirePageRoute(
          page: TeamLobbyScreen(tournamentId: tid),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        ref.watch(profileProvider).user?.id ?? ref.watch(squadProvider).viewerUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('PARTICIPATION APPROVAL', style: AppTextStyles.headingLg),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Request No Longer Valid',
                        style: AppTextStyles.headingLg,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'GO TO TEAM LOBBY',
                        onPressed: _navigateToLobby,
                      ),
                    ],
                  ),
                )
              : _actionSuccessMessage != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _actionSuccessMessage!,
                            style: AppTextStyles.headingLg,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'VIEW TEAM LOBBY',
                            onPressed: _navigateToLobby,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Tournament Header
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
                                (_approval?.tournamentTitle ?? 'Tournament').toUpperCase(),
                                style: AppTextStyles.headingLg.copyWith(
                                  color: AppColors.primaryNeon,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.surfaceMuted,
                                    backgroundImage: _approval?.teamLogoUrl.isNotEmpty == true
                                        ? NetworkImage(_approval!.teamLogoUrl)
                                        : null,
                                    child: _approval?.teamLogoUrl.isEmpty != false
                                        ? const Icon(Icons.groups_rounded, size: 18, color: AppColors.textMuted)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _approval?.teamTag.isNotEmpty == true
                                          ? '[${_approval!.teamTag}] ${_approval!.teamName.toUpperCase()}'
                                          : (_approval?.teamName ?? 'Team').toUpperCase(),
                                      style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Roster Change Notice
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNeon.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.group_add_rounded, color: AppColors.primaryNeon, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You were added to the Playing Roster of ${_approval?.teamName ?? "the team"}. Please review and respond.',
                                  style: AppTextStyles.bodySm.copyWith(color: AppColors.primaryNeon, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Responsible Person
                        if (_approval?.responsiblePerson != null) ...[
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
                                        'SUBMITTED BY',
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.primaryNeon,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_approval!.responsiblePerson!.name} (${_approval!.responsiblePerson!.role})',
                                        style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Playing Roster List
                        Text('PLAYING ROSTER', style: AppTextStyles.headingMd),
                        const SizedBox(height: 8),
                        for (final player in _approval?.playingPlayers ?? <RegistrationPlayer>[])
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: player.userId == currentUserId
                                  ? AppColors.primaryNeon.withValues(alpha: 0.1)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: player.userId == currentUserId
                                    ? AppColors.primaryNeon.withValues(alpha: 0.5)
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.surfaceMuted,
                                  backgroundImage: player.avatar.isNotEmpty
                                      ? NetworkImage(player.avatar)
                                      : null,
                                  child: player.avatar.isEmpty
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
                                          if (player.userId == currentUserId) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryNeon,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'YOU',
                                                style: AppTextStyles.caption.copyWith(
                                                  color: AppColors.bgNavy,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        player.role,
                                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                _StatusBadge(status: player.approvalStatus),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Action Buttons
                        if (_approval?.isPending == true) ...[
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.error),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: _isActioning ? null : _onDecline,
                                    child: Text(
                                      'DECLINE',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: 'APPROVE',
                                  isLoading: _isActioning,
                                  onPressed: _isActioning ? null : _onApprove,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          CustomButton(
                            text: 'VIEW TEAM LOBBY',
                            onPressed: _navigateToLobby,
                          ),
                        ],
                      ],
                    ),
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
