import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/tournaments/data/services/tournament_api_service.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';

class FakeStorageService extends StorageService {}
class FakeDeviceInfoService extends DeviceInfoService {}

class RecordingMockApiClient extends ApiClient {
  RecordingMockApiClient({this.mockResponse})
      : super(FakeStorageService(), FakeDeviceInfoService());

  Map<String, dynamic>? lastQueryParameters;
  dynamic mockResponse;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dynamic options,
  }) async {
    lastQueryParameters = queryParameters;
    return mockResponse ??
        {
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

    test('getTournaments sends section parameter to backend when provided', () async {
      final mockClient = RecordingMockApiClient();
      final apiService = TournamentApiService(mockClient);

      await apiService.getTournaments(
        section: 'BLASTX',
        status: 'LIVE',
      );

      expect(mockClient.lastQueryParameters, isNotNull);
      expect(mockClient.lastQueryParameters!['section'], equals('BLASTX'));
      expect(mockClient.lastQueryParameters!['status'], equals('LIVE'));
    });

    test('getTournaments correctly parses nested data.items response object', () async {
      final mockClient = RecordingMockApiClient(
        mockResponse: {
          'status': 'success',
          'data': {
            'items': [
              {
                'id': 'tourn_1',
                'title': '[BlastX] Test Tournament',
                'status': 'LIVE',
              }
            ],
            'page': 1,
            'limit': 20,
            'total': 1,
          }
        },
      );
      final apiService = TournamentApiService(mockClient);

      final result = await apiService.getTournaments(status: 'LIVE');

      expect(result['items'], isA<List>());
      final items = result['items'] as List;
      expect(items.length, equals(1));
      expect(items.first['id'], equals('tourn_1'));
      expect(items.first['title'], equals('[BlastX] Test Tournament'));
      expect(result['total'], equals(1));
    });

    test('getFreeFireLiveTournaments correctly parses nested data.items response object', () async {
      final mockClient = RecordingMockApiClient(
        mockResponse: {
          'data': {
            'items': [
              {
                'id': 'ff_1',
                'title': 'Free Fire Live Championship',
                'status': 'UPCOMING',
              }
            ],
            'page': 1,
            'limit': 10,
            'total': 1,
          }
        },
      );
      final apiService = TournamentApiService(mockClient);

      final result = await apiService.getFreeFireLiveTournaments(status: 'UPCOMING');

      expect(result['items'], isA<List>());
      final items = result['items'] as List;
      expect(items.length, equals(1));
      expect(items.first['id'], equals('ff_1'));
      expect(result['total'], equals(1));
    });
  });
}
