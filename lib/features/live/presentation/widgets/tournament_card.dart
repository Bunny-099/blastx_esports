import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/tournament_model.dart';

/// ============================================================
/// TOURNAMENT CARD — Free Fire Premium Glass Edition
/// ============================================================
/// - Thin gradient "neon edge" border (fire accent)
/// - Glass tint over the banner image
/// - Free Fire specific metadata badges (Map, Mode, Viewers)
/// - Tap-down scale bounce for tactile feedback
/// ============================================================

class TournamentCard extends StatefulWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  final TournamentModel tournament;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.all(1.2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: AppColors.glassBorder(accent),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.28),
                blurRadius: 30,
                spreadRadius: -6,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: SizedBox(
              height: 178,
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

                  // -------- Glass tint over image --------
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          AppColors.background.withValues(alpha: 0.94),
                        ],
                        stops: const [0.15, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // -------- Live badge --------
                  if (tournament.isLive)
                    const Positioned(
                      top: 14,
                      left: 14,
                      child: _LivePulseBadge(),
                    ),

                  // -------- Free Fire Game badge --------
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'FREE FIRE',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -------- Info block --------
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Map & Mode tags
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                modeDisplay,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primaryLight,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                mapDisplay,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 9.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Hero(
                          tag: 'tournament-title-${tournament.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              tournament.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingMd,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppColors.goldGradient.createShader(b),
                              child: const Icon(Icons.emoji_events_rounded,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tournament.formattedPrizePool,
                              style: AppTextStyles.bodySm.copyWith(
                                color: AppColors.glowLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.remove_red_eye_rounded,
                                color: Colors.white54, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              '${tournament.formattedViewers} watching',
                              style: AppTextStyles.bodySm,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 3,
                          width: 62,
                          decoration: BoxDecoration(
                            gradient: AppColors.fireGradient,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.7),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
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
}

/// ------------------------------------------------------------
/// LIVE pulse badge — soft breathing glow, neon core gradient fill
/// ------------------------------------------------------------

class _LivePulseBadge extends StatefulWidget {
  const _LivePulseBadge();

  @override
  State<_LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<_LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
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
        final glow = 0.35 + (_controller.value * 0.35);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: AppColors.fireGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: glow),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Colors.white, size: 7),
              SizedBox(width: 5),
              Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
