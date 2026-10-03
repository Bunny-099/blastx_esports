import 'package:dio/dio.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/api/api_endpoints.dart';

class TournamentApiService {
  final ApiClient _apiClient;

  TournamentApiService(this._apiClient);

  /// Dedicated fetch call for Free Fire Live section API
  Future<Map<String, dynamic>> getFreeFireLiveTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? q,
    String? cursor,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toUpperCase();
    }
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (cursor != null && cursor.isNotEmpty) queryParams['cursor'] = cursor;

    final response = await _apiClient.get(
      ApiEndpoints.freeFireLive,
      queryParameters: queryParams,
    );

    if (response is Map) {
      final mapResp = Map<String, dynamic>.from(response);
      final rawItems = mapResp['data'] ?? mapResp['items'] ?? [];
      final itemList = rawItems is List ? rawItems : [];
      return {
        'items': itemList,
        'next_cursor': mapResp['next_cursor'],
        'page': mapResp['page'] ?? page,
        'limit': mapResp['limit'] ?? limit,
        'total': mapResp['total'] ?? itemList.length,
      };
    }
    if (response is List) {
      return {
        'items': response,
        'next_cursor': null,
        'page': page,
        'limit': limit,
        'total': response.length,
      };
    }
    return {'items': [], 'next_cursor': null, 'page': page, 'limit': limit, 'total': 0};
  }

  /// Fetch call for BlastX Esports Tournaments section API
  Future<Map<String, dynamic>> getTournaments({
    int page = 1,
    int limit = 20,
    String? game,
    String? status,
    String? q,
    String? cursor,
    String? teamMode,
    String? format,
    String? map,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (game != null && game.isNotEmpty) queryParams['game'] = game;
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      queryParams['status'] = status.toUpperCase();
    }
    if (q != null && q.isNotEmpty) queryParams['q'] = q;
    if (cursor != null && cursor.isNotEmpty) queryParams['cursor'] = cursor;
    if (teamMode != null && teamMode.isNotEmpty) queryParams['team_mode'] = teamMode;
    if (format != null && format.isNotEmpty) queryParams['format'] = format;
    if (map != null && map.isNotEmpty) queryParams['map'] = map;

    final response = await _apiClient.get(
      ApiEndpoints.tournaments,
      queryParameters: queryParams,
    );

    if (response is Map) {
      final mapResp = Map<String, dynamic>.from(response);
      final rawItems = mapResp['data'] ?? mapResp['items'] ?? [];
      final itemList = rawItems is List ? rawItems : [];
      return {
        'items': itemList,
        'next_cursor': mapResp['next_cursor'],
        'page': mapResp['page'] ?? page,
        'limit': mapResp['limit'] ?? limit,
        'total': mapResp['total'] ?? itemList.length,
      };
    }
    if (response is List) {
      return {
        'items': response,
        'next_cursor': null,
        'page': page,
        'limit': limit,
        'total': response.length,
      };
    }
    return {'items': [], 'next_cursor': null, 'page': page, 'limit': limit, 'total': 0};
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
    try {
      final response = await _apiClient.get(ApiEndpoints.tournamentRoom(tournamentId));
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return {'status': 'success', 'data': response};
    } on DioException catch (e) {
      if (e.response != null && e.response?.data is Map) {
        final errorData = Map<String, dynamic>.from(e.response!.data as Map);
        errorData['statusCode'] = e.response?.statusCode;
        return errorData;
      }
      rethrow;
    }
  }

  Future<List<dynamic>> getParticipants(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentParticipants(tournamentId));
    if (response is List) return response;
    return [];
  }

  Future<List<dynamic>> getMatches(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentMatches(tournamentId));
    if (response is List) return response;
    if (response is Map) {
      if (response['matches'] is List) return response['matches'] as List;
      if (response['data'] is List) return response['data'] as List;
      if (response['items'] is List) return response['items'] as List;
    }
    return [];
  }

  Future<dynamic> getLeaderboard(String tournamentId, {String? round}) async {
    final queryParams = <String, dynamic>{};
    if (round != null && round.isNotEmpty) {
      queryParams['round'] = round;
    }
    final response = await _apiClient.get(
      ApiEndpoints.tournamentLeaderboard(tournamentId),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return response;
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
