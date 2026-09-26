import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/api/api_endpoints.dart';

class TournamentApiService {
  final ApiClient _apiClient;

  TournamentApiService(this._apiClient);

  Future<Map<String, dynamic>> getTournaments({
    int page = 1,
    int limit = 20,
    String? game,
    String? status,
    String? teamMode,
    String? format,
    String? map,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (game != null && game.isNotEmpty) queryParams['game'] = game;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (teamMode != null && teamMode.isNotEmpty) queryParams['team_mode'] = teamMode;
    if (format != null && format.isNotEmpty) queryParams['format'] = format;
    if (map != null && map.isNotEmpty) queryParams['map'] = map;

    final response = await _apiClient.get(
      ApiEndpoints.tournaments,
      queryParameters: queryParams,
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'items': response, 'page': page, 'limit': limit, 'total': (response as List).length};
  }

  Future<Map<String, dynamic>> getTournamentDetail(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentDetail(tournamentId));
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<dynamic>> getMyTournaments() async {
    final response = await _apiClient.get(ApiEndpoints.myTournaments);
    if (response is List) return response;
    if (response is Map && response['items'] is List) return response['items'] as List;
    return [];
  }

  Future<Map<String, dynamic>> getRoomDetails(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentRoom(tournamentId));
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<dynamic>> getParticipants(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentParticipants(tournamentId));
    if (response is List) return response;
    return [];
  }

  Future<List<dynamic>> getMatches(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentMatches(tournamentId));
    if (response is List) return response;
    return [];
  }

  Future<List<dynamic>> getLeaderboard(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentLeaderboard(tournamentId));
    if (response is List) return response;
    return [];
  }

  Future<dynamic> register({required String tournamentId, String? teamId}) async {
    final body = <String, dynamic>{};
    if (teamId != null && teamId.isNotEmpty) {
      body['team_id'] = teamId;
    }
    return await _apiClient.post(
      ApiEndpoints.registerTournament(tournamentId),
      data: body,
    );
  }

  Future<dynamic> unregister(String tournamentId) async {
    return await _apiClient.post(
      '${ApiEndpoints.registerTournament(tournamentId)}/delete',
    );
  }
}
