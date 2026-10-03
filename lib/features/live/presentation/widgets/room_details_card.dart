import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/room_details_model.dart';
import '../../data/models/tournament_model.dart';
import '../../providers/live_provider.dart';

/// ============================================================
/// ROOM DETAILS CARD
/// Displays Free Fire custom room ID & Password securely
/// ============================================================

class RoomDetailsCard extends ConsumerStatefulWidget {
  const RoomDetailsCard({
    super.key,
    required this.tournament,
    required this.accentColor,
    this.viewOnly = false,
  });

  final TournamentModel tournament;
  final Color accentColor;
  final bool viewOnly;

  @override
  ConsumerState<RoomDetailsCard> createState() => _RoomDetailsCardState();
}

class _RoomDetailsCardState extends ConsumerState<RoomDetailsCard> {
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

  @override
  Widget build(BuildContext context) {
    // Hide room details card if in view-only mode or if tournament completed
    if (widget.viewOnly || widget.tournament.status == TournamentStatus.completed) {
      return const SizedBox.shrink();
    }

    final roomAsync = ref.watch(roomDetailsProvider(widget.tournament.id));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: roomAsync.when(
        data: (state) => switch (state) {
          RoomDetailsAvailable(:final roomDetails) => _buildAvailableView(roomDetails),
          RoomDetailsNotYetAvailable(:final revealAt) => _buildNotYetAvailableView(revealAt),
          RoomDetailsNotRegistered() => _buildNotRegisteredView(),
          RoomDetailsError(:final message) => _buildErrorView(message),
        },
        loading: () => _buildLoadingView(),
        error: (err, _) => _buildErrorView(err.toString()),
      ),
    );
  }

  // ---------------- AVAILABLE STATE UI ----------------
  Widget _buildAvailableView(RoomDetails details) {
    final accent = widget.accentColor;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.vpn_key_rounded, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room Details',
                        style: AppTextStyles.bodyLg
                            .copyWith(fontWeight: FontWeight.bold)),
                    Text('Join custom room in Free Fire',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x2634C759),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF34C759), width: 0.8),
                ),
                child: Text(
                  'READY',
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF34C759),
                    fontWeight: FontWeight.w800,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),

          // Room ID Row
          _CredentialRow(
            label: 'Room ID',
            valueWidget: Text(
              details.roomId,
              style: AppTextStyles.headingMd.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            onCopy: () => _copyToClipboard(details.roomId, 'Room ID'),
          ),
          const SizedBox(height: 12),

          // Password Row with Toggle
          _CredentialRow(
            label: 'Password',
            valueWidget: Text(
              _isPasswordVisible ? details.password : '••••••••',
              style: AppTextStyles.headingMd.copyWith(
                letterSpacing: _isPasswordVisible ? 1.0 : 2.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailingWidget: IconButton(
              icon: Icon(
                _isPasswordVisible
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
            ),
            onCopy: () => _copyToClipboard(details.password, 'Password'),
          ),
        ],
      ),
    );
  }

  // ---------------- NOT YET AVAILABLE STATE UI ----------------
  Widget _buildNotYetAvailableView(DateTime? revealAt) {
    return _CountdownLockView(
      revealAt: revealAt ?? widget.tournament.effectiveStartsAt.subtract(const Duration(minutes: 15)),
      accentColor: widget.accentColor,
      onCountdownEnded: () {
        ref.invalidate(roomDetailsProvider(widget.tournament.id));
      },
    );
  }

  // ---------------- NOT REGISTERED STATE UI ----------------
  Widget _buildNotRegisteredView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room Details Locked',
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Register for this tournament to get room details',
                    style: AppTextStyles.bodySm
                        .copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ERROR STATE UI ----------------
  Widget _buildErrorView(String message) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load room details',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
            onPressed: () {
              ref.invalidate(roomDetailsProvider(widget.tournament.id));
            },
          ),
        ],
      ),
    );
  }

  // ---------------- LOADING STATE UI ----------------
  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Text('Fetching room details...', style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

/// Helper Row Widget for Room ID and Password display with copy button
class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.valueWidget,
    this.trailingWidget,
    required this.onCopy,
  });

  final String label;
  final Widget valueWidget;
  final Widget? trailingWidget;
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
                valueWidget,
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget,
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
                    size: 16,
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

/// Countdown Timer Widget for Locked Room State
class _CountdownLockView extends StatefulWidget {
  const _CountdownLockView({
    required this.revealAt,
    required this.accentColor,
    required this.onCountdownEnded,
  });

  final DateTime revealAt;
  final Color accentColor;
  final VoidCallback onCountdownEnded;

  @override
  State<_CountdownLockView> createState() => _CountdownLockViewState();
}

class _CountdownLockViewState extends State<_CountdownLockView> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final diff = widget.revealAt.difference(DateTime.now());
    if (diff.isNegative || diff == Duration.zero) {
      _remaining = Duration.zero;
      _timer?.cancel();
      widget.onCountdownEnded();
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              color: AppColors.accentOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room Details Locked',
                    style: AppTextStyles.bodyLg
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Room opens in ${_formatDuration(_remaining)}',
                  style: AppTextStyles.bodySm.copyWith(
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
