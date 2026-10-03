import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/challenge_model.dart';
import 'challenge_launch_dialog.dart';

class ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback? onClaim;
  final VoidCallback? onStopAndUpload;

  const ChallengeCard({
    super.key,
    required this.challenge,
    this.onClaim,
    this.onStopAndUpload,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRecording = challenge.status == 'RECORDING';
    final bool isProofSubmitted = challenge.isProofSubmitted;
    final bool isProofRejected = challenge.isProofRejected;
    final bool isReadyToClaim = challenge.isReadyToClaim;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRecording || isProofRejected
              ? Colors.redAccent.withValues(alpha: 0.8)
              : isProofSubmitted
                  ? AppColors.warning.withValues(alpha: 0.6)
                  : isReadyToClaim
                      ? AppColors.primaryNeon.withValues(alpha: 0.6)
                      : AppColors.borderSubtle,
          width: isRecording || isProofRejected || isProofSubmitted || isReadyToClaim ? 1.5 : 1.0,
        ),
        gradient: AppColors.glassFill,
        boxShadow: [
          if (isRecording || isProofRejected)
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            )
          else if (isReadyToClaim)
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
                          color: isRecording || isProofRejected
                              ? Colors.redAccent
                              : isProofSubmitted
                                  ? AppColors.warning
                                  : isReadyToClaim
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
                                Expanded(
                                  child: Text(
                                    isProofSubmitted
                                        ? 'Under Review'
                                        : isProofRejected
                                            ? 'Proof Rejected'
                                            : isRecording
                                                ? 'Recording Match...'
                                                : isReadyToClaim
                                                    ? 'Completed'
                                                    : 'Progress',
                                    style: AppTextStyles.caption.copyWith(
                                      color: isRecording || isProofRejected
                                          ? Colors.redAccent
                                          : isProofSubmitted
                                              ? AppColors.warning
                                              : isReadyToClaim
                                                  ? AppColors.success
                                                  : AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
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
                              isRejected: isProofRejected,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        challenge: challenge,
                        onClaim: onClaim,
                        onStopAndUpload: onStopAndUpload,
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
  final bool isRejected;

  const _ProgressBar({
    required this.progress,
    this.isRecording = false,
    this.isRejected = false,
  });

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
              gradient: isRecording || isRejected
                  ? const LinearGradient(colors: [Colors.red, Colors.orangeAccent])
                  : AppColors.blastixCoreGradient,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: (isRecording || isRejected ? Colors.red : AppColors.primaryNeon)
                      .withValues(alpha: 0.4),
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
  final VoidCallback? onStopAndUpload;
  final VoidCallback? onGo;

  const _ActionButton({
    required this.challenge,
    this.onClaim,
    this.onStopAndUpload,
    this.onGo,
  });

  @override
  Widget build(BuildContext context) {
    if (challenge.isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 16),
            SizedBox(width: 4),
            Text(
              'CLAIMED',
              style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (challenge.isProofSubmitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 14),
            SizedBox(width: 4),
            Text(
              'UNDER REVIEW',
              style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (challenge.isProofRejected) {
      return GestureDetector(
        onTap: onGo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.redAccent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withValues(alpha: 0.2),
                blurRadius: 6,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 16),
              SizedBox(width: 4),
              Text(
                'RETRY',
                style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (challenge.status == 'RECORDING') {
      return GestureDetector(
        onTap: onStopAndUpload,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.red, Colors.deepOrange]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                'STOP & UPLOAD',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    if (challenge.isReadyToClaim) {
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
          mainAxisSize: MainAxisSize.min,
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
