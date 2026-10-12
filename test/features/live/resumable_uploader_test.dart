import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/network/network_connectivity_observer.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/features/live/data/models/recording_job_model.dart';
import 'package:blastix_esports/features/live/data/repositories/recording_jobs_repository.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(StorageService(), DeviceInfoService());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late RecordingJobsRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = RecordingJobsRepository(prefs);
  });

  test('RecordingJobModel JSON serialization', () {
    final job = RecordingJobModel(
      clientRecordingId: 'uuid-1234',
      tournamentId: 't1',
      matchKey: 'm1',
      filePath: '/tmp/rec.mp4',
      sizeBytes: 1048576,
      durationSeconds: 120,
      startedAt: '2026-10-12T10:00:00.000Z',
      stoppedAt: '2026-10-12T10:02:00.000Z',
      recordingId: 'rec_1',
      sessionUrl: 'https://www.googleapis.com/upload/drive/v3/files?uploadType=resumable',
      chunkSizeBytes: 262144,
      status: 'pending',
    );

    final json = job.toJson();
    final restored = RecordingJobModel.fromJson(json);

    expect(restored.clientRecordingId, 'uuid-1234');
    expect(restored.tournamentId, 't1');
    expect(restored.matchKey, 'm1');
    expect(restored.sizeBytes, 1048576);
    expect(restored.chunkSizeBytes, 262144);
    expect(restored.status, 'pending');
  });

  test('RecordingJobsRepository saves, retrieves, and removes jobs', () async {
    final job = RecordingJobModel(
      clientRecordingId: 'uuid-5678',
      tournamentId: 't2',
      matchKey: 'm2',
      filePath: '/tmp/rec2.mp4',
      sizeBytes: 2048,
      durationSeconds: 30,
      startedAt: '2026-10-12T10:00:00.000Z',
      stoppedAt: '2026-10-12T10:00:30.000Z',
    );

    await repo.saveJob(job);

    var all = repo.getAllJobs();
    expect(all.length, 1);
    expect(all.first.clientRecordingId, 'uuid-5678');

    final found = repo.getJobForMatch('t2', 'm2');
    expect(found, isNotNull);
    expect(found?.filePath, '/tmp/rec2.mp4');

    await repo.removeJob('uuid-5678');
    all = repo.getAllJobs();
    expect(all.isEmpty, true);
  });

  test('RecordingJobsRepository WiFi only setting', () async {
    expect(repo.getWifiOnlySetting(), false);
    await repo.setWifiOnlySetting(true);
    expect(repo.getWifiOnlySetting(), true);
  });
}
