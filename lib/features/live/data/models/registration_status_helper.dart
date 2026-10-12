import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'team_model.dart';
import 'tournament_model.dart';

/// Representation of the small registration badge shown on tournament cards.
class BadgeState {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const BadgeState({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });
}

/// Helper that turns a [TournamentModel] + `my_registration` into a [BadgeState].
/// Returns `null` if no registration badge should be rendered.
BadgeState? getRegistrationBadge(TournamentModel tournament) {
  final reg = tournament.myRegistration;
  if (reg == null) {
    // Fall back to checking isRegistered on model or team if available
    if (tournament.effectiveIsRegistered) {
      return const BadgeState(
        label: 'Registered ✓',
        backgroundColor: Color(0x3334C759),
        textColor: Color(0xFF34C759),
        borderColor: Color(0x6634C759),
      );
    }
    return null;
  }

  switch (reg.state) {
    case MyRegistrationState.confirmed:
      return const BadgeState(
        label: 'Registered',
        backgroundColor: Color(0x3334C759),
        textColor: Color(0xFF34C759),
        borderColor: Color(0x6634C759),
      );

    case MyRegistrationState.pendingPlayerApproval:
      return BadgeState(
        label: 'Approval pending',
        backgroundColor: AppColors.accentOrange.withValues(alpha: 0.18),
        textColor: AppColors.accentOrange,
        borderColor: AppColors.accentOrange.withValues(alpha: 0.5),
      );

    case MyRegistrationState.rosterChangeRequired:
      return BadgeState(
        label: 'Action needed',
        backgroundColor: AppColors.error.withValues(alpha: 0.18),
        textColor: AppColors.error,
        borderColor: AppColors.error.withValues(alpha: 0.5),
      );

    case MyRegistrationState.waitlisted:
      final posStr = reg.waitlistPosition != null && reg.waitlistPosition! > 0
          ? ' #${reg.waitlistPosition}'
          : '';
      return BadgeState(
        label: 'Waitlisted$posStr',
        backgroundColor: AppColors.accentOrange.withValues(alpha: 0.18),
        textColor: AppColors.accentOrange,
        borderColor: AppColors.accentOrange.withValues(alpha: 0.5),
      );

    case MyRegistrationState.forming:
      return BadgeState(
        label: 'Team forming',
        backgroundColor: AppColors.primaryNeon.withValues(alpha: 0.18),
        textColor: AppColors.primaryNeon,
        borderColor: AppColors.primaryNeon.withValues(alpha: 0.5),
      );

    case MyRegistrationState.pendingPayment:
      return BadgeState(
        label: 'Payment pending',
        backgroundColor: AppColors.accentOrange.withValues(alpha: 0.18),
        textColor: AppColors.accentOrange,
        borderColor: AppColors.accentOrange.withValues(alpha: 0.5),
      );

    case MyRegistrationState.unknown:
      return null;
  }
}

/// Enumeration of all possible Floating CTA states on Tournament Detail screen
enum CtaType {
  completed,
  upcomingCountdown,
  confirmed,
  waitlisted,
  approveParticipation,
  waitingApprovals,
  rosterChangeRequired,
  forming,
  liveFullNoRegistration,
  liveJoinNow,
}

/// Data class encapsulating Floating CTA label, action behavior, and styling.
class CtaState {
  final CtaType type;
  final String label;
  final String? subNote;
  final bool isEnabled;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const CtaState({
    required this.type,
    required this.label,
    this.subNote,
    this.isEnabled = true,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}

/// Shared helper function to calculate [CtaState] based on [TournamentModel] and optional [TournamentTeamModel].
/// Tolerates missing fields gracefully.
CtaState getCtaState(TournamentModel tournament, TournamentTeamModel? team) {
  final myReg = tournament.myRegistration;
  final isOwner = team?.viewerIsOwner ?? false;

  // Priority 1: Tournament completed
  if (tournament.status == TournamentStatus.completed) {
    return const CtaState(
      type: CtaType.completed,
      label: 'TOURNAMENT COMPLETED',
      isEnabled: false,
      backgroundColor: AppColors.surface,
      textColor: Colors.white,
      icon: Icons.emoji_events_rounded,
    );
  }

  // Priority 2: Upcoming tournament -> countdown state
  if (tournament.status == TournamentStatus.upcoming) {
    return const CtaState(
      type: CtaType.upcomingCountdown,
      label: 'REGISTRATION OPENS WHEN LIVE',
      isEnabled: false,
      backgroundColor: AppColors.surfaceElevated,
      textColor: AppColors.textPrimary,
      icon: Icons.lock_clock_rounded,
    );
  }

  // Priority 3: my_registration.state == CONFIRMED (or team.isRegistered)
  final isConfirmed = myReg?.state == MyRegistrationState.confirmed ||
      team?.isRegistered == true ||
      team?.registrationState == TeamRegistrationState.confirmed;
  if (isConfirmed) {
    return const CtaState(
      type: CtaType.confirmed,
      label: 'REGISTERED - VIEW MATCHES',
      isEnabled: true,
      backgroundColor: AppColors.surfaceNavy,
      textColor: AppColors.primaryNeon,
      icon: Icons.check_circle_rounded,
    );
  }

  // Priority 4: my_registration.state == WAITLISTED (or team.registrationState == WAITLISTED)
  final isWaitlisted = myReg?.state == MyRegistrationState.waitlisted ||
      team?.registrationState == TeamRegistrationState.waitlisted;
  if (isWaitlisted) {
    final pos = myReg?.waitlistPosition ?? team?.waitlistPosition;
    final posStr = pos != null && pos > 0 ? ' #$pos' : '';
    return CtaState(
      type: CtaType.waitlisted,
      label: 'WAITLISTED$posStr - VIEW STATUS',
      isEnabled: true,
      backgroundColor: AppColors.surfaceElevated,
      textColor: AppColors.accentOrange,
      icon: Icons.schedule_rounded,
    );
  }

  // Priority 5: my_pending_approval_id present
  final pendingApprovalId = myReg?.myPendingApprovalId ?? team?.myPendingApprovalId;
  if (pendingApprovalId != null && pendingApprovalId.isNotEmpty) {
    return const CtaState(
      type: CtaType.approveParticipation,
      label: 'APPROVE PARTICIPATION',
      isEnabled: true,
      backgroundColor: AppColors.primaryNeon,
      textColor: AppColors.bgNavy,
      icon: Icons.rate_review_rounded,
    );
  }

  // Priority 6: my_registration.state == PENDING_PLAYER_APPROVAL
  final isPendingApproval = myReg?.state == MyRegistrationState.pendingPlayerApproval ||
      team?.registrationState == TeamRegistrationState.pendingPlayerApproval;
  if (isPendingApproval) {
    final approved = myReg?.approvalsApproved ?? team?.registration?.approvedCount ?? 0;
    final required = myReg?.approvalsRequired ?? team?.registration?.requiredCount ?? 3;
    return CtaState(
      type: CtaType.waitingApprovals,
      label: 'WAITING FOR APPROVALS ($approved/$required) - VIEW STATUS',
      isEnabled: true,
      backgroundColor: AppColors.surfaceElevated,
      textColor: AppColors.accentOrange,
      icon: Icons.hourglass_top_rounded,
    );
  }

  // Priority 7: my_registration.state == ROSTER_CHANGE_REQUIRED
  final isRosterChange = myReg?.state == MyRegistrationState.rosterChangeRequired ||
      team?.registrationState == TeamRegistrationState.rosterChangeRequired;
  if (isRosterChange) {
    return CtaState(
      type: CtaType.rosterChangeRequired,
      label: isOwner ? 'FIX ROSTER' : 'VIEW STATUS',
      isEnabled: true,
      backgroundColor: AppColors.surfaceElevated,
      textColor: AppColors.error,
      icon: Icons.warning_amber_rounded,
    );
  }

  // Priority 8: my_registration.state == FORMING (team exists)
  final isForming = myReg?.state == MyRegistrationState.forming ||
      (team != null && team.registrationState == TeamRegistrationState.forming);
  if (isForming) {
    return CtaState(
      type: CtaType.forming,
      label: isOwner ? 'CONTINUE REGISTRATION' : 'VIEW TEAM LOBBY',
      isEnabled: true,
      backgroundColor: AppColors.primaryNeon,
      textColor: AppColors.bgNavy,
      icon: Icons.how_to_reg_rounded,
    );
  }

  // Priority 9: live, no registration, tournament is full -> JOIN NOW with waitlist note
  if (tournament.isLive && tournament.isFull) {
    return const CtaState(
      type: CtaType.liveFullNoRegistration,
      label: 'JOIN NOW',
      subNote: 'All slots are filled - you will be added to the waitlist',
      isEnabled: true,
      backgroundColor: AppColors.accentOrange,
      textColor: AppColors.bgNavy,
      icon: Icons.sports_esports_rounded,
    );
  }

  // Priority 10: live, no registration, slots available -> JOIN NOW
  final feeText = tournament.isFree ? 'FREE' : tournament.formattedEntryFee;
  return CtaState(
    type: CtaType.liveJoinNow,
    label: 'JOIN NOW • $feeText',
    isEnabled: true,
    backgroundColor: AppColors.primaryNeon,
    textColor: AppColors.bgNavy,
    icon: Icons.sports_esports_rounded,
  );
}
