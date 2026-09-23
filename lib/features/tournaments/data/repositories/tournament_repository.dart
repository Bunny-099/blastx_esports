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

  Future<List<TournamentModel>> getTournaments({
    int page = 1,
    int limit = 20,
    String? status,
    String? teamMode,
    String? format,
    String? map,
  }) async {
    final response = await _apiService.getTournaments(
      page: page,
      limit: limit,
      status: status,
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

  Future<List<dynamic>> getParticipants(String id) async {
    return await _apiService.getParticipants(id);
  }

  Future<List<MatchModel>> getMatches(String id) async {
    final list = await _apiService.getMatches(id);
    return list
        .map((e) => MatchModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<TeamModel>> getLeaderboard(String id) async {
    final list = await _apiService.getLeaderboard(id);
    return list
        .map((e) => TeamModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<dynamic> registerSolo(String id, {String? teamId}) =>
      _apiService.register(tournamentId: id, teamId: teamId);

  Future<dynamic> unregister(String id) => _apiService.unregister(id);
}
