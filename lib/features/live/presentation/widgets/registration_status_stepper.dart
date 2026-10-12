import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:flutter/material.dart';

/// Registration status stepper showing team progress:
/// Roster -> Approvals -> Payment (if paid) -> Slot
class RegistrationStatusStepper extends StatelessWidget {
  const RegistrationStatusStepper({
    super.key,
    required this.team,
    this.tournament,
  });

  final TournamentTeamModel team;
  final TournamentModel? tournament;

  @override
  Widget build(BuildContext context) {
    final state = team.registrationState;
    final isPaid = (tournament?.entryFee ?? 0) > 0;

    int activeStep = 0;
    switch (state) {
      case TeamRegistrationState.forming:
        activeStep = 0;
        break;
      case TeamRegistrationState.pendingPlayerApproval:
      case TeamRegistrationState.rosterChangeRequired:
        activeStep = 1;
        break;
      case TeamRegistrationState.pendingPayment:
        activeStep = isPaid ? 2 : 3;
        break;
      case TeamRegistrationState.waitlisted:
      case TeamRegistrationState.confirmed:
        activeStep = isPaid ? 3 : 2;
        break;
    }

    final steps = <_StepData>[
      _StepData(
        title: 'Roster',
        isComplete: activeStep > 0 || state == TeamRegistrationState.confirmed,
        isCurrent: activeStep == 0,
        isError: false,
      ),
      _StepData(
        title: 'Approvals',
        isComplete: activeStep > 1 || state == TeamRegistrationState.confirmed,
        isCurrent: activeStep == 1,
        isError: state == TeamRegistrationState.rosterChangeRequired,
      ),
      if (isPaid)
        _StepData(
          title: 'Payment',
          isComplete: activeStep > 2 || state == TeamRegistrationState.confirmed,
          isCurrent: activeStep == 2,
          isError: false,
        ),
      _StepData(
        title: 'Slot',
        isComplete: state == TeamRegistrationState.confirmed,
        isCurrent: (isPaid && activeStep == 3) || (!isPaid && activeStep == 2),
        isError: state == TeamRegistrationState.waitlisted,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper Circles & Connecting Lines Row
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: steps[i].isComplete || steps[i].isCurrent
                          ? (steps[i].isError ? AppColors.error : AppColors.primaryNeon)
                          : AppColors.border,
                    ),
                  ),
                _StepCircle(
                  stepNumber: i + 1,
                  data: steps[i],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // Step Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final s in steps)
                SizedBox(
                  width: 60,
                  child: Text(
                    s.title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: s.isCurrent || s.isComplete
                          ? (s.isError ? AppColors.error : AppColors.primaryNeon)
                          : AppColors.textMuted,
                      fontWeight: s.isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Detail Card per State
          _buildStateDetailCard(context),
        ],
      ),
    );
  }

  Widget _buildStateDetailCard(BuildContext context) {
    final state = team.registrationState;
    final regInfo = team.registration;

    switch (state) {
      case TeamRegistrationState.forming:
        return _DetailBox(
          color: team.confirmedMainCount >= 4 ? AppColors.primaryNeon : AppColors.accentOrange,
          icon: team.confirmedMainCount >= 4 ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
          title: 'FORMING ROSTER',
          subtitle: team.confirmedMainCount < 4
              ? 'Waiting for 4 main playing players (${team.confirmedMainCount}/4 confirmed).'
              : 'Roster complete! Ready for tournament registration.',
        );

      case TeamRegistrationState.pendingPlayerApproval:
        final approved = regInfo?.approvedCount ?? 0;
        final required = regInfo?.requiredCount ?? (team.isManagerOwned ? 4 : 3);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailBox(
              color: AppColors.accentOrange,
              icon: Icons.how_to_reg_rounded,
              title: 'PENDING APPROVALS ($approved/$required)',
              subtitle: 'Waiting for playing members to approve participation.',
            ),
            if (regInfo?.players.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in regInfo!.players)
                    _PlayerApprovalChip(player: p),
                ],
              ),
            ],
          ],
        );

      case TeamRegistrationState.rosterChangeRequired:
        final decliners = regInfo?.players.where((p) => p.isDeclined).toList() ?? [];
        final declinerNames = decliners.isNotEmpty
            ? decliners.map((p) => p.name).join(', ')
            : 'a member';
        return _DetailBox(
          color: AppColors.error,
          icon: Icons.warning_amber_rounded,
          title: 'ROSTER CHANGE REQUIRED',
          subtitle: 'Declined by $declinerNames. Update the roster or ask again.',
        );

      case TeamRegistrationState.pendingPayment:
        return const _DetailBox(
          color: AppColors.accentOrange,
          icon: Icons.payment_rounded,
          title: 'PENDING PAYMENT',
          subtitle: 'Payment entry is not available yet.',
        );

      case TeamRegistrationState.waitlisted:
        final pos = team.waitlistPosition ?? 1;
        final size = team.waitlistSize ?? 1;
        return _DetailBox(
          color: AppColors.accentOrange,
          icon: Icons.schedule_rounded,
          title: 'WAITLISTED (#$pos/$size)',
          subtitle: 'You are #$pos of $size in the waitlist. We will confirm your slot automatically when one opens.',
        );

      case TeamRegistrationState.confirmed:
        return const _DetailBox(
          color: AppColors.success,
          icon: Icons.verified_rounded,
          title: 'REGISTERED & CONFIRMED',
          subtitle: 'Team slot is confirmed and roster is locked.',
        );
    }
  }
}

class _StepData {
  final String title;
  final bool isComplete;
  final bool isCurrent;
  final bool isError;

  _StepData({
    required this.title,
    required this.isComplete,
    required this.isCurrent,
    required this.isError,
  });
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.stepNumber,
    required this.data,
  });

  final int stepNumber;
  final _StepData data;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color iconColor;

    if (data.isError) {
      bg = AppColors.error.withValues(alpha: 0.2);
      border = AppColors.error;
      iconColor = AppColors.error;
    } else if (data.isComplete) {
      bg = AppColors.primaryNeon;
      border = AppColors.primaryNeon;
      iconColor = AppColors.bgNavy;
    } else if (data.isCurrent) {
      bg = AppColors.surfaceNavy;
      border = AppColors.primaryNeon;
      iconColor = AppColors.primaryNeon;
    } else {
      bg = AppColors.surfaceMuted;
      border = AppColors.border;
      iconColor = AppColors.textMuted;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      child: Center(
        child: data.isComplete
            ? Icon(Icons.check_rounded, size: 16, color: iconColor)
            : data.isError
                ? Icon(Icons.priority_high_rounded, size: 16, color: iconColor)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerApprovalChip extends StatelessWidget {
  const _PlayerApprovalChip({required this.player});
  final RegistrationPlayer player;

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (player.approvalStatus) {
      case ApprovalStatus.approved:
        color = AppColors.success;
        label = '${player.name}: Approved ✓';
        break;
      case ApprovalStatus.declined:
        color = AppColors.error;
        label = '${player.name}: Declined ✕';
        break;
      case ApprovalStatus.notRequired:
        color = AppColors.textMuted;
        label = '${player.name}: Owner';
        break;
      case ApprovalStatus.pending:
        color = AppColors.accentOrange;
        label = '${player.name}: Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
