import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../live/data/models/tournament_model.dart';

class BlastIXTournamentCard extends StatelessWidget {
  const BlastIXTournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  final TournamentModel tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: (tournament.bannerImageUrl.isNotEmpty && tournament.bannerImageUrl.startsWith('http'))
                ? NetworkImage(tournament.bannerImageUrl)
                : const AssetImage('assets/images/top_banner.jpg') as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.9),
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Dynamic Top Status Badge
              _buildTopStatusBadge(tournament),
              const SizedBox(height: 8),
              Text(
                tournament.displayTitle,
                style: AppTextStyles.headingMd.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primaryNeon, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    tournament.formattedPrizePool,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.glowLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getButtonBgColor(tournament),
                      foregroundColor: _getButtonFgColor(tournament),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(80, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      tournament.actionButtonText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusBadge(TournamentModel t) {
    Color bg;
    String label;

    if (t.isLive) {
      bg = AppColors.primaryDeep;
      label = 'LIVE';
    } else if (t.effectiveIsRegistered) {
      bg = const Color(0x3334C759);
      label = 'REGISTERED ✓';
    } else if (t.isRegistrationOpen) {
      bg = const Color(0x3334C759);
      label = 'REGISTRATION OPEN';
    } else if (t.isRegistrationClosed) {
      bg = AppColors.surfaceElevated;
      label = 'REGISTRATION CLOSED';
    } else if (t.isRegistrationOpensSoon) {
      bg = AppColors.accentOrange.withValues(alpha: 0.3);
      label = 'OPENS SOON';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: t.isLive ? Colors.white : (t.isRegistrationOpen || t.effectiveIsRegistered ? const Color(0xFF34C759) : AppColors.textSecondary),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getButtonBgColor(TournamentModel t) {
    if (t.isLive) return AppColors.primaryNeon;
    if (t.effectiveIsRegistered || t.isRegistrationOpen) return const Color(0xFF34C759);
    if (t.isRegistrationClosed) return AppColors.surfaceElevated;
    return AppColors.primaryNeon;
  }

  Color _getButtonFgColor(TournamentModel t) {
    if (t.isLive) return AppColors.bgNavy;
    if (t.effectiveIsRegistered || t.isRegistrationOpen) return Colors.white;
    if (t.isRegistrationClosed) return AppColors.textMuted;
    return AppColors.bgNavy;
  }
}
