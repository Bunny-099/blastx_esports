import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/challenges/data/models/challenge_model.dart';
import 'package:blastix_esports/features/challenges/data/repositories/challenges_repository.dart';
import 'package:blastix_esports/features/challenges/data/services/game_launcher_service.dart';
import 'package:blastix_esports/features/challenges/data/services/screen_recording_service.dart';
import 'package:blastix_esports/features/challenges/presentation/widgets/active_recording_overlay.dart';
import 'package:blastix_esports/features/challenges/providers/challenges_provider.dart';
import 'package:blastix_esports/features/live/data/models/room_details_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/live/presentation/team/tournament_match_room_screen.dart';
import 'package:blastix_esports/features/live/presentation/widgets/room_details_card.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/tournaments/data/repositories/tournament_repository.dart';

// ============================================================
// FAKES & TEST DOUBLES FOR POST-REGISTRATION FLOW
// ============================================================

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

class FakeTournamentRepository implements TournamentRepository {
  RoomDetailsState roomDetailsState = const RoomDetailsNotRegistered();
  TournamentModel? tournament;
  List<TournamentTeamModel> teams = [];

  @override
  Future<RoomDetailsState> getRoomDetailsState(
    String tournamentId, {
    TournamentModel? tournament,
  }) async {
    return roomDetailsState;
  }

  @override
  Future<List<TournamentTeamModel>> getRegisteredTeams(String id) async {
    return teams;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late ScreenRecordingService recordingService;
  late GameLauncherService gameLauncherService;
  late FakeChallengesRepository fakeChallengesRepo;
  late FakeTournamentRepository fakeTournamentRepo;
  late FakeRealTimeSyncManager fakeSyncManager;
  late TournamentModel sampleLiveTournament;
  late TournamentModel sampleUpcomingTournament;

  setUp(() {
    RealTimeSyncManager.isTestMode = true;

    recordingService = ScreenRecordingService()
      ..testMode = true
      ..mockPermissionGranted = true
      ..stopDelayMs = 0;

    gameLauncherService = GameLauncherService()
      ..testMode = true
      ..mockInstalledPackage = GameLauncherService.freeFireMaxPackage
      ..mockLaunchSuccess = true;

    fakeChallengesRepo = FakeChallengesRepository();
    fakeTournamentRepo = FakeTournamentRepository();
    fakeSyncManager = FakeRealTimeSyncManager();

    sampleLiveTournament = TournamentModel(
      id: 'tourney_101',
      name: 'BlastX Grand Finals S4',
      game: 'Free Fire MAX',
      bannerImageUrl: '',
      gameLogoUrl: '',
      prizePool: 50000,
      viewersCount: 1200,
      status: TournamentStatus.live,
      startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      organizer: 'BlastX',
      isRegistered: true,
    );

    sampleUpcomingTournament = TournamentModel(
      id: 'tourney_102',
      name: 'BlastX Pro Invitational',
      game: 'Free Fire',
      bannerImageUrl: '',
      gameLogoUrl: '',
      prizePool: 25000,
      viewersCount: 300,
      status: TournamentStatus.upcoming,
      startTime: DateTime.now().add(const Duration(hours: 2)),
      organizer: 'BlastX',
      isRegistered: true,
    );
  });

  group('Post-Tournament-Registration Automated Test Suite', () {
    // ------------------------------------------------------------------------
    // Scenario 1: Room ID/Password hidden before the tournament is live
    // ------------------------------------------------------------------------
    testWidgets('Scenario 1: Room ID/Password hidden before tournament is live', (tester) async {
      fakeTournamentRepo.roomDetailsState = RoomDetailsNotYetAvailable(
        revealAt: DateTime.now().add(const Duration(minutes: 45)),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            tournamentRepositoryProvider.overrideWithValue(fakeTournamentRepo),
            roomDetailsProvider('tourney_102').overrideWith((ref) => fakeTournamentRepo.roomDetailsState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RoomDetailsCard(
                tournament: sampleUpcomingTournament,
                accentColor: Colors.purple,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Room Details Locked'), findsOneWidget);
      expect(find.textContaining('Room opens in'), findsOneWidget);
      expect(find.text('Room ID'), findsNothing);
      expect(find.text('8492041'), findsNothing);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 2: Room ID/Password visible after tournament goes live
    // ------------------------------------------------------------------------
    testWidgets('Scenario 2: Room ID/Password visible after tournament goes live', (tester) async {
      fakeTournamentRepo.roomDetailsState = RoomDetailsAvailable(
        RoomDetails(
          roomId: '8492041',
          password: 'FF2026',
          visibleFrom: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            tournamentRepositoryProvider.overrideWithValue(fakeTournamentRepo),
            roomDetailsProvider('tourney_101').overrideWith((ref) => fakeTournamentRepo.roomDetailsState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RoomDetailsCard(
                tournament: sampleLiveTournament,
                accentColor: Colors.cyan,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Room Details'), findsOneWidget);
      expect(find.text('Room ID'), findsOneWidget);
      expect(find.text('8492041'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('••••••••'), findsOneWidget);

      // Toggle password visibility
      await tester.tap(find.byIcon(Icons.visibility_rounded));
      await tester.pump();

      expect(find.text('FF2026'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 3: Copy Room ID and copy Password work (verify via Clipboard)
    // ------------------------------------------------------------------------
    testWidgets('Scenario 3: Copy Room ID and copy Password work', (tester) async {
      fakeTournamentRepo.roomDetailsState = RoomDetailsAvailable(
        RoomDetails(
          roomId: '8492041',
          password: 'FF2026',
          visibleFrom: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      final List<MethodCall> log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          if (methodCall.method == 'Clipboard.setData') {
            return null;
          }
          return null;
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            tournamentRepositoryProvider.overrideWithValue(fakeTournamentRepo),
            roomDetailsProvider('tourney_101').overrideWith((ref) => fakeTournamentRepo.roomDetailsState),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RoomDetailsCard(
                tournament: sampleLiveTournament,
                accentColor: Colors.cyan,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Copy Room ID
      await tester.tap(find.text('COPY').first);
      await tester.pump();

      expect(find.text('Room ID copied to clipboard!'), findsOneWidget);
      expect(log.any((call) => call.method == 'Clipboard.setData' && call.arguments['text'] == '8492041'), isTrue);

      // Tap Copy Password
      await tester.tap(find.text('COPY').last);
      await tester.pump();

      expect(find.text('Password copied to clipboard!'), findsOneWidget);
      expect(log.any((call) => call.method == 'Clipboard.setData' && call.arguments['text'] == 'FF2026'), isTrue);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 4 & 5: Start & Record triggers recording start & Free Fire launch
    // ------------------------------------------------------------------------
    testWidgets('Scenario 4 & 5: Start & Record triggers recording start & Free Fire launch', (tester) async {
      fakeTournamentRepo.roomDetailsState = RoomDetailsAvailable(
        RoomDetails(
          roomId: '8492041',
          password: 'FF2026',
          visibleFrom: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            screenRecordingServiceProvider.overrideWithValue(recordingService),
            gameLauncherServiceProvider.overrideWithValue(gameLauncherService),
            tournamentRepositoryProvider.overrideWithValue(fakeTournamentRepo),
            appTournamentsProvider.overrideWith((ref) => [sampleLiveTournament]),
            roomDetailsProvider('tourney_101').overrideWith((ref) => fakeTournamentRepo.roomDetailsState),
            registeredTeamsProvider('tourney_101').overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const TournamentMatchRoomScreen(tournamentId: 'tourney_101');
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('START MATCH & RECORDING'), findsOneWidget);

      await tester.tap(find.text('START MATCH & RECORDING'));
      await tester.pump();
      await tester.pump();

      // Verify active recording state is set
      expect(capturedRef.read(activeRecordingChallengeIdProvider), equals('tourney_101'));
      expect(recordingService.isRecording, isTrue);

      // Verify SnackBar feedback
      expect(find.textContaining('480p Screen Recording Active! Launching Free Fire...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 6: Permissions denied -> proper guidance/error message shown
    // ------------------------------------------------------------------------
    testWidgets('Scenario 6: Permissions denied -> proper guidance/error message shown', (tester) async {
      fakeTournamentRepo.roomDetailsState = RoomDetailsAvailable(
        RoomDetails(
          roomId: '8492041',
          password: 'FF2026',
          visibleFrom: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      recordingService.mockPermissionGranted = false; // Simulate user denying screen recording permission

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            screenRecordingServiceProvider.overrideWithValue(recordingService),
            gameLauncherServiceProvider.overrideWithValue(gameLauncherService),
            tournamentRepositoryProvider.overrideWithValue(fakeTournamentRepo),
            appTournamentsProvider.overrideWith((ref) => [sampleLiveTournament]),
            roomDetailsProvider('tourney_101').overrideWith((ref) => fakeTournamentRepo.roomDetailsState),
            registeredTeamsProvider('tourney_101').overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                capturedRef = ref;
                return const TournamentMatchRoomScreen(tournamentId: 'tourney_101');
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('START MATCH & RECORDING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify recording did not start and active challenge is null
      expect(recordingService.isRecording, isFalse);
      expect(capturedRef.read(activeRecordingChallengeIdProvider), isNull);

      // Verify error snackbar is shown
      expect(find.text('Screen recording permission required to record your tournament match.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 7: Returning from Free Fire -> "Stop & Upload" is visible
    // ------------------------------------------------------------------------
    testWidgets('Scenario 7: ActiveRecordingOverlay is visible while recording', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            activeRecordingChallengeIdProvider.overrideWith((ref) => 'tourney_101'),
            screenRecordingServiceProvider.overrideWithValue(recordingService),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ActiveRecordingOverlay(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MATCH RECORDING (480P)'), findsOneWidget);
      expect(find.text('STOP & UPLOAD'), findsOneWidget);
      expect(find.textContaining('Temporary local file'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 8: "Stop & Upload" -> recording stops -> upload success shown
    // ------------------------------------------------------------------------
    testWidgets('Scenario 8: Stop & Upload stops recording and uploads video proof', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('s8_upload_');
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

      // Verify repository upload was invoked with correct parameters
      expect(fakeChallengesRepo.uploadCalled, isTrue);
      expect(fakeChallengesRepo.lastUploadedChallengeId, equals('tourney_101'));

      // Verify active recording state is cleared
      expect(capturedRef.read(activeRecordingChallengeIdProvider), isNull);

      // Verify success snackbar
      expect(find.textContaining('Match recording uploaded successfully!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 9: Upload failure (network error) -> error shown with retry; retry works
    // ------------------------------------------------------------------------
    testWidgets('Scenario 9: Upload failure displays error and RETRY UPLOAD works', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('s9_upload_');
      final tempFile = File('${tempDir.path}/retry.mp4');
      await tempFile.create(recursive: true);
      await tempFile.writeAsBytes(List.filled(150 * 1024, 0));
      recordingService.mockRecordedFile = tempFile;

      fakeChallengesRepo.uploadShouldFail = true; // First attempt fails

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

      // 1st Attempt: Stop & Upload (Fails due to network error)
      await tester.tap(find.text('STOP & UPLOAD'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeChallengesRepo.uploadCalled, isTrue);
      expect(find.textContaining('Upload error'), findsOneWidget);

      // Verify RETRY UPLOAD button appears
      expect(find.text('RETRY UPLOAD'), findsOneWidget);

      // Fix network connection for retry
      fakeChallengesRepo.uploadShouldFail = false;

      // 2nd Attempt: Tap RETRY UPLOAD
      await tester.tap(find.text('RETRY UPLOAD'));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeChallengesRepo.uploadCallCount, equals(2));
      expect(capturedRef.read(activeRecordingChallengeIdProvider), isNull);
      expect(find.textContaining('Match recording uploaded successfully!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    // ------------------------------------------------------------------------
    // Scenario 10 Edge Cases:
    // A) Free Fire Not Installed -> Dialog shown & open play store option
    // B) Short Recording (<100 KB) -> Blocked with warning
    // ------------------------------------------------------------------------
    testWidgets('Scenario 10A Edge Case: Free Fire not installed shows warning dialog', (tester) async {
      gameLauncherService.mockInstalledPackage = null; // Neither Free Fire nor Free Fire MAX installed

      fakeTournamentRepo.roomDetailsState = RoomDetailsAvailable(
        RoomDetails(
          roomId: '8492041',
          password: 'FF2026',
          visibleFrom: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            screenRecordingServiceProvider.overrideWithValue(recordingService),
            gameLauncherServiceProvider.overrideWithValue(gameLauncherService),
            tournamentRepositoryProvider.overrideWithValue(fakeTournamentRepo),
            appTournamentsProvider.overrideWith((ref) => [sampleLiveTournament]),
            roomDetailsProvider('tourney_101').overrideWith((ref) => fakeTournamentRepo.roomDetailsState),
            registeredTeamsProvider('tourney_101').overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: TournamentMatchRoomScreen(tournamentId: 'tourney_101'),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('START MATCH & RECORDING'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify alert dialog for missing Free Fire installation is displayed
      expect(find.text('Free Fire Not Installed'), findsOneWidget);
      expect(find.textContaining('Free Fire or Free Fire MAX is not installed on this device'), findsOneWidget);
      expect(find.text('Open Play Store'), findsOneWidget);

      // Recording should NOT have started
      expect(recordingService.isRecording, isFalse);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Scenario 10B Edge Case: Recording file too short (< 100 KB) shows error', (tester) async {
      final tempDir = Directory.systemTemp.createTempSync('s10b_tiny_');
      final tinyFile = File('${tempDir.path}/tiny.mp4');
      await tinyFile.create(recursive: true);
      await tinyFile.writeAsBytes(List.filled(5 * 1024, 0)); // 5 KB
      recordingService.mockRecordedFile = tinyFile;

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            realTimeSyncManagerProvider.overrideWithValue(fakeSyncManager),
            screenRecordingServiceProvider.overrideWithValue(recordingService),
            challengesRepositoryProvider.overrideWithValue(fakeChallengesRepo),
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

      await tester.tap(find.text('STOP & UPLOAD'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify upload was blocked for tiny file
      expect(fakeChallengesRepo.uploadCalled, isFalse);
      expect(find.textContaining('Recording was too short or empty.'), findsOneWidget);
      expect(capturedRef.read(activeRecordingChallengeIdProvider), isNull);

      await tester.pumpWidget(const SizedBox());
    });
  });
}
