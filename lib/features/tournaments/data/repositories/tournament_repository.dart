import 'package:flutter/foundation.dart';
import 'package:blastix_esports/features/live/data/models/leaderboard_model.dart';
import 'package:blastix_esports/features/live/data/models/room_details_model.dart';
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
      // Backend error or missing endpoint fallback handled below
    }

    // TODO(backend): remove mock - Fallback room details state when backend is offline or missing endpoint
    final isReg = tournament?.effectiveIsRegistered ?? false;
    if (!isReg) {
      return const RoomDetailsNotRegistered();
    }

    if (tournament != null) {
      if (tournament.isLive) {
        return RoomDetailsAvailable(
          RoomDetails(
            roomId: '8492041',
            password: 'FF2026',
            visibleFrom: DateTime.now().subtract(const Duration(minutes: 10)),
          ),
        );
      }
      final diff = tournament.effectiveStartsAt.difference(DateTime.now());
      if (diff.inMinutes <= 15) {
        return RoomDetailsAvailable(
          RoomDetails(
            roomId: '8492041',
            password: 'FF2026',
            visibleFrom: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );
      } else {
        return RoomDetailsNotYetAvailable(
          revealAt: tournament.effectiveStartsAt.subtract(const Duration(minutes: 15)),
        );
      }
    }

    return const RoomDetailsNotRegistered();
  }

  Future<List<dynamic>> getParticipants(String id) async {
    return await _apiService.getParticipants(id);
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
      // API error or offline fallback handled below
    }

    // TODO(backend): remove mock - Fallback mock matches data for testing in debug mode
    if (kDebugMode) {
      return _getMockMatches(id);
    }

    return const [];
  }

  // TODO(backend): remove mock - Sample matches grouped by rounds for testing in debug mode
  List<MatchModel> _getMockMatches(String tournamentId) {
    final now = DateTime.now();
    return [
      // Round 1 - Qualifiers
      MatchModel(
        id: 'match_101',
        tournamentId: tournamentId,
        round: 'Round 1 - Qualifiers',
        matchNumber: 1,
        map: 'Bermuda',
        status: MatchStatus.completed,
        startsAt: now.subtract(const Duration(hours: 3)),
        endedAt: now.subtract(const Duration(hours: 2, minutes: 20)),
        winnerTeamName: 'Total Gaming',
        topKillerName: 'FOAB (12 Kills)',
      ),
      MatchModel(
        id: 'match_102',
        tournamentId: tournamentId,
        round: 'Round 1 - Qualifiers',
        matchNumber: 2,
        map: 'Purgatory',
        status: MatchStatus.completed,
        startsAt: now.subtract(const Duration(hours: 2)),
        endedAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        winnerTeamName: 'Team GodLike',
        topKillerName: 'JONATHAN (9 Kills)',
      ),
      MatchModel(
        id: 'match_103',
        tournamentId: tournamentId,
        round: 'Round 1 - Qualifiers',
        matchNumber: 3,
        map: 'Kalahari',
        status: MatchStatus.live,
        startsAt: now.subtract(const Duration(minutes: 15)),
        streamUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      ),
      MatchModel(
        id: 'match_104',
        tournamentId: tournamentId,
        round: 'Round 1 - Qualifiers',
        matchNumber: 4,
        map: 'Alpine',
        status: MatchStatus.upcoming,
        startsAt: now.add(const Duration(minutes: 45)),
      ),

      // Round 2 - Semi Finals
      MatchModel(
        id: 'match_201',
        tournamentId: tournamentId,
        round: 'Round 2 - Semi Finals',
        matchNumber: 5,
        map: 'Bermuda',
        status: MatchStatus.upcoming,
        startsAt: now.add(const Duration(hours: 2, minutes: 30)),
      ),
      MatchModel(
        id: 'match_202',
        tournamentId: tournamentId,
        round: 'Round 2 - Semi Finals',
        matchNumber: 6,
        map: 'Purgatory',
        status: MatchStatus.upcoming,
        startsAt: now.add(const Duration(hours: 3, minutes: 30)),
      ),

      // Grand Finals
      MatchModel(
        id: 'match_301',
        tournamentId: tournamentId,
        round: 'Grand Finals',
        matchNumber: 7,
        map: 'Kalahari',
        status: MatchStatus.upcoming,
        startsAt: now.add(const Duration(days: 1)),
      ),
    ];
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
      // Fallback handled below
    }

    // TODO(backend): remove mock - Fallback mock leaderboard data for testing in debug mode
    if (kDebugMode) {
      return _getMockLeaderboard(tournamentId, round: round);
    }

    return LeaderboardResponse(
      tournamentId: tournamentId,
      updatedAt: DateTime.now(),
      round: round ?? 'Grand Final',
      entries: const [],
    );
  }

  // TODO(backend): remove mock - Sample 10 teams mock leaderboard data for testing in debug mode
  LeaderboardResponse _getMockLeaderboard(String tournamentId, {String? round}) {
    final mockEntries = <LeaderboardEntry>[
      const LeaderboardEntry(
        rank: 1,
        prevRank: 2,
        teamId: 'team_01',
        teamName: 'Total Gaming',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=TotalGaming',
        kills: 42,
        placementPoints: 60,
        totalPoints: 102,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 2,
        prevRank: 1,
        teamId: 'team_02',
        teamName: 'Team GodLike',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=GodLike',
        kills: 38,
        placementPoints: 50,
        totalPoints: 88,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 3,
        prevRank: 3,
        teamId: 'team_03',
        teamName: 'Orangutan Esports',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=Orangutan',
        kills: 35,
        placementPoints: 45,
        totalPoints: 80,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 4,
        prevRank: 6,
        teamId: 'team_04',
        teamName: 'Team Elite',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=TeamElite',
        kills: 28,
        placementPoints: 38,
        totalPoints: 66,
        status: LeaderboardEntryStatus.qualified,
      ),
      const LeaderboardEntry(
        rank: 5,
        prevRank: 4,
        teamId: 'team_05',
        teamName: 'Blind Esports',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=BlindEsports',
        kills: 25,
        placementPoints: 35,
        totalPoints: 60,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 6,
        prevRank: 5,
        teamId: 'team_06',
        teamName: 'Nigma Galaxy',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=NigmaGalaxy',
        kills: 22,
        placementPoints: 30,
        totalPoints: 52,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 7,
        prevRank: 8,
        teamId: 'team_07',
        teamName: 'TSM India',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=TSMIndia',
        kills: 20,
        placementPoints: 25,
        totalPoints: 45,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 8,
        prevRank: 7,
        teamId: 'team_08',
        teamName: 'Chemugu Esports',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=Chemugu',
        kills: 18,
        placementPoints: 20,
        totalPoints: 38,
        status: LeaderboardEntryStatus.active,
      ),
      const LeaderboardEntry(
        rank: 9,
        prevRank: 9,
        teamId: 'team_09',
        teamName: 'Team Insane',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=TeamInsane',
        kills: 15,
        placementPoints: 15,
        totalPoints: 30,
        status: LeaderboardEntryStatus.eliminated,
      ),
      const LeaderboardEntry(
        rank: 10,
        prevRank: 10,
        teamId: 'team_10',
        teamName: 'Entity Gaming',
        logoUrl: 'https://api.dicebear.com/7.x/identicon/svg?seed=EntityGaming',
        kills: 12,
        placementPoints: 10,
        totalPoints: 22,
        status: LeaderboardEntryStatus.eliminated,
      ),
    ];

    return LeaderboardResponse(
      tournamentId: tournamentId,
      updatedAt: DateTime.now(),
      round: round ?? 'Grand Final',
      entries: mockEntries,
    );
  }

  Future<dynamic> registerSolo(String id, {String? teamId}) =>
      _apiService.register(tournamentId: id, teamId: teamId);

  Future<dynamic> unregister(String id) => _apiService.unregister(id);
}
