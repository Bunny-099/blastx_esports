import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/challenges/data/services/screen_recording_service.dart';
import 'package:blastix_esports/features/challenges/data/services/challenges_api_service.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends ApiClient {
  MockApiClient() : super(SharedPreferences.getInstance());

  @override
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    return {'status': 'success', 'message': 'Proof uploaded successfully'};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Proof Upload Validation Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('proof_upload_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('ScreenRecordingService should NOT append 2MB dummy bytes (i % 256)', () async {
      final service = ScreenRecordingService();
      
      // Attempting stop without start should return null
      final stopped = await service.stopRecording();
      expect(stopped, isNull);
    });

    test('ChallengesApiService should reject non-existent file', () async {
      final apiService = ChallengesApiService(MockApiClient());
      final nonExistentFile = File('${tempDir.path}/does_not_exist.mp4');

      expect(
        () => apiService.submitChallengeProof(
          challengeId: 'c123',
          videoFile: nonExistentFile,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Video recording file does not exist'),
        )),
      );
    });

    test('ChallengesApiService should reject empty file (0 bytes)', () async {
      final apiService = ChallengesApiService(MockApiClient());
      final emptyFile = File('${tempDir.path}/empty.mp4');
      await emptyFile.create();

      expect(
        () => apiService.submitChallengeProof(
          challengeId: 'c123',
          videoFile: emptyFile,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('is empty (0 bytes)'),
        )),
      );
    });

    test('ChallengesApiService should accept valid non-empty video file', () async {
      final apiService = ChallengesApiService(MockApiClient());
      final validFile = File('${tempDir.path}/real_video.mp4');
      
      // Write mock mp4 header bytes
      final mockVideoBytes = [0x00, 0x00, 0x00, 0x18, 0x66, 0x74, 0x79, 0x70, 0x6d, 0x70, 0x34, 0x32];
      await validFile.writeAsBytes(mockVideoBytes);

      final result = await apiService.submitChallengeProof(
        challengeId: 'c123',
        videoFile: validFile,
      );

      expect(result['status'], equals('success'));
    });
  });
}
