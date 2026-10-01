import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/challenges/data/services/screen_recording_service.dart';
import 'package:blastix_esports/features/challenges/data/services/challenges_api_service.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';

class FakeStorageService extends StorageService {}

class FakeDeviceInfoService extends DeviceInfoService {
  FakeDeviceInfoService() : super();
}

class MockApiClient extends ApiClient {
  MockApiClient() : super(FakeStorageService(), FakeDeviceInfoService());

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

    test('ScreenRecordingService start and stop recording generates valid non-empty mp4 file', () async {
      final service = ScreenRecordingService();

      final started = await service.startRecording(challengeId: 'c123');
      expect(started, isTrue);
      expect(service.isRecording, isTrue);

      final recordedFile = await service.stopRecording();
      expect(recordedFile, isNotNull);
      expect(await recordedFile!.exists(), isTrue);
      expect(await recordedFile.length(), greaterThan(0));
      expect(service.isRecording, isFalse);

      // Clean up temp file
      await service.deleteRecordingFile(recordedFile);
      expect(await recordedFile.exists(), isFalse);
    });

    test('ScreenRecordingService stop without start returns null', () async {
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

    test('ChallengesApiService should reject small or empty file (< 100 KB)', () async {
      final apiService = ChallengesApiService(MockApiClient());
      final smallFile = File('${tempDir.path}/small.mp4');
      await smallFile.writeAsBytes(List.filled(10 * 1024, 0x00)); // 10 KB file

      expect(
        () => apiService.submitChallengeProof(
          challengeId: 'c123',
          videoFile: smallFile,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Minimum required size is 100 KB'),
        )),
      );
    });

    test('ChallengesApiService should reject file exceeding 60 MB limit', () async {
      final apiService = ChallengesApiService(MockApiClient());
      final oversizedFile = File('${tempDir.path}/oversized.mp4');
      
      // Create a sparse file or mock size > 60 MB
      final RandomAccessFile raf = await oversizedFile.open(mode: FileMode.write);
      await raf.truncate(61 * 1024 * 1024); // 61 MB
      await raf.close();

      expect(
        () => apiService.submitChallengeProof(
          challengeId: 'c123',
          videoFile: oversizedFile,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('exceeds the maximum allowed limit of 60 MB'),
        )),
      );
    });

    test('ChallengesApiService should accept valid video file (>= 100 KB)', () async {
      final apiService = ChallengesApiService(MockApiClient());
      final validFile = File('${tempDir.path}/real_video.mp4');
      
      // Write mock mp4 video bytes (150 KB > 100 KB limit)
      await validFile.writeAsBytes(List.filled(150 * 1024, 0x00));

      final result = await apiService.submitChallengeProof(
        challengeId: 'c123',
        videoFile: validFile,
      );

      expect(result['status'], equals('success'));
    });
  });
}
