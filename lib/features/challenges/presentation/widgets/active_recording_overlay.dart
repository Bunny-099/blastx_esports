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
    if (_seconds < 5) {
      final bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Recording Short (under 5s)',
            style: AppTextStyles.headingMd.copyWith(color: AppColors.warning),
          ),
          content: Text(
            'Recording duration is less than 5 seconds. Google Drive preview requires at least 8-10 seconds of video for online streaming.\n\nDo you want to continue recording or upload anyway?',
            style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Keep Recording', style: AppTextStyles.button.copyWith(color: AppColors.primaryNeon)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Upload Anyway', style: AppTextStyles.button.copyWith(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final recordingService = ref.read(screenRecordingServiceProvider);
    final repository = ref.read(challengesRepositoryProvider);

    // 1. Loading state on karein via Riverpod taaki user wait kare
    ref.read(isUploadingProofProvider.notifier).state = true;

    try {
      // 2. STOP RECORDING ko properly AWAIT karein
      File? uploadFile = await recordingService.stopRecording();

      if (uploadFile == null || !await uploadFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Screen recording file not found. Please record your match gameplay again.'),
            ),
          );
        }
        return;
      }

      // 3. File Size verify karein upload karne se pehle (Must be at least 100 KB)
      final int fileSize = await uploadFile.length();
      debugPrint('Final Video Size: $fileSize bytes');

      // Agar file 100 KB se choti hai
      if (fileSize < 100 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('Recording was too short or empty. Please record your match gameplay again.'),
              duration: Duration(seconds: 4),
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
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 4. Upload Real MP4 File to Server & Automatically Delete Local Temp File
      await repository.uploadProofAndDeleteLocal(
        challengeId: challengeId,
        videoFile: uploadFile,
      );

      // 5. Update Challenge State to PROOF_SUBMITTED
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
                    'Match recording uploaded successfully! Temp video auto-deleted.',
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
      debugPrint('Upload proof error: $e');
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
        border: Border.all(
          color: isUploading
              ? AppColors.primaryNeon.withValues(alpha: 0.8)
              : AppColors.primaryNeon.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isUploading ? AppColors.primaryNeon : Colors.red).withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Blinking REC or Cyan Uploading Indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUploading ? AppColors.primaryNeon : Colors.redAccent,
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
                    Flexible(
                      child: Text(
                        isUploading ? 'UPLOADING MATCH PROOF...' : 'MATCH RECORDING (480P)',
                        style: AppTextStyles.caption.copyWith(
                          color: isUploading ? AppColors.primaryNeon : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isUploading) ...[
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(_seconds),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isUploading
                      ? 'Finalizing video file & uploading to server...'
                      : 'Temporary local file • Auto-deletes upon upload',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Action Button / Uploading Indicator
          if (isUploading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryNeon.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNeon),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'UPLOADING...',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primaryNeon,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: activeChallengeId != null ? () => _handleStopAndUpload(activeChallengeId) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    const Icon(Icons.cloud_upload_rounded, color: AppColors.bgNavy, size: 15),
                    const SizedBox(width: 4),
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
