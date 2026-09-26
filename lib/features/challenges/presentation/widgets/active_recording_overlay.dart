import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/challenges_provider.dart';

class ActiveRecordingOverlay extends ConsumerStatefulWidget {
  const ActiveRecordingOverlay({super.key});

  @override
  ConsumerState<ActiveRecordingOverlay> createState() => _ActiveRecordingOverlayState();
}

class _ActiveRecordingOverlayState extends ConsumerState<ActiveRecordingOverlay> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() => _seconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _handleStopAndUpload(String challengeId) async {
    final recordingService = ref.read(screenRecordingServiceProvider);
    final repository = ref.read(challengesRepositoryProvider);

    ref.read(isUploadingProofProvider.notifier).state = true;

    try {
      // 1. Stop Recording
      final File? recordedFile = await recordingService.stopRecording();

      if (recordedFile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('No recording file found.'),
            ),
          );
        }
        return;
      }

      // Show Uploading SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.surfaceNavy,
            content: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNeon),
                ),
                SizedBox(width: 12),
                Text('Uploading 480p match recording to server...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // 2. Upload to Server & Automatically Delete Local File
      await repository.uploadProofAndDeleteLocal(
        challengeId: challengeId,
        videoFile: recordedFile,
      );

      // 3. Update Challenge State
      ref.read(challengesProvider.notifier).markProofSubmitted(challengeId);
      ref.read(activeRecordingChallengeIdProvider.notifier).state = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Match recording uploaded successfully! Temp video auto-deleted from local storage.',
                    style: AppTextStyles.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Upload proof error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Upload error: $e'),
          ),
        );
      }
    } finally {
      ref.read(isUploadingProofProvider.notifier).state = false;
      recordingService.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeChallengeId = ref.watch(activeRecordingChallengeIdProvider);
    final isUploading = ref.watch(isUploadingProofProvider);

    if (activeChallengeId == null && !isUploading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy.withValues(alpha: 0.95),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Blinking REC Indicator
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.redAccent,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 800.ms)
           .fade(begin: 0.4, end: 1.0),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'MATCH RECORDING (480P)',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_seconds),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Temporary local file • Auto-deletes upon upload',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action Button
          if (isUploading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNeon),
            )
          else
            GestureDetector(
              onTap: activeChallengeId != null ? () => _handleStopAndUpload(activeChallengeId) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.cyanIceGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryNeon.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload_rounded, color: AppColors.bgNavy, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'STOP & UPLOAD',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.bgNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
