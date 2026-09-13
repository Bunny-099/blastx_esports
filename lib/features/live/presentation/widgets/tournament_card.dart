import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/tournament_model.dart';

/// ============================================================
/// TOURNAMENT CARD
/// ============================================================
/// Esports "Bullet Strike" card.
///
/// The silhouette is intentionally asymmetric:
/// - Left side = impact / entry point
/// - Top-right = projectile cut
/// - Bottom-right = stepped ballistic cut
/// - Angular border follows the exact same silhouette
/// ============================================================

class TournamentCardGradients {
  static const LinearGradient liveGradient = LinearGradient(
    colors: [
      AppColors.error,
      AppColors.warning,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardImageOverlay = LinearGradient(
    colors: [
      Colors.transparent,
      Color(0xF2080A12),
    ],
    stops: [0.25, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class TournamentCard extends StatelessWidget {
  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  final TournamentModel tournament;
  final VoidCallback onTap;

  Color get _accentColor {
    try {
      final hex = tournament.accentColorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.22),
              blurRadius: 28,
              spreadRadius: -5,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const _BulletStrikeClipper(),
          child: Container(
            height: 168,
            decoration: const BoxDecoration(
              color: AppColors.surface,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // =================================================
                // BACKGROUND IMAGE
                // =================================================
                Image.network(
                  tournament.bannerImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surfaceMuted,
                    );
                  },
                ),

                // =================================================
                // DARK IMAGE OVERLAY
                // =================================================
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: TournamentCardGradients.cardImageOverlay,
                  ),
                ),

                // =================================================
                // ACCENT GLOW / EDGE
                // =================================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BulletStrikeGlowPainter(
                        color: accent,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // CUSTOM BORDER
                // =================================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _BulletStrikeBorderPainter(
                        color: accent,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // LIVE BADGE
                // =================================================
                if (tournament.isLive)
                  const Positioned(
                    top: 14,
                    left: 0,
                    child: _LivePulseBadge(),
                  ),

                // =================================================
                // GAME BADGE
                // =================================================
                Positioned(
                  top: 14,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.75),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      tournament.game,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // TOURNAMENT INFORMATION
                // =================================================
                Positioned(
                  left: 22,
                  right: 26,
                  bottom: 17,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tournament.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            color: accent,
                            size: 15,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            tournament.formattedPrizePool,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Icon(
                            Icons.remove_red_eye_rounded,
                            color: Colors.white70,
                            size: 14,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            '${tournament.formattedViewers} watching',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // =================================================
                      // LASER / ENERGY LINE
                      // =================================================
                      Row(
                        children: [
                          Container(
                            height: 3,
                            width: 62,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.85),
                                  blurRadius: 7,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            height: 3,
                            width: 8,
                            color: accent.withValues(alpha: 0.45),
                          ),
                          const SizedBox(width: 3),
                          Container(
                            height: 3,
                            width: 4,
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // =================================================
                // BULLET IMPACT DETAIL
                // =================================================
                Positioned(
                  left: 0,
                  top: 55,
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: const Size(28, 52),
                      painter: _ImpactMarkPainter(
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// BULLET STRIKE CLIPPER
/// ============================================================
/// Creates the main asymmetric card silhouette.
///
/// Visual concept:
///
///       ________________________
///      /                       /
///     /                       /
///    |                       /
///    |                      /
///    |                    __/
///    |                  _/
///    |_________________/
///
/// The right side looks like the card has been "cut" by a
/// projectile / energy strike.
/// ============================================================

class _BulletStrikeClipper extends CustomClipper<Path> {
  const _BulletStrikeClipper();

  @override
  Path getClip(Size size) {
    final path = Path();

    // ------------------------------------------------------------
    // LEFT TOP
    // ------------------------------------------------------------

    path.moveTo(18, 0);

    // Top edge
    path.lineTo(size.width - 38, 0);

    // Projectile cut #1
    path.lineTo(size.width - 10, 18);

    // Right upper edge
    path.lineTo(size.width - 10, 52);

    // Projectile cut #2
    path.lineTo(size.width - 28, 70);

    // Right middle edge
    path.lineTo(size.width - 18, 82);

    // Projectile cut #3
    path.lineTo(size.width - 40, 104);

    // Lower right edge
    path.lineTo(size.width - 20, 124);

    // Final ballistic cut
    path.lineTo(size.width - 52, size.height);

    // Bottom
    path.lineTo(18, size.height);

    // Bottom-left angled impact
    path.lineTo(0, size.height - 16);

    // Left edge
    path.lineTo(0, 18);

    // Top-left angle
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

/// ============================================================
/// BORDER PAINTER
/// ============================================================

class _BulletStrikeBorderPainter extends CustomPainter {
  const _BulletStrikeBorderPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _BulletStrikeClipper().getClip(size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.miter
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
      covariant _BulletStrikeBorderPainter oldDelegate,
      ) {
    return oldDelegate.color != color;
  }
}

/// ============================================================
/// OUTER GLOW PAINTER
/// ============================================================

class _BulletStrikeGlowPainter extends CustomPainter {
  const _BulletStrikeGlowPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _BulletStrikeClipper().getClip(size);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        7,
      )
      ..color = color.withValues(alpha: 0.35);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
      covariant _BulletStrikeGlowPainter oldDelegate,
      ) {
    return oldDelegate.color != color;
  }
}

/// ============================================================
/// BULLET IMPACT MARK
/// ============================================================
/// Small accent "impact" detail on the left side.
/// ============================================================

class _ImpactMarkPainter extends CustomPainter {
  const _ImpactMarkPainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;

    // Main impact slash
    final main = Path()
      ..moveTo(2, 25)
      ..lineTo(18, 8)
      ..lineTo(25, 8);

    canvas.drawPath(main, paint);

    // Secondary slash
    final second = Path()
      ..moveTo(2, 39)
      ..lineTo(13, 28);

    canvas.drawPath(second, paint);

    // Tiny energy fragments
    final fragment = Path()
      ..moveTo(5, 49)
      ..lineTo(10, 44);

    canvas.drawPath(fragment, paint);
  }

  @override
  bool shouldRepaint(
      covariant _ImpactMarkPainter oldDelegate,
      ) {
    return oldDelegate.color != color;
  }
}

/// ============================================================
/// LIVE PULSE BADGE
/// ============================================================

class _LivePulseBadge extends StatefulWidget {
  const _LivePulseBadge();

  @override
  State<_LivePulseBadge> createState() => _LivePulseBadgeState();
}

class _LivePulseBadgeState extends State<_LivePulseBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(
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
        final glow = 0.4 + (_controller.value * 0.4);

        return Container(
          padding: const EdgeInsets.only(
            left: 14,
            right: 12,
            top: 5,
            bottom: 5,
          ),
          decoration: BoxDecoration(
            gradient: TournamentCardGradients.liveGradient,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(
                  alpha: glow,
                ),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: Colors.white,
                size: 8,
              ),
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