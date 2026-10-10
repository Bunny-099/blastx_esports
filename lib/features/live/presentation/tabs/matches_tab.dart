import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../tournaments/presentation/widgets/wild_card_banner_widget.dart';
import '../../data/models/tournament_matches_model.dart';
import '../../providers/live_provider.dart';
import '../../providers/matches_provider.dart';

/// ============================================================
/// MATCHES TAB — Master Prompt Synchronized Edition
/// ============================================================
/// Supports 5-Stage Tournament Progression, Round 2 Dual-Exit,
/// 15-Minute Room Unlocking, Auto-Refresh at 00:00, and COPY BOTH action.
/// ============================================================

class MatchesTab extends ConsumerStatefulWidget {
  const MatchesTab({super.key, required this.tournamentId});

  final String tournamentId;

  @override
  ConsumerState<MatchesTab> createState() => _MatchesTabState();
}

class _MatchesTabState extends ConsumerState<MatchesTab>
    with AutomaticKeepAliveClientMixin {
  StreamSubscription<Map<String, dynamic>>? _notificationSub;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _notificationSub = NotificationService.instance.onNotificationTapped.listen((data) {
      final tid = data['tournament_id'] ?? data['tournamentId'];
      final type = data['type'];
      if (type == 'room_details_live' && (tid == widget.tournamentId || tid == null)) {
        ref.read(matchesProvider(widget.tournamentId).notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final asyncMatches = ref.watch(matchesProvider(widget.tournamentId));
    final tournament = ref.watch(tournamentByIdProvider(widget.tournamentId));
    final isRegistered = tournament?.effectiveIsRegistered ?? false;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(matchesProvider(widget.tournamentId).notifier).refresh(),
      color: AppColors.accentOrange,
      backgroundColor: AppColors.surface,
      child: asyncMatches.when(
        loading: () => const _MatchesShimmerState(),
        error: (err, stack) => _MatchesErrorState(
          onRetry: () => ref
              .read(matchesProvider(widget.tournamentId).notifier)
              .refresh(),
        ),
        data: (response) {
          final userContext = response.userContext;
          final rounds = response.rounds;
          final wildCardWindow = response.wildCardWindow;

          if (rounds.isEmpty && userContext == null) {
            return _MatchesEmptyState(
              isRegistered: isRegistered,
              onRefresh: () => ref
                  .read(matchesProvider(widget.tournamentId).notifier)
                  .refresh(),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              // 1. WILD CARD BANNER (If Open / Active)
              if (wildCardWindow != null && wildCardWindow.isOpen) ...[
                WildCardBannerWidget(
                  wildCardWindow: wildCardWindow,
                  onClaimPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Wild Card Slot Registration Request Sent!'),
                        backgroundColor: AppColors.accentOrange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.05, end: 0),
                const SizedBox(height: 16),
              ],

              // 2. HIGHLIGHT CARD: User Team Room & Group Status (Top Priority)
              if (isRegistered && userContext != null) ...[
                _UserTeamRoomCard(
                  userContext: userContext,
                  onTimerExpired: () {
                    ref
                        .read(matchesProvider(widget.tournamentId).notifier)
                        .refresh();
                  },
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.05, end: 0),
                const SizedBox(height: 20),
              ] else if (!isRegistered) ...[
                _NotRegisteredBanner()
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: -0.05, end: 0),
                const SizedBox(height: 20),
              ],

              // 3. ROUNDS & GROUPS TIMELINE HISTORY
              if (rounds.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'TOURNAMENT ROUNDS & SCHEDULE',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ...rounds.asMap().entries.map((entry) {
                  final roundIndex = entry.key;
                  final round = entry.value;

                  return _RoundSectionCard(
                    round: round,
                    userTeamId: userContext?.teamId ?? '',
                  )
                      .animate(delay: (60 * roundIndex).ms)
                      .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.05, end: 0);
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// ============================================================
/// 1. TOP HIGHLIGHT CARD: User Team Room Credentials & Status
/// ============================================================

class _UserTeamRoomCard extends StatefulWidget {
  const _UserTeamRoomCard({
    required this.userContext,
    required this.onTimerExpired,
  });

  final UserMatchContext userContext;
  final VoidCallback onTimerExpired;

  @override
  State<_UserTeamRoomCard> createState() => _UserTeamRoomCardState();
}

class _UserTeamRoomCardState extends State<_UserTeamRoomCard> {
  bool _isPasswordVisible = false;

  void _copyText(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyBoth(String roomId, String password) {
    if (roomId.isEmpty) return;
    final text = 'Room ID: $roomId | Password: $password';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primaryNeon, size: 20),
            SizedBox(width: 8),
            Text('Room ID & Password copied together!'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.userContext;

    // Handle Disqualified State
    if (ctx.isEliminated) {
      return _EliminatedCard(userContext: ctx);
    }

    // Handle Direct Finalist State (Round 2 Top 2 Teams)
    if (ctx.isDirectFinalist) {
      return _DirectFinalistCard(userContext: ctx);
    }

    // Handle Qualified for Next Round State
    if (ctx.isQualified && !ctx.isPublished) {
      return _QualifiedCard(userContext: ctx);
    }

    final isLive = ctx.status == TeamRoundStatus.live;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLive
              ? AppColors.primaryNeon
              : AppColors.accentOrange.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? AppColors.primaryNeon : AppColors.accentOrange)
                .withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Label Badge & Status Pill
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentOrange.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded,
                          color: AppColors.accentOrange, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'YOUR TEAM\'S MATCH',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _StatusBadge(status: ctx.status),
              ],
            ),

            const SizedBox(height: 12),

            // Round & Group Title
            Text(
              'Your Team: ${ctx.teamName} — ${ctx.groupName.toUpperCase()}',
              style: AppTextStyles.headingXl.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 2),
            Text(
              ctx.roundName,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),

            // Opponents & Map Info
            Row(
              children: [
                const Icon(Icons.sports_esports_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ctx.opponentTeamNames.isNotEmpty
                        ? 'vs ${ctx.opponentTeamNames.join(', ')}'
                        : 'Map: ${ctx.map}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 16),

            // ROOM CREDENTIALS OR LOCKED COUNTDOWN
            if (ctx.hasCredentials) ...[
              // Room ID Row
              _CredentialFieldRow(
                label: 'ROOM ID',
                value: ctx.roomId!,
                onCopy: () => _copyText(ctx.roomId!, 'Room ID'),
              ),
              const SizedBox(height: 10),

              // Password Row
              _CredentialFieldRow(
                label: 'PASSWORD',
                value: ctx.password ?? '••••••••',
                isPassword: true,
                isPasswordVisible: _isPasswordVisible,
                onToggleVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                onCopy: () =>
                    _copyText(ctx.password ?? '', 'Password'),
              ),

              const SizedBox(height: 14),

              // Copy Both Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _copyBoth(ctx.roomId!, ctx.password ?? ''),
                  icon: const Icon(Icons.content_copy_rounded, size: 16),
                  label: const Text('COPY ROOM ID & PASSWORD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNeon,
                    foregroundColor: AppColors.bgNavy,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: AppTextStyles.button.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Room Details Locked State
              _LockedRoomCountdownView(
                revealAt: ctx.revealAt ?? ctx.startsAt,
                onTimerExpired: widget.onTimerExpired,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Direct Finalist Card State (Round 2 Top 2 Teams)
class _DirectFinalistCard extends StatelessWidget {
  const _DirectFinalistCard({required this.userContext});

  final UserMatchContext userContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.25),
            blurRadius: 18,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded,
                        color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '🏆 DIRECT GRAND FINALIST',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFFFD700),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Congratulations ${userContext.teamName}! 🎉',
            style: AppTextStyles.headingXl.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            userContext.messageBanner ??
                'You have secured a direct spot in the Grand Final (Top 2 in Round 2). You do not need to play Round 3!',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper Row for displaying single Room ID or Password with copy button
class _CredentialFieldRow extends StatelessWidget {
  const _CredentialFieldRow({
    required this.label,
    required this.value,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onToggleVisibility,
    required this.onCopy,
  });

  final String label;
  final String value;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onToggleVisibility;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final displayValue = isPassword
        ? (isPasswordVisible ? value : '••••••••')
        : value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: AppTextStyles.headingMd.copyWith(
                    letterSpacing: isPassword && !isPasswordVisible ? 2.5 : 1.2,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          if (isPassword && onToggleVisibility != null)
            IconButton(
              icon: Icon(
                isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleVisibility,
              tooltip: isPasswordVisible ? 'Hide' : 'Show',
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  const Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: AppColors.primaryNeon,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'COPY',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primaryNeon,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Locked Room Countdown View
class _LockedRoomCountdownView extends StatefulWidget {
  const _LockedRoomCountdownView({
    this.revealAt,
    required this.onTimerExpired,
  });

  final DateTime? revealAt;
  final VoidCallback onTimerExpired;

  @override
  State<_LockedRoomCountdownView> createState() =>
      _LockedRoomCountdownViewState();
}

class _LockedRoomCountdownViewState extends State<_LockedRoomCountdownView> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (widget.revealAt == null) return;
    final diff = widget.revealAt!.difference(DateTime.now());
    if (diff.isNegative) {
      if (_remaining > Duration.zero) {
        widget.onTimerExpired();
      }
      _remaining = Duration.zero;
      _timer?.cancel();
    } else {
      if (mounted) {
        setState(() {
          _remaining = diff;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours.toString().padLeft(2, '0');
      final m = (d.inMinutes % 60).toString().padLeft(2, '0');
      final s = (d.inSeconds % 60).toString().padLeft(2, '0');
      return '${h}h ${m}m ${s}s';
    }
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: AppColors.accentOrange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Details Locked',
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.revealAt != null && _remaining > Duration.zero
                      ? '🔒 Room credentials will unlock in ${_formatDuration(_remaining)}'
                      : 'Waiting for Admin to release room details...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.w700,
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

/// Disqualified / Eliminated Card State
class _EliminatedCard extends StatelessWidget {
  const _EliminatedCard({required this.userContext});

  final UserMatchContext userContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '❌ ELIMINATED FROM TOURNAMENT',
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your team is eliminated from ${userContext.roundName}. Wild Card entry will open soon. Keep an eye out!',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Qualified Card State (Waiting for Next Round Group Assignment)
class _QualifiedCard extends StatelessWidget {
  const _QualifiedCard({required this.userContext});

  final UserMatchContext userContext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryNeon.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryNeon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: AppColors.primaryNeon,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userContext.qualificationStatus.badgeLabel,
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNeon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Congratulations ${userContext.teamName}! Waiting for organizer to assign next round groups and publish room details.',
                  style: AppTextStyles.bodySm.copyWith(
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

/// Unregistered Banner State
class _NotRegisteredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Details Locked',
                  style: AppTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Register for this tournament to participate and get your team\'s room ID & password.',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.textMuted,
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

/// Status Badge Pill
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TeamRoundStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TeamRoundStatus.live => const Color(0xFFFF3B30),
      TeamRoundStatus.completed => const Color(0xFF34C759),
      TeamRoundStatus.qualified => AppColors.primaryNeon,
      TeamRoundStatus.disqualified => AppColors.error,
      TeamRoundStatus.upcoming => AppColors.accentOrange,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 9.5,
        ),
      ),
    );
  }
}

/// ============================================================
/// 2. ROUND SECTION CARD: Groups & Matches Timeline History
/// ============================================================

class _RoundSectionCard extends StatelessWidget {
  const _RoundSectionCard({
    required this.round,
    required this.userTeamId,
  });

  final RoundModel round;
  final String userTeamId;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          round.roundName.toUpperCase(),
          style: AppTextStyles.headingMd.copyWith(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${round.groups.length} ${round.groups.length == 1 ? 'Group / Match' : 'Groups / Matches'}',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        ),
        iconColor: AppColors.accentOrange,
        collapsedIconColor: AppColors.textMuted,
        children: round.groups.map((group) {
          final isMyGroup = group.teams.any((t) => t.isMyTeam || t.id == userTeamId);

          return _GroupItemCard(
            group: group,
            isMyGroup: isMyGroup,
          );
        }).toList(),
      ),
    );
  }
}

class _GroupItemCard extends StatelessWidget {
  const _GroupItemCard({
    required this.group,
    required this.isMyGroup,
  });

  final GroupModel group;
  final bool isMyGroup;

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMyGroup
            ? AppColors.bgNavy
            : AppColors.surfaceMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMyGroup
              ? AppColors.primaryNeon.withValues(alpha: 0.4)
              : AppColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                group.groupName,
                style: AppTextStyles.headingMd.copyWith(
                  fontSize: 14,
                  color: isMyGroup ? AppColors.primaryNeon : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  group.map,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(group.startsAt),
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Participating Teams Badges
          if (group.teams.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: group.teams.map((t) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.isMyTeam
                        ? AppColors.primaryNeon.withValues(alpha: 0.2)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: t.isMyTeam
                          ? AppColors.primaryNeon
                          : AppColors.borderSubtle,
                    ),
                  ),
                  child: Text(
                    t.name,
                    style: AppTextStyles.caption.copyWith(
                      color: t.isMyTeam ? AppColors.primaryNeon : Colors.white,
                      fontWeight:
                          t.isMyTeam ? FontWeight.bold : FontWeight.normal,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Non-group Spectator Button or Completed Results
          if (!isMyGroup) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.remove_red_eye_rounded,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  'Spectate match via live stream',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],

          if (group.isCompleted &&
              (group.winnerTeamName != null || group.topMvpName != null)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (group.winnerTeamName != null) ...[
                  const Icon(Icons.emoji_events_rounded,
                      size: 13, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    'Winner: ${group.winnerTeamName}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
                if (group.topMvpName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.local_fire_department_rounded,
                      size: 13, color: AppColors.accentOrange),
                  const SizedBox(width: 4),
                  Text(
                    'MVP: ${group.topMvpName}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// ============================================================
/// SHIMMER LOADING STATE
/// ============================================================

class _MatchesShimmerState extends StatelessWidget {
  const _MatchesShimmerState();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceMuted,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// ============================================================
/// EMPTY STATE
/// ============================================================

class _MatchesEmptyState extends StatelessWidget {
  const _MatchesEmptyState({
    required this.isRegistered,
    required this.onRefresh,
  });

  final bool isRegistered;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.sports_esports_rounded,
                size: 40,
                color: AppColors.accentOrange,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Matches Scheduled Yet',
              style: AppTextStyles.headingMd,
            ),
            const SizedBox(height: 6),
            Text(
              isRegistered
                  ? 'Round groups and your team\'s room details will appear here as soon as the admin publishes them.'
                  : 'Register for this tournament to view your team\'s group room details.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// ERROR STATE
/// ============================================================

class _MatchesErrorState extends StatelessWidget {
  const _MatchesErrorState({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.primary,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              "Couldn't load matches",
              style: AppTextStyles.headingMd,
            ),
            const SizedBox(height: 6),
            Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
