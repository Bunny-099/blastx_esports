import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blastix_esports/core/theme/app_colors.dart';
import 'package:blastix_esports/core/theme/app_text_styles.dart';
import 'package:blastix_esports/features/live/data/models/match_center_model.dart';
import 'package:blastix_esports/features/live/data/models/recording_job_model.dart';
import 'package:blastix_esports/features/live/providers/tournament_recording_provider.dart';
import 'package:blastix_esports/features/live/providers/uploader_provider.dart';

class MatchRecordingSection extends ConsumerStatefulWidget {
  const MatchRecordingSection({
    super.key,
    required this.tournamentId,
    required this.matchKey,
    required this.myAccess,
    required this.roomState,
    this.backendRecordingStatus,
  });

  final String tournamentId;
  final String matchKey;
  final MyAccess myAccess;
  final RoomState roomState;
  final String? backendRecordingStatus;

  @override
  ConsumerState<MatchRecordingSection> createState() => _MatchRecordingSectionState();
}

class _MatchRecordingSectionState extends ConsumerState<MatchRecordingSection> {

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _triggerUploadJob() async {
    final controllerState = ref.read(tournamentRecordingControllerProvider);
    final repo = ref.read(recordingJobsRepositoryProvider);
    final uploader = ref.read(resumableUploaderServiceProvider);

    if (repo == null || uploader == null) return;

    final job = repo.getJobForMatch(widget.tournamentId, widget.matchKey);
    if (job != null && !job.isCompleted) {
      ref.read(tournamentRecordingControllerProvider.notifier).setUploadingProgress(job.uploadedOffset, job.sizeBytes);

      uploader.uploadJob(
        job,
        onProgress: (uploaded, total) {
          if (mounted) {
            ref.read(tournamentRecordingControllerProvider.notifier).setUploadingProgress(uploaded, total);
          }
        },
        onCompleted: () {
          if (mounted) {
            ref.read(tournamentRecordingControllerProvider.notifier).setUploaded();
          }
        },
        onError: (err) {
          if (mounted) {
            ref.read(tournamentRecordingControllerProvider.notifier).setFailed(err);
          }
        },
      );
    } else if (controllerState.recordedFile != null) {
      final file = controllerState.recordedFile!;
      final fileSize = await file.length();
      final clientRecId = controllerState.clientRecordingId ?? 'rec_${DateTime.now().millisecondsSinceEpoch}';

      final nowIso = DateTime.now().toUtc().toIso8601String();
      final newJob = RecordingJobModel(
        clientRecordingId: clientRecId,
        tournamentId: widget.tournamentId,
        matchKey: widget.matchKey,
        filePath: file.path,
        sizeBytes: fileSize,
        durationSeconds: controllerState.elapsedSeconds > 0 ? controllerState.elapsedSeconds : 60,
        startedAt: nowIso,
        stoppedAt: nowIso,
      );

      await repo.saveJob(newJob);

      uploader.uploadJob(
        newJob,
        onProgress: (uploaded, total) {
          if (mounted) {
            ref.read(tournamentRecordingControllerProvider.notifier).setUploadingProgress(uploaded, total);
          }
        },
        onCompleted: () {
          if (mounted) {
            ref.read(tournamentRecordingControllerProvider.notifier).setUploaded();
          }
        },
        onError: (err) {
          if (mounted) {
            ref.read(tournamentRecordingControllerProvider.notifier).setFailed(err);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. NON-PLAYING MEMBERS SEE NOTHING
    if (widget.myAccess != MyAccess.playing) {
      return const SizedBox.shrink();
    }

    // 2. WATCH RECORDING CONTROLLER STATE
    final state = ref.watch(tournamentRecordingControllerProvider);
    final repo = ref.watch(recordingJobsRepositoryProvider);

    // If local controller is for a different match, check repository for job or show READY
    final isMatchingCurrentMatch =
        state.tournamentId == widget.tournamentId && state.matchKey == widget.matchKey;

    final localJob = repo?.getJobForMatch(widget.tournamentId, widget.matchKey);

    // Fallback status from backend if local state is idle and local job is absent
    final backendStatus = widget.backendRecordingStatus?.toUpperCase().trim();

    if (!isMatchingCurrentMatch && localJob != null) {
      if (localJob.isCompleted || backendStatus == 'UPLOADED') {
        return _buildUploadedCard();
      }
      if (localJob.isFailed) {
        return _buildFailedCard(localJob.lastErrorMessage ?? 'Upload failed.', () {
          _triggerUploadJob();
        });
      }
      if (localJob.status == 'uploading' || localJob.status == 'pending') {
        return _buildUploadingCard(
          uploadedBytes: localJob.uploadedOffset,
          totalBytes: localJob.sizeBytes,
        );
      }
    }

    if (backendStatus == 'UPLOADED' && (state.status == TournamentRecordingStatus.idle || !isMatchingCurrentMatch)) {
      return _buildUploadedCard();
    }

    // 3. RENDER BASED ON LOCAL CONTROLLER STATUS
    if (!isMatchingCurrentMatch && state.status != TournamentRecordingStatus.idle) {
      return _buildReadyButton();
    }

    switch (state.status) {
      case TournamentRecordingStatus.idle:
        if (widget.roomState != RoomState.published) {
          return const SizedBox.shrink();
        }
        return _buildReadyButton();

      case TournamentRecordingStatus.starting:
        return _buildDisabledButton('STARTING RECORDING & LAUNCHING GAME...');

      case TournamentRecordingStatus.recording:
        return _buildActiveRecordingCard(state.elapsedSeconds);

      case TournamentRecordingStatus.stopping:
        return _buildDisabledButton('STOPPING RECORDING...');

      case TournamentRecordingStatus.pendingUpload:
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerUploadJob();
        });
        return _buildPendingUploadCard();

      case TournamentRecordingStatus.uploading:
        return _buildUploadingCard(
          uploadedBytes: state.uploadedBytes,
          totalBytes: state.totalBytes,
        );

      case TournamentRecordingStatus.uploaded:
        return _buildUploadedCard();

      case TournamentRecordingStatus.failed:
        return _buildFailedCard(
          state.errorMessage ?? 'Upload failed.',
          () {
            _triggerUploadJob();
          },
        );

      case TournamentRecordingStatus.notInstalled:
        return _buildErrorBanner(
          icon: Icons.sports_esports_outlined,
          title: 'Free Fire Not Installed',
          message: 'Free Fire or Free Fire MAX is not installed on this device.',
          buttonText: 'TRY AGAIN',
          onTap: () {
            ref.read(tournamentRecordingControllerProvider.notifier).reset();
          },
        );

      case TournamentRecordingStatus.permissionDenied:
        return _buildErrorBanner(
          icon: Icons.security_rounded,
          title: 'Permission Required',
          message: state.errorMessage ?? 'Screen recording permission is required.',
          buttonText: 'RETRY PERMISSION',
          onTap: () {
            ref.read(tournamentRecordingControllerProvider.notifier).startRecording(
                  tournamentId: widget.tournamentId,
                  matchKey: widget.matchKey,
                );
          },
        );

      case TournamentRecordingStatus.lowStorage:
        return _buildErrorBanner(
          icon: Icons.sd_card_alert_rounded,
          title: 'Insufficient Disk Space',
          message: state.errorMessage ?? 'Free up at least 1.5 GB of disk space to record.',
          buttonText: 'RETRY',
          onTap: () {
            ref.read(tournamentRecordingControllerProvider.notifier).startRecording(
                  tournamentId: widget.tournamentId,
                  matchKey: widget.matchKey,
                );
          },
        );
    }
  }

  Widget _buildReadyButton() {
    if (widget.roomState != RoomState.published) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primaryNeon,
          foregroundColor: AppColors.bgNavy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          shadowColor: AppColors.primaryNeon.withValues(alpha: 0.5),
        ),
        onPressed: () {
          ref.read(tournamentRecordingControllerProvider.notifier).startRecording(
                tournamentId: widget.tournamentId,
                matchKey: widget.matchKey,
              );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_rounded, color: AppColors.bgNavy, size: 22),
            const SizedBox(width: 8),
            Text(
              'START RECORDING & OPEN GAME',
              style: AppTextStyles.button.copyWith(
                color: AppColors.bgNavy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledButton(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNeon),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRecordingCard(int seconds) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MATCH RECORDING ACTIVE',
                style: AppTextStyles.headingMd.copyWith(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(seconds),
                style: AppTextStyles.bodyLg.copyWith(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '💡 You can also stop recording from the ongoing notification while playing in Free Fire.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(tournamentRecordingControllerProvider.notifier).stopRecording();
              },
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(
                'STOP RECORDING',
                style: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingUploadCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryNeon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recording Saved', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  'Upload will start automatically in background.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingCard({required int uploadedBytes, required int totalBytes}) {
    final double pct = totalBytes > 0 ? (uploadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
    final int pctInt = (pct * 100).toInt();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryNeon.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_upload_rounded, color: AppColors.primaryNeon, size: 20),
              const SizedBox(width: 8),
              Text(
                'UPLOADING MATCH RECORDING',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.primaryNeon),
              ),
              const Spacer(),
              Text(
                '$pctInt%',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.primaryNeon),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: AppColors.bgNavy,
              color: AppColors.primaryNeon,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatSize(uploadedBytes)} / ${_formatSize(totalBytes)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1F34C759),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF34C759)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0x3334C759),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF34C759), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECORDING UPLOADED ✓',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: const Color(0xFF34C759),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your match gameplay proof has been successfully submitted.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedCard(String error, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
              const SizedBox(width: 8),
              Text(
                'UPLOAD FAILED',
                style: AppTextStyles.headingMd.copyWith(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            error,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'RETRY UPLOAD',
                style: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner({
    required IconData icon,
    required String title,
    required String message,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accentOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.headingMd.copyWith(color: AppColors.accentOrange),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceMuted,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onTap,
              child: Text(
                buttonText,
                style: AppTextStyles.button.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
