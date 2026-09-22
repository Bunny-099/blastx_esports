import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/challenge_model.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onClaim;
  final VoidCallback? onGo;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onClaim,
    this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        gradient: AppColors.glassFill,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background ambient glow if completed
            if (challenge.isCompleted && !challenge.isClaimed)
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryNeon.withValues(alpha: 0.15),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNavy,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Icon(
                          _getIconData(challenge.title),
                          color: challenge.isCompleted ? AppColors.glowLight : AppColors.primaryNeon,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.title,
                              style: AppTextStyles.headingMd,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              challenge.description,
                              style: AppTextStyles.bodySm,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RewardBadge(xp: challenge.rewardXP),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  challenge.isCompleted ? 'Completed' : 'Progress',
                                  style: AppTextStyles.caption.copyWith(
                                    color: challenge.isCompleted ? AppColors.success : AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${challenge.currentProgress.toInt()} / ${challenge.targetProgress.toInt()}',
                                  style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _ProgressBar(progress: challenge.progressPercentage),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        isCompleted: challenge.isCompleted,
                        isClaimed: challenge.isClaimed,
                        onClaim: onClaim,
                        onGo: onGo,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String title) {
    final t = title.toLowerCase();
    if (t.contains('kill')) return Icons.gps_fixed;
    if (t.contains('win') || t.contains('booyah')) return Icons.emoji_events;
    if (t.contains('headshot')) return Icons.ads_click;
    if (t.contains('survive')) return Icons.timer;
    if (t.contains('revive') || t.contains('support')) return Icons.medical_services;
    return Icons.flash_on;
  }
}

class _RewardBadge extends StatelessWidget {
  final int xp;
  const _RewardBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glowLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glowLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.glowLight, size: 14),
          const SizedBox(width: 4),
          Text(
            '+$xp XP',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.glowLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceNavy,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: AppColors.blastixCoreGradient,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryNeon.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final bool isCompleted;
  final bool isClaimed;
  final VoidCallback? onClaim;
  final VoidCallback? onGo;

  const _ActionButton({
    required this.isCompleted,
    required this.isClaimed,
    this.onClaim,
    this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    if (isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
      );
    }

    if (isCompleted) {
      return GestureDetector(
        onTap: onClaim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.cyanIceGradient,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.glowSoft.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            'CLAIM',
            style: AppTextStyles.button.copyWith(color: AppColors.bgNavy),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .shimmer(duration: 2.seconds, color: Colors.white24),
      );
    }

    return GestureDetector(
      onTap: onGo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryNeon),
        ),
        child: Text(
          'GO',
          style: AppTextStyles.button.copyWith(color: AppColors.primaryNeon),
        ),
      ),
    );
  }
}
