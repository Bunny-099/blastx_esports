import 'package:blastix_esports/features/live/data/models/leaderboard_model.dart';
import 'package:blastix_esports/features/live/data/models/room_details_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_matches_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/splash/providers/splash_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tournament_api_service.dart';

final tournamentApiServiceProvider = Provider<TournamentApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TournamentApiService(apiClient);
});

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  final apiService = ref.watch(tournamentApiServiceProvider);
  return TournamentRepository(apiService);
});

class TournamentRepository {
  final TournamentApiService _apiService;

  TournamentRepository(this._apiService);

  Future<List<TournamentModel>> getFreeFireLiveTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? q,
    String? cursor,
  }) async {
    final response = await _apiService.getFreeFireLiveTournaments(
      page: page,
      limit: limit,
      status: status,
      q: q,
      cursor: cursor,
    );

    final items = (response['items'] as List<dynamic>?) ?? [];
    return items
        .map((e) => TournamentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<TournamentModel>> getTournaments({
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
    try {
      final response = await _apiService.getTournaments(
        page: page,
        limit: limit,
        game: game,
        status: status,
        q: q,
        cursor: cursor,
        teamMode: teamMode,
        format: format,
        map: map,
      );

      final items = (response['items'] as List<dynamic>?) ?? [];
      return items
          .map((e) => TournamentModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {}

    return const [];
  }

  Future<TournamentModel> getTournamentDetail(String id) async {
    final data = await _apiService.getTournamentDetail(id);
    return TournamentModel.fromJson(data);
  }

  Future<List<TournamentModel>> getMyTournaments() async {
    final list = await _apiService.getMyTournaments();
    return list
        .map((e) => TournamentModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, String>> getRoomDetails(String id) async {
    final data = await _apiService.getRoomDetails(id);
    return {
      'room_id': data['room_id']?.toString() ?? '',
      'room_password': data['room_password']?.toString() ?? '',
      'room_released_at': data['room_released_at']?.toString() ?? '',
    };
  }

  Future<RoomDetailsState> getRoomDetailsState(
    String tournamentId, {
    TournamentModel? tournament,
  }) async {
    try {
      final res = await _apiService.getRoomDetails(tournamentId);

      // Check code or status codes
      final code = (res['code'] ?? '').toString().toUpperCase();
      final statusCode = res['statusCode'] as int?;

      if (code == 'NOT_REGISTERED' || statusCode == 403) {
        return const RoomDetailsNotRegistered();
      }

      if (code == 'ROOM_NOT_AVAILABLE' || statusCode == 409 || statusCode == 425) {
        final rawRevealAt = res['reveal_at'] ?? res['revealAt'] ?? res['visible_from'] ?? res['visibleFrom'];
        final parsedRevealAt = rawRevealAt != null ? DateTime.tryParse(rawRevealAt.toString()) : null;
        return RoomDetailsNotYetAvailable(revealAt: parsedRevealAt);
      }

      // Check for valid room_id
      final dataMap = res['data'] is Map ? Map<String, dynamic>.from(res['data'] as Map) : res;
      final roomId = (dataMap['room_id'] ?? dataMap['roomId'] ?? '').toString();
      if (roomId.isNotEmpty) {
        return RoomDetailsAvailable(RoomDetails.fromJson(dataMap));
      }
    } catch (_) {
      // Backend error or missing endpoint handled
    }

    return const RoomDetailsNotRegistered();
  }

  Future<List<TournamentTeamModel>> getRegisteredTeams(String id) async {
    try {
      final list = await _apiService.getParticipants(id);
      if (list.isNotEmpty) {
        return list
            .map((e) => TournamentTeamModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}

    return const [];
  }

  Future<List<dynamic>> getParticipants(String id) async {
    return await _apiService.getParticipants(id);
  }

  Future<TournamentMatchesResponse> getTournamentMatches(String id) async {
    try {
      final res = await _apiService.getTournamentMatchesResponse(id);
      if (res.isNotEmpty) {
        return TournamentMatchesResponse.fromJson(res);
      }
    } catch (_) {
      // API error or missing endpoint handled
    }

    return TournamentMatchesResponse(tournamentId: id);
  }

  Future<List<MatchModel>> getMatches(String id) async {
    try {
      final list = await _apiService.getMatches(id);
      if (list.isNotEmpty) {
        return list
            .map((e) => MatchModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // API error handled
    }

    return const [];
  }

  Future<List<TeamModel>> getLeaderboard(String id) async {
    final raw = await _apiService.getLeaderboard(id);
    if (raw is List) {
      return raw
          .map((e) => TeamModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<LeaderboardResponse> getLeaderboardResponse(String tournamentId, {String? round}) async {
    try {
      final raw = await _apiService.getLeaderboard(tournamentId, round: round);
      if (raw is Map) {
        final dataList = raw['data'] is List ? (raw['data'] as List) : null;
        if (dataList != null && dataList.isNotEmpty) {
          final entries = dataList
              .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          return LeaderboardResponse(
            tournamentId: tournamentId,
            updatedAt: DateTime.now(),
            round: round ?? 'Live Standings',
            entries: entries,
          );
        }
        final resp = LeaderboardResponse.fromJson(Map<String, dynamic>.from(raw));
        if (resp.entries.isNotEmpty) {
          return resp;
        }
      } else if (raw is List && raw.isNotEmpty) {
        final entries = raw
            .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return LeaderboardResponse(
          tournamentId: tournamentId,
          updatedAt: DateTime.now(),
          round: round ?? 'Grand Final',
          entries: entries,
        );
      }
    } catch (_) {
      // API error handled
    }

    return LeaderboardResponse(
      tournamentId: tournamentId,
      updatedAt: DateTime.now(),
      round: round ?? 'Grand Final',
      entries: const [],
    );
  }

  Future<dynamic> registerSolo(String id, {String? teamId}) =>
      _apiService.register(tournamentId: id, teamId: teamId);

  Future<dynamic> unregister(String id) => _apiService.unregister(id);
}
