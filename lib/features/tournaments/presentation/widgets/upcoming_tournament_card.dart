git import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/live/data/models/tournament_model.dart';

/// ============================================================
/// UPCOMING TOURNAMENT CARD
/// ============================================================
/// Adapted from TournamentCard for upcoming events.
/// Maintains the asymmetric "Bullet Strike" silhouette.
/// ============================================================

class UpcomingTournamentCard extends StatelessWidget {
  const UpcomingTournamentCard({
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

  String get _formattedDate {
    return DateFormat('EEE, MMM d • hh:mm a').format(tournament.startTime);
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
              color: accent.withValues(alpha: 0.15),
              blurRadius: 28,
              spreadRadius: -5,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipPath(
          clipper: const BulletStrikeClipper(),
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
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xF2080A12),
                      ],
                      stops: [0.25, 1.0],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // =================================================
                // CUSTOM BORDER
                // =================================================
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: BulletStrikeBorderPainter(
                        color: accent,
                      ),
                    ),
                  ),
                ),

                // =================================================
                // DATE BADGE
                // =================================================
                Positioned(
                  top: 14,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 14,
                      right: 12,
                      top: 5,
                      bottom: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      _formattedDate.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
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
                            Icons.calendar_today_rounded,
                            color: Colors.white70,
                            size: 13,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            'Registration Open',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // =================================================
                      // ACCENT DECORATION
                      // =================================================
                      Row(
                        children: [
                          Container(
                            height: 3,
                            width: 62,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BulletStrikeClipper extends CustomClipper<Path> {
  const BulletStrikeClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(18, 0);
    path.lineTo(size.width - 38, 0);
    path.lineTo(size.width - 10, 18);
    path.lineTo(size.width - 10, 52);
    path.lineTo(size.width - 28, 70);
    path.lineTo(size.width - 18, 82);
    path.lineTo(size.width - 40, 104);
    path.lineTo(size.width - 20, 124);
    path.lineTo(size.width - 52, size.height);
    path.lineTo(18, size.height);
    path.lineTo(0, size.height - 16);
    path.lineTo(0, 18);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class BulletStrikeBorderPainter extends CustomPainter {
  const BulletStrikeBorderPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const BulletStrikeClipper().getClip(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.2),
          color.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BulletStrikeBorderPainter oldDelegate) => oldDelegate.color != color;
}
