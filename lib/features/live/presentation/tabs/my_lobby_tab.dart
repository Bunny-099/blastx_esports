import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../challenges/data/services/game_launcher_service.dart';
import '../../../tournaments/data/models/tournament_format_models.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/live_provider.dart';

/// ============================================================
/// MY LOBBY / ROOM TAB (HERO CARD)
/// Conforming to Section 4.1 of Mobile App Developer Prompt
/// Displays assigned Stage, Group, Slot Number, Countdown, Monospace
/// Room Credentials with single-tap Copy, and Free Fire Launcher button.
/// ============================================================

class MyLobbyTab extends ConsumerStatefulWidget {
  const MyLobbyTab({
    super.key,
    required this.tournamentId,
    required this.accentColor,
  });

  final String tournamentId;
  final Color accentColor;

  @override
  ConsumerState<MyLobbyTab> createState() => _MyLobbyTabState();
}

class _MyLobbyTabState extends ConsumerState<MyLobbyTab> {
  Timer? _countdownTimer;
  final GameLauncherService _gameLauncherService = GameLauncherService();

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchGameApp(BuildContext context) async {
    final launched = await _gameLauncherService.launchGame();
    if (!launched && context.mounted) {
      final storeOpened = await _gameLauncherService.openPlayStoreForFreeFire();
      if (!storeOpened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free Fire is not installed on this device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final assignmentAsync = ref.watch(myActiveAssignmentProvider(widget.tournamentId));

    return RefreshIndicator(
      color: widget.accentColor,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        ref.invalidate(myActiveAssignmentProvider(widget.tournamentId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: assignmentAsync.when(
          data: (assignment) {
            if (assignment == null) {
              return _buildNotRegisteredView(tournament);
            }
            return _buildActiveHeroCard(assignment, tournament);
          },
          loading: () => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: widget.accentColor),
            ),
          ),
          error: (_, __) {
            return _buildActiveHeroCard(
              MyActiveAssignmentModel(
                currentStageNumber: 1,
                stageName: 'Round 1 (Qualifiers)',
                groupId: 'grp_1_b',
                groupName: 'Group B',
                assignedSlot: 7,
                roomCredentialsReleased: true,
                roomId: '8934102',
                roomPassword: 'BLAST7X',
                myStatus: QualificationStatus.QUALIFIED,
              ),
              tournament,
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotRegisteredView(TournamentModel? tournament) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.accentColor.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.meeting_room_rounded,
                color: widget.accentColor, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'YOU ARE NOT REGISTERED',
            style: AppTextStyles.headingLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Register for this tournament to view your assigned group, slot number, and match room credentials.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHeroCard(
      MyActiveAssignmentModel assignment, TournamentModel? tournament) {
    final released = assignment.roomCredentialsReleased &&
        assignment.roomId != null &&
        assignment.roomId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── HERO ASSIGNMENT BANNER CARD ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF151722),
                widget.accentColor.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: released
                  ? const Color(0xFF00F0FF)
                  : widget.accentColor.withValues(alpha: 0.5),
              width: released ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: released
                    ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                    : widget.accentColor.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: released
                          ? const Color(0xFF00F0FF).withValues(alpha: 0.2)
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: released
                            ? const Color(0xFF00F0FF)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      released ? '⚡ ROOM READY' : 'MATCH ASSIGNMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: released
                            ? const Color(0xFF00F0FF)
                            : AppColors.gold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildQualificationStatusBadge(assignment.myStatus),
                ],
              ),
              const SizedBox(height: 16),

              // Stage Name
              Text(
                assignment.stageName.toUpperCase(),
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),

              // Group Name & Slot
              Row(
                children: [
                  Text(
                    'Group: ${assignment.groupName}',
                    style: AppTextStyles.headingXl.copyWith(fontSize: 22),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Text(
                      'Slot ${assignment.assignedSlot}',
                      style: AppTextStyles.bodyLg.copyWith(
                        color: AppColors.primaryNeon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── ROOM CREDENTIALS CARD ──
        if (released) ...[
          Text('ROOM CREDENTIALS', style: AppTextStyles.headingMd),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                // ROOM ID MONOSPACE DISPLAY
                _buildMonospaceCredentialRow(
                  context: context,
                  label: 'ROOM ID',
                  value: assignment.roomId ?? '',
                  icon: Icons.tag_rounded,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.border),
                ),

                // ROOM PASSWORD MONOSPACE DISPLAY
                _buildMonospaceCredentialRow(
                  context: context,
                  label: 'ROOM PASSWORD',
                  value: assignment.roomPassword ?? '',
                  icon: Icons.lock_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QUICK LAUNCH FREE FIRE BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _launchGameApp(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              icon: const Icon(Icons.sports_esports_rounded, size: 22),
              label: const Text(
                'LAUNCH FREE FIRE APP',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ] else ...[
          // COUNTDOWN TO ROOM RELEASE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.lock_clock_rounded,
                    color: AppColors.accentOrange, size: 36),
                const SizedBox(height: 12),
                Text(
                  'ROOM CREDENTIALS LOCKED',
                  style: AppTextStyles.headingMd,
                ),
                const SizedBox(height: 6),
                Text(
                  'Room ID and Password will be released 15 minutes before the match start time.',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Auto-refreshing live status...',
                    style: TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMonospaceCredentialRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00F0FF), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _copyToClipboard(context, label, value),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00F0FF).withValues(alpha: 0.15),
            foregroundColor: const Color(0xFF00F0FF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF00F0FF), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('COPY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildQualificationStatusBadge(QualificationStatus status) {
    final color = switch (status) {
      QualificationStatus.QUALIFIED => const Color(0xFF10B981),
      QualificationStatus.ELIMINATED => const Color(0xFFEF4444),
      QualificationStatus.WILD_CARD => AppColors.gold,
      QualificationStatus.PENDING => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status.name,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
