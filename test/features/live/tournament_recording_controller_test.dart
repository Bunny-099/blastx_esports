import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/features/challenges/data/services/game_launcher_service.dart';
import 'package:blastix_esports/features/challenges/data/services/screen_recording_service.dart';
import 'package:blastix_esports/features/live/providers/tournament_recording_provider.dart';
import 'package:blastix_esports/features/splash/data/models/app_config_model.dart';
import 'package:blastix_esports/features/splash/data/services/splash_api_service.dart';

class FakeScreenRecordingService extends ScreenRecordingService {
  bool startCalled = false;
  bool stopCalled = false;
  bool shouldFailStart = false;

  FakeScreenRecordingService() {
    testMode = true;
  }

  @override
  Future<bool> startMatchRecording({
    required String tournamentId,
    required String matchKey,
    required String clientRecordingId,
    int videoBitrateKbps = 2500,
    int maxHeight = 720,
    int fps = 30,
    int maxDurationMinutes = 60,
    int minFreeSpaceMb = 1500,
  }) async {
    startCalled = true;
    if (shouldFailStart) return false;
    return true;
  }

  @override
  Future<File?> stopRecording() async {
    stopCalled = true;
    final temp = Directory.systemTemp;
    final file = File('${temp.path}/test_match_recording.mp4');
    await file.writeAsString('test video data chunk');
    return file;
  }
}

class FakeGameLauncherService extends GameLauncherService {
  bool installed = true;
  bool launchCalled = false;

  @override
  Future<String?> getInstalledPackageName({String? preferredPackage}) async {
    return installed ? 'com.dts.freefireth' : null;
  }

  @override
  Future<bool> launchGame({String packageName = 'com.dts.freefireth'}) async {
    launchCalled = true;
    return true;
  }
}

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(StorageService(), DeviceInfoService());
}

class FakeSplashApiService extends SplashApiService {
  FakeSplashApiService() : super(FakeApiClient());

  @override
  Future<AppConfigModel> getAppConfig() async {
    return AppConfigModel(
      minVersion: '1.0.0',
      latestVersion: '1.0.0',
      isMaintenance: false,
      recording: const RecordingConfigModel(
        videoBitrateKbps: 2500,
        maxHeight: 720,
        fps: 30,
        maxDurationMinutes: 60,
        minFreeSpaceMb: 1500,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeScreenRecordingService recordingService;
  late FakeGameLauncherService gameLauncher;
  late FakeSplashApiService splashService;
  late TournamentRecordingController controller;

  setUp(() {
    recordingService = FakeScreenRecordingService();
    gameLauncher = FakeGameLauncherService();
    splashService = FakeSplashApiService();

    controller = TournamentRecordingController(
      recordingService: recordingService,
      gameLauncher: gameLauncher,
      splashApiService: splashService,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('Initial state is idle', () {
    expect(controller.state.status, TournamentRecordingStatus.idle);
    expect(controller.state.elapsedSeconds, 0);
  });

  test('startRecording sets notInstalled state when Free Fire is not installed', () async {
    gameLauncher.installed = false;

    await controller.startRecording(tournamentId: 't1', matchKey: 'm1');

    expect(controller.state.status, TournamentRecordingStatus.notInstalled);
    expect(recordingService.startCalled, false);
  });

  test('startRecording transitions to recording and launches game when permission granted', () async {
    await controller.startRecording(tournamentId: 't1', matchKey: 'm1');

    expect(recordingService.startCalled, true);
    expect(gameLauncher.launchCalled, true);
    expect(controller.state.status, TournamentRecordingStatus.recording);
    expect(controller.state.tournamentId, 't1');
    expect(controller.state.matchKey, 'm1');
    expect(controller.state.clientRecordingId, isNotNull);
  });

  test('stopRecording transitions to pendingUpload and stops recorder', () async {
    await controller.startRecording(tournamentId: 't1', matchKey: 'm1');
    final file = await controller.stopRecording();

    expect(recordingService.stopCalled, true);
    expect(controller.state.status, TournamentRecordingStatus.pendingUpload);
    expect(file, isNotNull);
  });

  test('setUploadingProgress, setUploaded, setFailed update state accurately', () {
    controller.setUploadingProgress(500, 1000);
    expect(controller.state.status, TournamentRecordingStatus.uploading);
    expect(controller.state.uploadProgress, 0.5);

    controller.setUploaded();
    expect(controller.state.status, TournamentRecordingStatus.uploaded);

    controller.setFailed('Network error');
    expect(controller.state.status, TournamentRecordingStatus.failed);
    expect(controller.state.errorMessage, 'Network error');
    expect(controller.state.canRetry, true);
  });
}
