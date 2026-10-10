import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/services/device_info_service.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStorageService extends StorageService {}
class FakeDeviceInfoService extends DeviceInfoService {}

class MockApiClient extends ApiClient {
  MockApiClient({required this.onGet})
      : super(FakeStorageService(), FakeDeviceInfoService());

  final Future<dynamic> Function(String endpoint) onGet;

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return onGet(endpoint);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const tournamentId = 'cmuznjl7c000lte01zdf62y95';

  group('GET /v1/tournaments/{tournamentId}/my-team 404 vs 200 Handling', () {
    test('HTTP 404 Not Found returns null (User has not created or joined a team)', () async {
      final mockApi = MockApiClient(
        onGet: (endpoint) async {
          expect(endpoint, contains('/tournaments/$tournamentId/my-team'));
          throw DioException(
            requestOptions: RequestOptions(path: endpoint),
            response: Response(
              requestOptions: RequestOptions(path: endpoint),
              statusCode: 404,
              data: {'message': 'Team not found', 'code': 'NOT_FOUND'},
            ),
            type: DioExceptionType.badResponse,
          );
        },
      );

      final repo = TeamRepository(mockApi);
      final result = await repo.myTeam(tournamentId);

      expect(result, isNull);
    });

    test('API NOT_FOUND error code response returns null (User not in team)', () async {
      final mockApi = MockApiClient(
        onGet: (endpoint) async {
          return {'status': 'error', 'code': 'TEAM_NOT_FOUND', 'message': 'No team'};
        },
      );

      final repo = TeamRepository(mockApi);
      final result = await repo.myTeam(tournamentId);

      expect(result, isNull);
    });

    test('HTTP 200 OK returns TournamentTeamModel (User registered in team)', () async {
      final mockApi = MockApiClient(
        onGet: (endpoint) async {
          return {
            'id': 'team_123',
            'tournament_id': tournamentId,
            'name': 'Alpha Squad',
            'tag': 'ALPHA',
            'code': 'BLX-ALPHA',
            'captain_id': 'usr_1',
            'status': 'FORMING',
            'members': [
              {
                'user_id': 'usr_1',
                'name': 'Pro Player',
                'ign': 'PRO_ONE',
                'uid': '987654321',
                'role': 'CAPTAIN',
                'roster_type': 'MAIN',
                'status': 'CONFIRMED',
              }
            ],
          };
        },
      );

      final repo = TeamRepository(mockApi);
      final result = await repo.myTeam(tournamentId);

      expect(result, isNotNull);
      expect(result, isA<TournamentTeamModel>());
      expect(result!.id, equals('team_123'));
      expect(result.name, equals('Alpha Squad'));
      expect(result.members.length, equals(1));
      expect(result.members.first.role, equals(TeamRole.captain));
    });

    test('TeamState correctly identifies when team is registered or present', () {
      const nullTeamState = TeamState(team: null);
      expect(nullTeamState.team, isNull);

      final registeredTeam = TournamentTeamModel(
        id: 'team_123',
        tournamentId: tournamentId,
        code: 'BLX-123',
        name: 'Alpha Squad',
        captainId: 'usr_1',
        status: TeamRegistrationStatus.registered,
      );

      final hasTeamState = TeamState(team: registeredTeam);
      expect(hasTeamState.team, isNotNull);
      expect(hasTeamState.team!.isRegistered, isTrue);
    });
  });
}
