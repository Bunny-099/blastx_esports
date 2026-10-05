import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/challenges/data/models/challenge_model.dart';
import 'package:blastix_esports/features/challenges/data/repositories/challenges_repository.dart';
import 'package:blastix_esports/features/challenges/data/services/screen_recording_service.dart';
import 'package:blastix_esports/features/challenges/presentation/widgets/active_recording_overlay.dart';
import 'package:blastix_esports/features/challenges/providers/challenges_provider.dart';

class FakeRealTimeSyncManager implements RealTimeSyncManager {
  @override
  void register({
    required String key,
    required Future<dynamic> Function() fetcher,
    required void Function(dynamic data) onChanged,
    bool runImmediately = false,
  }) {}

  @override
  void unregister(String key) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeChallengesRepository implements ChallengesRepository {
  bool uploadShouldFail = false;
  bool uploadCalled = false;
  int uploadCallCount = 0;
  String? lastUploadedChallengeId;
  File? lastUploadedFile;

  @override
  Future<List<ChallengeModel>> getChallenges() async => [
        ChallengeModel(
          id: 'tourney_101',
          title: 'BlastX Grand Tournament',
          description: 'Match Recording Challenge',
          rewardXP: 500,
          currentProgress: 0,
          targetProgress: 1,
          type: ChallengeType.special,
        ),
      ];

  @override
  Future<ChallengeModel> claimChallenge(String challengeId) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> uploadProofAndDeleteLocal({
    required String challengeId,
    required File videoFile,
  }) async {
    uploadCalled = true;
    uploadCallCount++;
    lastUploadedChallengeId = challengeId;
    lastUploadedFile = videoFile;

    if (uploadShouldFail) {
      throw Exception('Network upload failed (503 Service Unavailable)');
    }

    if (await videoFile.exists()) {
      try {
        await videoFile.delete();
      } catch (_) {}
    }
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late ScreenRecordingService recordingService;
  late FakeChallengesRepository fakeChallengesRepo;
  late FakeRealTimeSyncManager fakeSyncManager;

  setUp(() {
    RealTimeSyncManager.isTestMode = true;

    recordingService = ScreenRecordingService()
      ..testMode = true
      ..mockPermissionGranted = true
      ..stopDelayMs = 0;

    fakeChallengesRepo = FakeChallengesRepository();
    fakeSyncManager = FakeRealTimeSyncManager();
  });

  group('Active Recording Overlay & Upload Tests', () {
    testWidgets('Stop & Upload stops recording and uploads video proof', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('overlay_upload_test_');
      final tempFile = File('${tempDir.path}/valid.mp4');
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(List.filled(150 * 1024, 0)); // 150 KB
      recordingService.mockRecordedFile = tempFile;

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            screenRecordingServiceProvider.overrideWithValue(recordingService),
            challengesRepositoryProvider.overrideWithValue(fakeChallengesRepo),
            challengesProvider.overrideWith((ref) => ChallengesNotifier(fakeChallengesRepo, fakeSyncManager)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  return const ActiveRecordingOverlay();
                },
              ),
            ),
          ),
        ),
      );

      capturedRef.read(activeRecordingChallengeIdProvider.notifier).state = 'tourney_101';
      await recordingService.startRecording(challengeId: 'tourney_101');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('STOP & UPLOAD'), findsOneWidget);

      await tester.tap(find.text('STOP & UPLOAD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify repository upload was invoked
      expect(fakeChallengesRepo.uploadCalled, isTrue);
      expect(fakeChallengesRepo.lastUploadedChallengeId, equals('tourney_101'));

      // Verify active recording state is cleared
      expect(capturedRef.read(activeRecordingChallengeIdProvider), isNull);

      // Verify success snackbar
      expect(find.textContaining('Match recording uploaded successfully!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
