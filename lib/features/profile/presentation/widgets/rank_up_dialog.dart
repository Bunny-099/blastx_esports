import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/rank_model.dart';

/// Animated Dialog shown when a player advances to a new Rank.
class RankUpDialog extends StatelessWidget {
  final RankTier previousRank;
  final RankTier currentRank;

  const RankUpDialog({
    super.key,
    required this.previousRank,
    required this.currentRank,
  });

  static Future<void> show(
    BuildContext context, {
    required RankTier previousRank,
    required RankTier currentRank,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RankUpDialog(
        previousRank: previousRank,
        currentRank: currentRank,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primaryNeon,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNeon.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Trophy/Celebration Icon
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [
                    AppColors.primaryNeon,
                    AppColors.glowSoft,
                    AppColors.gold,
                    AppColors.primaryNeon,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.6),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.bgNavy,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentRank.icon,
                  size: 48,
                  color: AppColors.primaryNeon,
                ),
              ),
            )
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut)
                .shimmer(delay: 500.ms, duration: 1000.ms),

            const SizedBox(height: 20),

            // Banner Text
            Text(
              '🎉 RANK UP!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 8),

            Text(
              'You reached Rank ${currentRank.number}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            // Main Rank Badge & Name Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryNeon.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    currentRank.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNeon,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rank ${currentRank.number} / 14',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ).animate().scale(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNeon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.primaryNeon.withValues(alpha: 0.5),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'CONTINUE',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bgNavy,
                    letterSpacing: 1.0,
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
