import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/challenge_model.dart';
import '../../providers/challenges_provider.dart';

class ChallengeLaunchDialog extends ConsumerStatefulWidget {
  final ChallengeModel challenge;

  const ChallengeLaunchDialog({
    super.key,
    required this.challenge,
  });

  static Future<void> show(BuildContext context, ChallengeModel challenge) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChallengeLaunchDialog(challenge: challenge),
    );
  }

  @override
  ConsumerState<ChallengeLaunchDialog> createState() => _ChallengeLaunchDialogState();
}

class _ChallengeLaunchDialogState extends ConsumerState<ChallengeLaunchDialog> {
  bool _isCheckingGame = true;
  bool _isGameInstalled = false;
  bool _isStartingRecording = false;

  @override
  void initState() {
    super.initState();
    _checkGameInstallation();
  }

  Future<void> _checkGameInstallation() async {
    setState(() => _isCheckingGame = true);
    final gameLauncher = ref.read(gameLauncherServiceProvider);
    
    final installed = await gameLauncher.isGameInstalled(
      packageName: widget.challenge.gamePackage,
    );

    if (mounted) {
      setState(() {
        _isGameInstalled = installed;
        _isCheckingGame = false;
      });
    }
  }

  Future<void> _handleStartChallenge({bool force = false}) async {
    setState(() => _isStartingRecording = true);

    try {
      final recordingService = ref.read(screenRecordingServiceProvider);
      final gameLauncher = ref.read(gameLauncherServiceProvider);

      // 1. Try launching Free Fire game FIRST
      bool gameLaunched = await gameLauncher.launchGame(
        packageName: widget.challenge.gamePackage,
      );

      // Fallback: If launch returns false but force is true, attempt direct launch of freefiremax
      if (!gameLaunched && force) {
        gameLaunched = await gameLauncher.launchGame(
          packageName: 'com.dts.freefiremax',
        );
      }

      // 2. Start screen recording if game launched OR if forced launch
      if (gameLaunched || force) {
        final recordingStarted = await recordingService.startRecording(
          challengeId: widget.challenge.id,
        );

        if (recordingStarted) {
          ref.read(activeRecordingChallengeIdProvider.notifier).state = widget.challenge.id;
          ref.read(challengesProvider.notifier).updateChallengeStatus(
            widget.challenge.id,
            'RECORDING',
          );
        }

        if (mounted) {
          Navigator.of(context).pop(); // Close bottom sheet
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.primaryDeep,
              content: Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '480p Match Recording Started! Free Fire launched.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Could not launch Free Fire. Please install Free Fire MAX from Play Store.'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting challenge flow: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to start challenge: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingRecording = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.primaryNeon, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Title & XP Reward
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceNavy,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.sports_esports,
                  color: AppColors.primaryNeon,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challenge.title,
                      style: AppTextStyles.headingLg,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${widget.challenge.targetProgress.toInt()} in ${widget.challenge.game}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.glowLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.glowLight.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.glowLight, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '+${widget.challenge.rewardXP} XP',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.glowLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.borderSubtle),
          const SizedBox(height: 16),

          // Recording Guidelines / Rules
          Text(
            'CHALLENGE RULES & RECORDING PROOF',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryNeon,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _RuleTile(
            icon: Icons.videocam,
            text: 'Automatic 480p match recording will be activated upon launching Free Fire.',
          ),
          const SizedBox(height: 8),
          _RuleTile(
            icon: Icons.sd_card_alert,
            text: 'Video proof is saved in temporary local storage during the match.',
          ),
          const SizedBox(height: 8),
          _RuleTile(
            icon: Icons.cloud_upload,
            text: 'Upload recording after finishing your match to claim your XP reward.',
          ),
          const SizedBox(height: 8),
          _RuleTile(
            icon: Icons.delete_forever,
            text: 'Recording will be automatically deleted from your mobile device right after upload.',
          ),

          const SizedBox(height: 24),

          // Game Detection Status Box
          if (_isCheckingGame) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNeon),
                  ),
                  SizedBox(width: 14),
                  Text(
                    'Checking for Free Fire on device...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ] else ...[
            // GAME STATUS CARD
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isGameInstalled
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isGameInstalled
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isGameInstalled ? Icons.check_circle_outline : Icons.sports_esports_outlined,
                    color: _isGameInstalled ? AppColors.success : AppColors.primaryNeon,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isGameInstalled
                          ? 'Free Fire detected on device. Ready to record match at 480p.'
                          : 'Launch Free Fire MAX & Start 480p Recording.',
                      style: TextStyle(
                        color: _isGameInstalled ? AppColors.success : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!_isGameInstalled)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primaryNeon, size: 20),
                      tooltip: 'Re-check Game',
                      onPressed: _checkGameInstallation,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // MAIN START & LAUNCH BUTTON (Always active so user is never blocked!)
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _isStartingRecording ? null : () => _handleStartChallenge(force: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.fireGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNeon.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isStartingRecording)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else ...[
                        const Icon(Icons.fiber_manual_record, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'START 480P RECORDING & LAUNCH GAME',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // PLAY STORE LINK BUTTON
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(gameLauncherServiceProvider).openPlayStoreForFreeFire();
                },
                icon: const Icon(Icons.download, color: AppColors.textSecondary, size: 18),
                label: Text(
                  'GET FREE FIRE MAX FROM PLAY STORE',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.glowLight, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
