import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/challenge_model.dart';
import 'challenge_launch_dialog.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onClaim;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRecording = challenge.status == 'RECORDING';
    final bool isProofSubmitted = challenge.status == 'PROOF_SUBMITTED' || challenge.status == 'UNDER_REVIEW';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecording
              ? Colors.redAccent.withValues(alpha: 0.8)
              : challenge.isCompleted
                  ? AppColors.primaryNeon.withValues(alpha: 0.6)
                  : AppColors.borderSubtle,
          width: isRecording || challenge.isCompleted ? 1.5 : 1.0,
        ),
        gradient: AppColors.glassFill,
        boxShadow: [
          if (isRecording)
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else if (challenge.isCompleted && !challenge.isClaimed)
            BoxShadow(
              color: AppColors.primaryNeon.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNavy,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Icon(
                          _getIconData(challenge.title),
                          color: isRecording
                              ? Colors.redAccent
                              : challenge.isCompleted
                                  ? AppColors.glowLight
                                  : AppColors.primaryNeon,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    challenge.title,
                                    style: AppTextStyles.headingMd,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                _GameBadge(game: challenge.game),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              challenge.description,
                              style: AppTextStyles.bodySm,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RewardBadge(xp: challenge.rewardXP),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Bottom Progress Bar & Action Button
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
                                  isProofSubmitted
                                      ? 'Proof Submitted'
                                      : isRecording
                                          ? 'Recording Match...'
                                          : challenge.isCompleted
                                              ? 'Completed'
                                              : 'Progress',
                                  style: AppTextStyles.caption.copyWith(
                                    color: isRecording
                                        ? Colors.redAccent
                                        : isProofSubmitted || challenge.isCompleted
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${challenge.currentProgress.toInt()} / ${challenge.targetProgress.toInt()}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _ProgressBar(
                              progress: challenge.progressPercentage,
                              isRecording: isRecording,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        challenge: challenge,
                        onClaim: onClaim,
                        onGo: () => ChallengeLaunchDialog.show(context, challenge),
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
    if (t.contains('kill') || t.contains('blood')) return Icons.gps_fixed;
    if (t.contains('win') || t.contains('booyah')) return Icons.emoji_events;
    if (t.contains('headshot')) return Icons.center_focus_strong;
    if (t.contains('survive')) return Icons.timer;
    if (t.contains('revive') || t.contains('support')) return Icons.medical_services;
    return Icons.sports_esports;
  }
}

class _GameBadge extends StatelessWidget {
  final String game;
  const _GameBadge({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Text(
        game,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primaryNeon,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final int xp;
  const _RewardBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.glowLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glowLight.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.glowLight, size: 15),
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
  final bool isRecording;

  const _ProgressBar({required this.progress, this.isRecording = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 7,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceNavy,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          widthFactor: progress > 0 ? progress : 0.05,
          child: Container(
            height: 7,
            decoration: BoxDecoration(
              gradient: isRecording
                  ? const LinearGradient(colors: [Colors.red, Colors.orangeAccent])
                  : AppColors.blastixCoreGradient,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: (isRecording ? Colors.red : AppColors.primaryNeon).withValues(alpha: 0.4),
                  blurRadius: 6,
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
  final ChallengeModel challenge;
  final VoidCallback? onClaim;
  final VoidCallback? onGo;

  const _ActionButton({
    required this.challenge,
    this.onClaim,
    this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    if (challenge.isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 18),
            SizedBox(width: 6),
            Text(
              'CLAIMED',
              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (challenge.status == 'PROOF_SUBMITTED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: const Text(
          'SUBMITTED',
          style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (challenge.status == 'RECORDING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
            SizedBox(width: 6),
            Text(
              'RECORDING',
              style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (challenge.isCompleted) {
      return GestureDetector(
        onTap: onClaim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            gradient: AppColors.cyanIceGradient,
            borderRadius: BorderRadius.circular(10),
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
            style: AppTextStyles.button.copyWith(
              color: AppColors.bgNavy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .shimmer(duration: 2.seconds, color: Colors.white24),
      );
    }

    return GestureDetector(
      onTap: onGo,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryNeon, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryNeon.withValues(alpha: 0.15),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.play_arrow_rounded, color: AppColors.primaryNeon, size: 18),
            const SizedBox(width: 4),
            Text(
              'GO',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primaryNeon,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
