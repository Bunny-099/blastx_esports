import 'package:blastx_esports/core/api/api_client.dart';
import 'package:blastx_esports/core/api/api_endpoints.dart';
import 'package:blastx_esports/features/splash/providers/splash_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/team_model.dart';

/// ============================================================
/// TEAM PROVIDER
/// ============================================================
/// Per-tournament team state (family keyed by tournamentId).
/// All rules (one team per tournament, 4/2 caps, captain
/// transfer, roster lock) are enforced by the backend; the
/// client only maps backend error codes to friendly messages.
/// ============================================================

/// TODO: return your app's existing ApiClient provider here
/// (e.g. `ref.watch(apiClientProvider)`).
final teamApiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(apiClientProvider);
});

final teamRepositoryProvider = Provider<TeamRepository>(
        (ref) => TeamRepository(ref.watch(teamApiClientProvider)));

class TeamRepository {
  TeamRepository(this._api);
  final ApiClient _api;

  TournamentTeamModel _team(dynamic d) {
    final map = (d is Map && d['team'] is Map) ? d['team'] : d;
    return TournamentTeamModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  Future<TournamentTeamModel?> myTeam(String tid) async {
    try {
      final d = await _api.get(ApiEndpoints.myTeam(tid));
      return d == null ? null : _team(d);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<TournamentTeamModel> create(String tid, Map<String, dynamic> body) async =>
      _team(await _api.post(ApiEndpoints.tournamentTeams(tid), data: body));

  Future<TournamentTeamModel> byCode(String tid, String code) async =>
      _team(await _api.get(ApiEndpoints.teamByCode(tid, code)));

  Future<TournamentTeamModel> join(String teamId, Map<String, dynamic> body) async =>
      _team(await _api.post(ApiEndpoints.joinTeam(teamId), data: body));

  Future<void> leave(String teamId) => _api.post(ApiEndpoints.leaveTeam(teamId));

  Future<TournamentTeamModel> removeMember(String teamId, String userId) async =>
      _team(await _api.post(ApiEndpoints.removeTeamMember(teamId, userId)));

  Future<TournamentTeamModel> transferCaptain(String teamId, String userId) async =>
      _team(await _api.post(ApiEndpoints.transferCaptain(teamId),
          data: {'userId': userId}));

  Future<TournamentTeamModel> setAcceptingSubstitutes(
      String teamId, bool value) async =>
      _team(await _api.patch(ApiEndpoints.teamSubstitutes(teamId),
          data: {'acceptingSubstitutes': value}));
}

class _TeamException implements Exception {
  const _TeamException(this.message);
  final String message;
}

class TeamState {
  final TournamentTeamModel? team; // the user's team in this tournament
  final TournamentTeamModel? previewTeam; // team found by code
  final bool isLoading;
  final String? error;

  const TeamState({
    this.team,
    this.previewTeam,
    this.isLoading = false,
    this.error,
  });

  TeamState copyWith({
    TournamentTeamModel? team,
    bool clearTeam = false,
    TournamentTeamModel? previewTeam,
    bool clearPreview = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      TeamState(
        team: clearTeam ? null : (team ?? this.team),
        previewTeam: clearPreview ? null : (previewTeam ?? this.previewTeam),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class TeamNotifier extends FamilyNotifier<TeamState, String> {
  @override
  TeamState build(String arg) => const TeamState();

  String get _tid => arg;
  TeamRepository get _repo => ref.read(teamRepositoryProvider);

  static String _message(Object e) {
    if (e is _TeamException) return e.message;
    if (e is DioException) {
      final data = e.response?.data;
      switch (data is Map ? data['code']?.toString() : null) {
        case 'TEAM_NOT_FOUND':
          return 'Team not found. Please check the code and try again.';
        case 'TEAM_FULL':
          return 'This team is full.';
        case 'ALREADY_IN_TEAM':
          return 'You are already part of a team in this tournament.';
        case 'REGISTRATION_CLOSED':
          return 'Registration for this tournament has ended.';
        case 'CAPTAIN_MUST_TRANSFER':
          return 'Transfer captaincy before leaving the team.';
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Network error. Check your connection and try again.';
      }
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<bool> _guard(Future<void> Function() body) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await body();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearPreview() => state = state.copyWith(clearPreview: true);

  /// Loads the user's existing team for this tournament (if any).
  Future<void> loadMyTeam() => _guard(() async {
    final t = await _repo.myTeam(_tid);
    state = t == null ? state.copyWith(clearTeam: true) : state.copyWith(team: t);
  });

  Future<void> refresh() async {
    try {
      final t = await _repo.myTeam(_tid);
      state = t == null ? state.copyWith(clearTeam: true) : state.copyWith(team: t);
    } catch (e) {
      state = state.copyWith(error: _message(e));
    }
  }

  Future<bool> createTeam({
    required String teamName,
    required String tag,
    required String playerName,
    required String ign,
    required String uid,
  }) =>
      _guard(() async {
        final t = await _repo.create(_tid, {
          'name': teamName,
          'tag': tag,
          'player': {'name': playerName, 'ign': ign, 'uid': uid},
        });
        state = state.copyWith(team: t);
      });

  Future<bool> lookupTeam(String code) => _guard(() async {
    try {
      final t = await _repo.byCode(_tid, code);
      state = state.copyWith(previewTeam: t);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const _TeamException(
            'Team not found. Please check the code and try again.');
      }
      rethrow;
    }
  });

  Future<bool> joinTeam({
    required String playerName,
    required String ign,
    required String uid,
  }) =>
      _guard(() async {
        final preview = state.previewTeam!;
        final t = await _repo.join(preview.id, {
          'rosterType': preview.isMainFull ? 'SUBSTITUTE' : 'MAIN',
          'player': {'name': playerName, 'ign': ign, 'uid': uid},
        });
        state = state.copyWith(team: t, clearPreview: true);
      });

  Future<bool> removeMember(String userId) => _guard(() async {
    final t = await _repo.removeMember(state.team!.id, userId);
    state = state.copyWith(team: t);
  });

  Future<bool> transferCaptain(String userId) => _guard(() async {
    final t = await _repo.transferCaptain(state.team!.id, userId);
    state = state.copyWith(team: t);
  });

  Future<bool> setAcceptingSubstitutes(bool value) => _guard(() async {
    final t = await _repo.setAcceptingSubstitutes(state.team!.id, value);
    state = state.copyWith(team: t);
  });

  Future<bool> leaveTeam() => _guard(() async {
    await _repo.leave(state.team!.id);
    state = state.copyWith(clearTeam: true);
  });
}

final teamProvider =
NotifierProvider.family<TeamNotifier, TeamState, String>(TeamNotifier.new);