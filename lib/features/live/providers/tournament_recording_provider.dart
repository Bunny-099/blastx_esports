import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../challenges/data/services/game_launcher_service.dart';
import '../../challenges/data/services/screen_recording_service.dart';
import '../../challenges/providers/challenges_provider.dart';
import '../../splash/data/models/app_config_model.dart';
import '../../splash/data/services/splash_api_service.dart';
import '../../splash/providers/splash_providers.dart';

enum TournamentRecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  pendingUpload,
  uploading,
  uploaded,
  failed,
  notInstalled,
  permissionDenied,
  lowStorage,
}

class TournamentRecordingState {
  final TournamentRecordingStatus status;
  final String? tournamentId;
  final String? matchKey;
  final String? clientRecordingId;
  final File? recordedFile;
  final int elapsedSeconds;
  final int uploadedBytes;
  final int totalBytes;
  final String? errorMessage;
  final bool canRetry;

  const TournamentRecordingState({
    this.status = TournamentRecordingStatus.idle,
    this.tournamentId,
    this.matchKey,
    this.clientRecordingId,
    this.recordedFile,
    this.elapsedSeconds = 0,
    this.uploadedBytes = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.canRetry = false,
  });

  double get uploadProgress {
    if (totalBytes <= 0) return 0.0;
    return (uploadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  TournamentRecordingState copyWith({
    TournamentRecordingStatus? status,
    String? tournamentId,
    String? matchKey,
    String? clientRecordingId,
    File? recordedFile,
    int? elapsedSeconds,
    int? uploadedBytes,
    int? totalBytes,
    String? errorMessage,
    bool? canRetry,
  }) {
    return TournamentRecordingState(
      status: status ?? this.status,
      tournamentId: tournamentId ?? this.tournamentId,
      matchKey: matchKey ?? this.matchKey,
      clientRecordingId: clientRecordingId ?? this.clientRecordingId,
      recordedFile: recordedFile ?? this.recordedFile,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      uploadedBytes: uploadedBytes ?? this.uploadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      canRetry: canRetry ?? this.canRetry,
    );
  }
}

class TournamentRecordingController extends StateNotifier<TournamentRecordingState> {
  final ScreenRecordingService _recordingService;
  final GameLauncherService _gameLauncher;
  final SplashApiService _splashApiService;

  Timer? _recordingTimer;
  StreamSubscription? _eventSubscription;

  TournamentRecordingController({
    required ScreenRecordingService recordingService,
    required GameLauncherService gameLauncher,
    required SplashApiService splashApiService,
  })  : _recordingService = recordingService,
        _gameLauncher = gameLauncher,
        _splashApiService = splashApiService,
        super(const TournamentRecordingState()) {
    _listenToNativeEvents();
  }

  void _listenToNativeEvents() {
    _eventSubscription = _recordingService.recordingEvents.listen((event) {
      final type = event['event'] as String?;
      if (type == 'recordingStopped') {
        _handleNativeStopped(event['recording'] as Map<String, dynamic>?);
      } else if (type == 'recordingFailed') {
        _handleNativeFailed(event['errorCode'] as String?, event['reason'] as String?);
      }
    });
  }

  void _handleNativeStopped(Map<String, dynamic>? recMap) {
    _recordingTimer?.cancel();
    if (state.status == TournamentRecordingStatus.recording ||
        state.status == TournamentRecordingStatus.stopping) {
      final filePath = recMap?['file_path'] as String?;
      File? file;
      if (filePath != null && filePath.isNotEmpty) {
        file = File(filePath);
      }

      state = state.copyWith(
        status: TournamentRecordingStatus.pendingUpload,
        recordedFile: file ?? _recordingService.currentVideoFile,
      );
    }
  }

  void _handleNativeFailed(String? errorCode, String? reason) {
    _recordingTimer?.cancel();
    if (errorCode == 'LOW_STORAGE') {
      state = state.copyWith(
        status: TournamentRecordingStatus.lowStorage,
        errorMessage: reason ?? 'Storage space is below required limit.',
      );
    } else {
      state = state.copyWith(
        status: TournamentRecordingStatus.failed,
        errorMessage: reason ?? 'Screen recording failed to start.',
        canRetry: true,
      );
    }
  }

  Future<void> startRecording({
    required String tournamentId,
    required String matchKey,
  }) async {
    if (state.status == TournamentRecordingStatus.recording ||
        state.status == TournamentRecordingStatus.starting) {
      return;
    }

    state = state.copyWith(
      status: TournamentRecordingStatus.starting,
      tournamentId: tournamentId,
      matchKey: matchKey,
      errorMessage: null,
      elapsedSeconds: 0,
    );

    // 1. Check game installation
    final installedPkg = await _gameLauncher.getInstalledPackageName();
    if (installedPkg == null) {
      state = state.copyWith(status: TournamentRecordingStatus.notInstalled);
      return;
    }

    // 2. Fetch config options from /config/init (or fallback)
    RecordingConfigModel recConfig = const RecordingConfigModel();
    try {
      final appConfig = await _splashApiService.getAppConfig();
      recConfig = appConfig.recording;
    } catch (e) {
      debugPrint('Error fetching config for recording, using defaults: $e');
    }

    // 3. Generate client_recording_id
    final clientRecordingId = const Uuid().v4();

    // 4. Call native start recording
    try {
      final started = await _recordingService.startMatchRecording(
        tournamentId: tournamentId,
        matchKey: matchKey,
        clientRecordingId: clientRecordingId,
        videoBitrateKbps: recConfig.videoBitrateKbps,
        maxHeight: recConfig.maxHeight,
        fps: recConfig.fps,
        maxDurationMinutes: recConfig.maxDurationMinutes,
        minFreeSpaceMb: recConfig.minFreeSpaceMb,
      );

      if (started) {
        // State transitions to recording ONLY AFTER native confirms started
        state = state.copyWith(
          status: TournamentRecordingStatus.recording,
          clientRecordingId: clientRecordingId,
          elapsedSeconds: 0,
        );

        _startTimer();

        // 5. Launch Free Fire game
        await _gameLauncher.launchGame(packageName: installedPkg);
      } else {
        state = state.copyWith(
          status: TournamentRecordingStatus.permissionDenied,
          errorMessage: 'Screen recording permission required.',
        );
      }
    } catch (e) {
      debugPrint('startRecording exception: $e');
      if (e.toString().contains('LOW_STORAGE')) {
        state = state.copyWith(
          status: TournamentRecordingStatus.lowStorage,
          errorMessage: 'Storage space is below required limit.',
        );
      } else {
        state = state.copyWith(
          status: TournamentRecordingStatus.permissionDenied,
          errorMessage: 'Failed to start screen recording: $e',
        );
      }
    }
  }

  void _startTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TournamentRecordingStatus.recording) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      } else {
        _recordingTimer?.cancel();
      }
    });
  }

  Future<File?> stopRecording() async {
    if (state.status != TournamentRecordingStatus.recording) return null;

    _recordingTimer?.cancel();
    state = state.copyWith(status: TournamentRecordingStatus.stopping);

    try {
      final file = await _recordingService.stopRecording();
      state = state.copyWith(
        status: TournamentRecordingStatus.pendingUpload,
        recordedFile: file,
      );
      return file;
    } catch (e) {
      debugPrint('stopRecording error: $e');
      state = state.copyWith(
        status: TournamentRecordingStatus.failed,
        errorMessage: 'Failed to stop recording cleanly.',
        canRetry: true,
      );
      return null;
    }
  }

  void setPendingUpload(File file, {String? tournamentId, String? matchKey, String? clientRecordingId}) {
    state = state.copyWith(
      status: TournamentRecordingStatus.pendingUpload,
      recordedFile: file,
      tournamentId: tournamentId ?? state.tournamentId,
      matchKey: matchKey ?? state.matchKey,
      clientRecordingId: clientRecordingId ?? state.clientRecordingId,
    );
  }

  void setUploadingProgress(int uploadedBytes, int totalBytes) {
    state = state.copyWith(
      status: TournamentRecordingStatus.uploading,
      uploadedBytes: uploadedBytes,
      totalBytes: totalBytes,
    );
  }

  void setUploaded() {
    state = state.copyWith(
      status: TournamentRecordingStatus.uploaded,
      errorMessage: null,
    );
  }

  void setFailed(String error) {
    state = state.copyWith(
      status: TournamentRecordingStatus.failed,
      errorMessage: error,
      canRetry: true,
    );
  }

  void reset() {
    _recordingTimer?.cancel();
    _recordingService.reset();
    state = const TournamentRecordingState();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }
}

// Providers
final splashApiServiceProvider = Provider<SplashApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SplashApiService(apiClient);
});

final tournamentRecordingControllerProvider =
    StateNotifierProvider<TournamentRecordingController, TournamentRecordingState>((ref) {
  final recordingService = ref.watch(screenRecordingServiceProvider);
  final gameLauncher = ref.watch(gameLauncherServiceProvider);
  final splashApiService = ref.watch(splashApiServiceProvider);

  return TournamentRecordingController(
    recordingService: recordingService,
    gameLauncher: gameLauncher,
    splashApiService: splashApiService,
  );
});
