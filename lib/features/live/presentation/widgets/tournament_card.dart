import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_model.dart';

/// ============================================================
/// TOURNAMENT CARD — Clean & Minimal Free Fire Esports Card
/// ============================================================
/// - Status Area:
///   - LIVE: small pulsing red dot + "LIVE" + viewer count
///   - UPCOMING: live minute countdown "Starts in 02h 14m" / "Starts in 14m"
///   - COMPLETED: muted "Ended" label
/// - Registration Chip: "Registered ✓" (green) or "Full" (muted)
/// - Thin Slots Progress Bar with "32/48 slots" (Orange < 90%, Red >= 90%)
/// - 0.97 Press-Scale tactile bounce & clean 18px border radius
/// ============================================================

class TournamentCard extends StatefulWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
    this.viewOnly = false,
  });

  final TournamentModel tournament;
  final VoidCallback onTap;
  final bool viewOnly;

  @override
  State<TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<TournamentCard> {
  double _scale = 1;

  Color get _accentColor {
    try {
      final hex = widget.tournament.accentColorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primaryNeon;
    }
  }

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.97);
  void _onTapCancel() => setState(() => _scale = 1);
  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    final tournament = widget.tournament;

    final mapDisplay = tournament.mapName.isNotEmpty ? tournament.mapName : 'Bermuda';
    final modeDisplay = tournament.mode.isNotEmpty ? tournament.mode : 'SQUAD';

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      onTapUp: _onTapUp,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accent.withValues(alpha: 0.22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              height: 188,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // -------- Banner image (Hero) --------
                  Hero(
                    tag: 'tournament-banner-${tournament.id}',
                    child: Image.network(
                      tournament.bannerImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppColors.surfaceElevated),
                    ),
                  ),

                  // -------- Soft gradient tint over banner --------
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          AppColors.background.withValues(alpha: 0.95),
                        ],
                        stops: const [0.10, 0.95],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // -------- Top Bar: Status Badge (Left) & Registration Chip (Right) --------
                  Positioned(
                    top: 12,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusBadge(tournament),
                        _buildTopRightBadges(tournament),
                      ],
                    ),
                  ),

                  // -------- Bottom Information Block --------
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tags Row: Mode, Map, Entry Fee
                        Row(
                          children: [
                            _TagPill(
                              label: modeDisplay,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                              borderColor: AppColors.primary.withValues(alpha: 0.35),
                              textColor: AppColors.primaryLight,
                              isBold: true,
                            ),
                            const SizedBox(width: 6),
                            _TagPill(
                              label: mapDisplay,
                              backgroundColor: AppColors.surfaceMuted,
                              textColor: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            _TagPill(
                              label: tournament.formattedEntryFee,
                              backgroundColor: tournament.isFree
                                  ? const Color(0x2234C759)
                                  : AppColors.surfaceNavy,
                              borderColor: tournament.isFree
                                  ? const Color(0xFF34C759).withValues(alpha: 0.4)
                                  : AppColors.borderSubtle,
                              textColor: tournament.isFree
                                  ? const Color(0xFF34C759)
                                  : AppColors.textSecondary,
                              isBold: tournament.isFree,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Hero(
                          tag: 'tournament-title-${tournament.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              tournament.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingMd.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Prize Pool & Viewing Info
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.goldGradient.createShader(bounds),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tournament.formattedPrizePool,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.glowLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Prize Pool',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Slots Progress Bar
                        _SlotsProgressBar(
                          tournament: tournament,
                          viewOnly: widget.viewOnly,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the top-left status badge according to tournament status
  Widget _buildStatusBadge(TournamentModel tournament) {
    if (tournament.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFF3B30).withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _LivePulseDot(),
            const SizedBox(width: 5),
            Text(
              'LIVE',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFFF3B30),
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '• ${tournament.formattedViewers} watching',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else if (tournament.status == TournamentStatus.upcoming) {
      return _UpcomingCountdownBadge(startTime: tournament.effectiveStartsAt);
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 0.8,
          ),
        ),
        child: Text(
          'Ended',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
          ),
        ),
      );
    }
  }

  /// Builds the top-right registration / capacity chip
  Widget _buildTopRightBadges(TournamentModel tournament) {
    if (widget.viewOnly) return const SizedBox.shrink();
    final isReg = tournament.effectiveIsRegistered;

    if (isReg) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0x2634C759),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF34C759).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF34C759),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              'Registered ✓',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFF34C759),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    } else if (tournament.isRegistrationOpen) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: const Color(0x2634C759),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF34C759).withValues(alpha: 0.6),
            width: 0.8,
          ),
        ),
        child: Text(
          'Registration Open',
          style: AppTextStyles.caption.copyWith(
            color: const Color(0xFF34C759),
            fontWeight: FontWeight.w800,
            fontSize: 10,
          ),
        ),
      );
    } else if (tournament.isRegistrationClosed || tournament.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 0.8,
          ),
        ),
        child: Text(
          tournament.isFull ? 'Full' : 'Registration Closed',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      );
    } else if (tournament.isRegistrationOpensSoon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accentOrange.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Text(
          'Opens Soon',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.accentOrange,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// ------------------------------------------------------------
/// Small Tag Pill Widget
/// ------------------------------------------------------------
class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.label,
    required this.backgroundColor,
    this.borderColor,
    required this.textColor,
    this.isBold = false,
  });

  final String label;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 0.8)
            : null,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontSize: 9.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Thin Slots Progress Bar Widget
/// ------------------------------------------------------------
class _SlotsProgressBar extends StatelessWidget {
  const _SlotsProgressBar({required this.tournament, this.viewOnly = false});

  final TournamentModel tournament;
  final bool viewOnly;

  @override
  Widget build(BuildContext context) {
    if (viewOnly) return const SizedBox.shrink();
    final progress = tournament.slotsProgress;
    final isCritical = progress >= 0.90;
    final fillColor = isCritical ? const Color(0xFFFF3B30) : AppColors.accentOrange;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tournament.slotsText,
              style: AppTextStyles.caption.copyWith(
                color: isCritical ? const Color(0xFFFF3B30) : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (tournament.isFull)
              Text(
                'FULL',
                style: AppTextStyles.caption.copyWith(
                  color: const Color(0xFFFF3B30),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(fillColor),
          ),
        ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// LIVE status small pulsing red dot widget
/// ------------------------------------------------------------
class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.35 + (_controller.value * 0.65),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B30),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

/// ------------------------------------------------------------
/// UPCOMING countdown badge widget with minute-interval Timer
/// ------------------------------------------------------------
class _UpcomingCountdownBadge extends StatefulWidget {
  const _UpcomingCountdownBadge({required this.startTime});

  final DateTime startTime;

  @override
  State<_UpcomingCountdownBadge> createState() => _UpcomingCountdownBadgeState();
}

class _UpcomingCountdownBadgeState extends State<_UpcomingCountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.inSeconds <= 0) {
      return 'Starting soon';
    }
    if (diff.inMinutes < 60) {
      return 'Starts in ${diff.inMinutes}m';
    }
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    return 'Starts in ${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: AppColors.accentOrange,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            _formatCountdown(widget.startTime),
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}
