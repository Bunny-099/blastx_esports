import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/tournaments/data/services/tournament_api_service.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';

class FakeStorageService extends StorageService {}
class FakeDeviceInfoService extends DeviceInfoService {}

class RecordingMockApiClient extends ApiClient {
  RecordingMockApiClient() : super(FakeStorageService(), FakeDeviceInfoService());

  Map<String, dynamic>? lastQueryParameters;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastQueryParameters = queryParameters;
    return {
      'data': [],
      'page': 1,
      'limit': 20,
      'total': 0,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TournamentApiService Unit Tests', () {
    test('getTournaments sends status parameter in UPPERCASE to backend', () async {
      final mockClient = RecordingMockApiClient();
      final apiService = TournamentApiService(mockClient);

      await apiService.getTournaments(
        status: 'live',
        game: 'Free Fire',
      );

      expect(mockClient.lastQueryParameters, isNotNull);
      expect(mockClient.lastQueryParameters!['status'], equals('LIVE'));
    });

    test('getTournaments formats upcoming status in UPPERCASE', () async {
      final mockClient = RecordingMockApiClient();
      final apiService = TournamentApiService(mockClient);

      await apiService.getTournaments(
        status: 'upcoming',
        game: 'Free Fire',
      );

      expect(mockClient.lastQueryParameters, isNotNull);
      expect(mockClient.lastQueryParameters!['status'], equals('UPCOMING'));
    });

    test('getTournaments omits status when status is all', () async {
      final mockClient = RecordingMockApiClient();
      final apiService = TournamentApiService(mockClient);

      await apiService.getTournaments(
        status: 'all',
        game: 'Free Fire',
      );

      expect(mockClient.lastQueryParameters, isNotNull);
      expect(mockClient.lastQueryParameters!.containsKey('status'), isFalse);
    });
  });
}
