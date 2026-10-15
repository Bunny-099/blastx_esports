import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/models/match_center_model.dart';
import '../data/models/room_credentials_model.dart';
import '../providers/matches_provider.dart';
import 'widgets/match_recording_section.dart';

/// ============================================================
/// MATCH DETAIL SCREEN
/// Individual Match Unit Details with Header, Room Card, Result Card,
/// and MatchRecordingSection.
/// Room credentials are fetched ONLY when screen is opened and room_state == PUBLISHED.
/// Credentials are NEVER cached on disk or logged.
/// ============================================================

class MatchDetailScreen extends ConsumerStatefulWidget {
  const MatchDetailScreen({
    super.key,
    required this.tournamentId,
    required this.matchKey,
    this.initialMatch,
    this.myAccess = MyAccess.none,
  });

  final String tournamentId;
  final String matchKey;
  final MatchCenterMatchItemModel? initialMatch;
  final MyAccess myAccess;

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _isPasswordVisible = false;

  void _copyToClipboard(String text, String label) {
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

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final param = MatchParam(tournamentId: widget.tournamentId, matchKey: widget.matchKey);
    final matchDetailAsync = ref.watch(matchDetailProvider(param));
    final matchCenterAsync = ref.watch(matchCenterProvider(widget.tournamentId));
    final credsAsync = ref.watch(matchRoomCredentialsProvider(param));

    // Determine myAccess level
    MyAccess myAccess = widget.myAccess;
    if (myAccess == MyAccess.none && matchCenterAsync.valueOrNull != null) {
      myAccess = matchCenterAsync.valueOrNull!.myAccess;
    }

    final match = matchDetailAsync.valueOrNull ?? widget.initialMatch;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match != null ? '${match.groupName} — Match #${match.matchNumber}' : 'MATCH DETAILS',
              style: AppTextStyles.headingLg,
            ),
            if (match != null)
              Text(
                'Map: ${match.map} • ${_formatTime(match.scheduledAt)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accentOrange,
        onRefresh: () async {
          ref.invalidate(matchDetailProvider(param));
          ref.invalidate(matchRoomCredentialsProvider(param));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. MATCH HEADER CARD
              if (match != null) _buildHeaderCard(match),

              const SizedBox(height: 20),

              // 2. ROOM CARD
              _buildRoomCardSection(match, myAccess, param),

              // 3. RESULT CARD (If Match Completed or myResult present)
              if (match != null && (match.status == MatchUnitStatus.completed || match.myResult != null)) ...[
                const SizedBox(height: 20),
                _buildResultCard(match),
              ],

              // 4. RECORDING SECTION (For Playing Members in Assigned Matches)
              if (match != null && myAccess.isPlaying && credsAsync.valueOrNull is! RoomCredentialsNotEligible)
                MatchRecordingSection(
                  tournamentId: widget.tournamentId,
                  matchKey: widget.matchKey,
                  myAccess: myAccess,
                  roomState: match.roomState,
                  backendRecordingStatus: match.recordingStatus,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER CARD ----------------
  Widget _buildHeaderCard(MatchCenterMatchItemModel match) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  'MATCH #${match.matchNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              _StatusChip(status: match.status),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            match.groupName,
            style: AppTextStyles.headingXl.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.map_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Map: ${match.map}',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                _formatTime(match.scheduledAt),
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- ROOM CARD SECTION ----------------
  Widget _buildRoomCardSection(MatchCenterMatchItemModel? match, MyAccess myAccess, MatchParam param) {
    if (match == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accentOrange),
        ),
      );
    }

    // State 1: NOT_ELIGIBLE or non-playing member
    if (match.roomState == RoomState.notEligible || myAccess != MyAccess.playing) {
      return _buildNotEligibleRoomCard(myAccess);
    }

    // State 2: HIDDEN (Countdown or "Room details will be published soon")
    if (match.roomState == RoomState.hidden) {
      return _buildHiddenRoomCard(match.roomRevealAt ?? match.scheduledAt.subtract(const Duration(minutes: 15)));
    }

    // State 3: PUBLISHED & PLAYING -> Fetch room credentials on-demand
    final credsAsync = ref.watch(matchRoomCredentialsProvider(param));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: credsAsync.when(
        data: (state) => switch (state) {
          RoomCredentialsAvailable(:final credentials) => _buildPublishedCredentialsView(credentials),
          RoomCredentialsNotYetAvailable(:final revealAt, :final message) =>
            _buildHiddenRoomCard(revealAt, customMessage: message),
          RoomCredentialsNotEligible(:final userMessage) => _buildCustomNotEligibleCard(userMessage),
          RoomCredentialsError(:final message) => _buildErrorCard(message, () {
              ref.invalidate(matchRoomCredentialsProvider(param));
            }),
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: CircularProgressIndicator(color: Color(0xFF00F0FF)),
          ),
        ),
        error: (err, _) => _buildErrorCard(err.toString(), () {
          ref.invalidate(matchRoomCredentialsProvider(param));
        }),
      ),
    );
  }

  // Published Credentials View with Copy Buttons
  Widget _buildPublishedCredentialsView(RoomCredentialsModel credentials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0x2600F0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key_rounded, color: Color(0xFF00F0FF), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ROOM CREDENTIALS',
                style: AppTextStyles.headingMd.copyWith(
                  color: const Color(0xFF00F0FF),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x2634C759),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF34C759)),
              ),
              child: Text(
                'PUBLISHED',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFF34C759),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: AppColors.border, height: 1),
        const SizedBox(height: 16),

        // Room ID
        _CredentialRow(
          label: 'ROOM ID',
          value: credentials.roomId,
          onCopy: () => _copyToClipboard(credentials.roomId, 'Room ID'),
        ),
        const SizedBox(height: 12),

        // Password
        _CredentialRow(
          label: 'ROOM PASSWORD',
          value: _isPasswordVisible ? credentials.roomPassword : '••••••••',
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          onCopy: () => _copyToClipboard(credentials.roomPassword, 'Password'),
        ),
      ],
    );
  }

  // Hidden / Countdown Room Card
  Widget _buildHiddenRoomCard(DateTime? revealAt, {String? customMessage}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock_rounded, color: AppColors.accentOrange, size: 36),
          const SizedBox(height: 12),
          Text(
            'ROOM DETAILS LOCKED',
            style: AppTextStyles.headingMd,
          ),
          const SizedBox(height: 6),
          Text(
            customMessage ?? 'Room details will be published soon.',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          if (revealAt != null) ...[
            const SizedBox(height: 12),
            _CountdownPill(revealAt: revealAt),
          ],
        ],
      ),
    );
  }

  // Not Eligible Room Card
  Widget _buildNotEligibleRoomCard(MyAccess myAccess) {
    final message = myAccess.isNonPlaying
        ? 'Only the Playing 4 get room details.'
        : 'Your team is not eligible to view room details for this match.';

    return _buildCustomNotEligibleCard(message);
  }

  Widget _buildCustomNotEligibleCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
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
            child: const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Access Note',
                  style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message, VoidCallback onRetry) {
    return Column(
      children: [
        Text(
          'Could not fetch room details: $message',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  // ---------------- RESULT CARD ----------------
  Widget _buildResultCard(MatchCenterMatchItemModel match) {
    final result = match.myResult;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'YOUR MATCH RESULT',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (result != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ResultStatBox(
                  label: 'PLACEMENT',
                  value: '#${result.placement}',
                  color: AppColors.gold,
                ),
                _ResultStatBox(
                  label: 'KILLS',
                  value: '${result.kills}',
                  color: AppColors.accentOrange,
                ),
                _ResultStatBox(
                  label: 'TOTAL POINTS',
                  value: '${result.totalPoints}',
                  color: AppColors.primaryNeon,
                ),
              ],
            ),
          ] else ...[
            Text(
              'Match Completed. Official result will be updated shortly.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MatchUnitStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MatchUnitStatus.scheduled => AppColors.accentOrange,
      MatchUnitStatus.live => AppColors.error,
      MatchUnitStatus.completed => AppColors.primaryNeon,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
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
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: isPassword && !isPasswordVisible ? 2.5 : 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (isPassword && onToggleVisibility != null)
            IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF00F0FF)),
                  const SizedBox(width: 4),
                  Text(
                    'COPY',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF00F0FF),
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

class _ResultStatBox extends StatelessWidget {
  const _ResultStatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headingLg.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CountdownPill extends StatefulWidget {
  const _CountdownPill({required this.revealAt});
  final DateTime revealAt;

  @override
  State<_CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<_CountdownPill> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final diff = widget.revealAt.difference(DateTime.now());
    if (diff.isNegative) {
      _remaining = Duration.zero;
      _timer?.cancel();
    } else {
      if (mounted) setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentOrange),
      ),
      child: Text(
        'Unlocks in ${_fmt(_remaining)}',
        style: const TextStyle(
          color: AppColors.accentOrange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
