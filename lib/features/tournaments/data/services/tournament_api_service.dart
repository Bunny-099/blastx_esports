import 'package:dio/dio.dart';
import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/api/api_endpoints.dart';

class TournamentApiService {
  final ApiClient _apiClient;

  TournamentApiService(this._apiClient);

  List<dynamic> _extractItemList(Map<String, dynamic> mapResp) {
    if (mapResp['data'] is Map) {
      final dataMap = Map<String, dynamic>.from(mapResp['data'] as Map);
      if (dataMap['items'] is List) return dataMap['items'] as List;
      if (dataMap['data'] is List) return dataMap['data'] as List;
      if (dataMap['docs'] is List) return dataMap['docs'] as List;
      if (dataMap['results'] is List) return dataMap['results'] as List;
    }
    if (mapResp['data'] is List) return mapResp['data'] as List;
    if (mapResp['items'] is List) return mapResp['items'] as List;
    if (mapResp['docs'] is List) return mapResp['docs'] as List;
    if (mapResp['results'] is List) return mapResp['results'] as List;
    return [];
  }

  int _extractInt(Map<String, dynamic> mapResp, String key, int fallback) {
    if (mapResp[key] is int) return mapResp[key] as int;
    if (mapResp['data'] is Map) {
      final dataMap = mapResp['data'] as Map;
      if (dataMap[key] is int) return dataMap[key] as int;
    }
    return fallback;
  }

  dynamic _extractCursor(Map<String, dynamic> mapResp) {
    if (mapResp.containsKey('next_cursor')) return mapResp['next_cursor'];
    if (mapResp['data'] is Map) {
      final dataMap = mapResp['data'] as Map;
      if (dataMap.containsKey('next_cursor')) return dataMap['next_cursor'];
    }
    return null;
  }

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
      final itemList = _extractItemList(mapResp);
      return {
        'items': itemList,
        'next_cursor': _extractCursor(mapResp),
        'page': _extractInt(mapResp, 'page', page),
        'limit': _extractInt(mapResp, 'limit', limit),
        'total': _extractInt(mapResp, 'total', itemList.length),
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
    String? section,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
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
      final itemList = _extractItemList(mapResp);
      return {
        'items': itemList,
        'next_cursor': _extractCursor(mapResp),
        'page': _extractInt(mapResp, 'page', page),
        'limit': _extractInt(mapResp, 'limit', limit),
        'total': _extractInt(mapResp, 'total', itemList.length),
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
    if (response is Map) {
      final mapResp = Map<String, dynamic>.from(response);
      if (mapResp['data'] is Map) {
        return Map<String, dynamic>.from(mapResp['data'] as Map);
      }
      return mapResp;
    }
    return {};
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
    final response = await _apiClient.get(ApiEndpoints.tournamentRegisteredTeams(tournamentId));
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
      if (response['items'] is List) return response['items'] as List;
      if (response['teams'] is List) return response['teams'] as List;
    }
    return [];
  }

  Future<Map<String, dynamic>> getTournamentMatchesResponse(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentMatches(tournamentId));
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    if (response is List) {
      return {
        'tournament_id': tournamentId,
        'rounds': response,
      };
    }
    return {};
  }

  Future<List<dynamic>> getMatches(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentMatches(tournamentId));
    if (response is List) return response;
    if (response is Map) {
      if (response['rounds'] is List) return response['rounds'] as List;
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

  /// Fetch full stages and group standings
  Future<List<dynamic>> getTournamentStages(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentStages(tournamentId));
    if (response is List) return response;
    if (response is Map) {
      if (response['data'] is List) return response['data'] as List;
      if (response['stages'] is List) return response['stages'] as List;
    }
    return [];
  }

  /// Fetch player's active assignment and room credentials
  Future<Map<String, dynamic>> getMyAssignment(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentMyAssignment(tournamentId));
    if (response is Map) {
      final mapResp = Map<String, dynamic>.from(response);
      if (mapResp['data'] is Map) {
        return Map<String, dynamic>.from(mapResp['data'] as Map);
      }
      return mapResp;
    }
    return {};
  }

  /// Fetch Clash Squad single-elimination knockout bracket
  Future<Map<String, dynamic>> getTournamentBracket(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.tournamentBracket(tournamentId));
    if (response is Map) {
      final mapResp = Map<String, dynamic>.from(response);
      if (mapResp['data'] is Map) {
        return Map<String, dynamic>.from(mapResp['data'] as Map);
      }
      return mapResp;
    }
    return {};
  }

  /// Register FCM registration token with backend
  Future<dynamic> registerFcmToken({required String fcmToken, String deviceType = 'android'}) async {
    return await _apiClient.post(
      ApiEndpoints.fcmToken,
      data: {
        'fcm_token': fcmToken,
        'device_type': deviceType,
      },
    );
  }

  /// Section 5: Fetch Match Center
  Future<Map<String, dynamic>> getMatchCenter(String tournamentId) async {
    final response = await _apiClient.get(ApiEndpoints.matchCenter(tournamentId));
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Section 5: Fetch single Match Unit Detail
  Future<Map<String, dynamic>> getMatchDetail(String tournamentId, String matchKey) async {
    final response = await _apiClient.get(ApiEndpoints.matchDetail(tournamentId, matchKey));
    if (response is Map) {
      final mapResp = Map<String, dynamic>.from(response);
      if (mapResp['data'] is Map) {
        return Map<String, dynamic>.from(mapResp['data'] as Map);
      }
      return mapResp;
    }
    return {};
  }

  /// Section 5: Fetch Room Credentials for a Match Unit
  Future<Map<String, dynamic>> getMatchRoomCredentials(String tournamentId, String matchKey) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.matchRoomCredentials(tournamentId, matchKey));
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
}
