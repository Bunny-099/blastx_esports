import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/api/api_endpoints.dart';
import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/profile/providers/profile_provider.dart';
import 'package:blastix_esports/features/splash/providers/splash_providers.dart';
import 'package:blastix_esports/features/squad/data/models/squad_model.dart';
import 'package:blastix_esports/features/squad/providers/squad_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/registration_approval_model.dart';
import '../data/models/team_member_model.dart';
import '../data/models/team_model.dart';
import 'live_provider.dart';

/// ============================================================
/// TEAM PROVIDER & DATA LAYER
/// ============================================================

final teamApiClientProvider = Provider<ApiClient>((ref) {
  return ref.watch(apiClientProvider);
});

final teamRepositoryProvider = Provider<TeamRepository>(
    (ref) => TeamRepository(ref.watch(teamApiClientProvider)));

class TeamRepository {
  TeamRepository(this._api);
  final ApiClient _api;

  TournamentTeamModel parseTeam(dynamic d) {
    final map = (d is Map && d['team'] is Map) ? d['team'] : d;
    return TournamentTeamModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  Future<TournamentTeamModel?> myTeam(String tid) async {
    try {
      final d = await _api.get(ApiEndpoints.myTeam(tid));
      if (d == null) return null;
      if (d is Map && (d['code'] == 'NOT_FOUND' || d['code'] == 'TEAM_NOT_FOUND')) {
        return null;
      }
      return parseTeam(d);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      final data = e.response?.data;
      if (data is Map && (data['code'] == 'NOT_FOUND' || data['code'] == 'TEAM_NOT_FOUND')) {
        return null;
      }
      rethrow;
    }
  }

  Future<TournamentTeamModel> create(String tid, Map<String, dynamic> body) async =>
      parseTeam(await _api.post(ApiEndpoints.tournamentTeams(tid), data: body));

  Future<TeamPreview> lookupTeamPreview(String tid, String code) async {
    final data = await _api.get(ApiEndpoints.teamByCode(tid, code));
    if (data is Map) {
      return TeamPreview.fromJson(Map<String, dynamic>.from(data));
    }
    throw const _TeamException('Invalid response when searching for team code');
  }

  Future<TournamentTeamModel> byCode(String tid, String code) async =>
      parseTeam(await _api.get(ApiEndpoints.teamByCode(tid, code)));

  Future<JoinResult> requestToJoin(String teamId, Map<String, dynamic> body) async {
    final data = await _api.post(ApiEndpoints.joinTeam(teamId), data: body);
    if (data is Map) {
      return JoinResult.fromJson(Map<String, dynamic>.from(data));
    }
    return const JoinResult(status: JoinResultStatus.joined);
  }

  Future<TournamentTeamModel> join(String teamId, Map<String, dynamic> body) async =>
      parseTeam(await _api.post(ApiEndpoints.joinTeam(teamId), data: body));

  Future<void> leave(String teamId) => _api.post(ApiEndpoints.leaveTeam(teamId));

  Future<TournamentTeamModel> removeMember(String teamId, String userId) async =>
      parseTeam(await _api.post(ApiEndpoints.removeTeamMember(teamId, userId)));

  Future<TournamentTeamModel> transferCaptain(String teamId, String userId) async =>
      parseTeam(await _api.post(
        ApiEndpoints.transferCaptain(teamId),
        data: {'new_captain_id': userId, 'userId': userId},
      ));

  Future<TournamentTeamModel> setAcceptingSubstitutes(
      String teamId, bool value) async =>
      parseTeam(await _api.patch(
        ApiEndpoints.teamSubstitutes(teamId),
        data: {'accepting_substitutes': value, 'acceptingSubstitutes': value},
      ));

  Future<dynamic> registerTournament(String tournamentId, String teamId) async =>
      await _api.post(
        ApiEndpoints.registerTournament(tournamentId),
        data: {'team_id': teamId},
      );

  Future<dynamic> unregisterTournament(String tournamentId) async =>
      await _api.delete(
        ApiEndpoints.registerTournament(tournamentId),
      );

  // ── Section 2: Join Request Management API ──

  Future<List<JoinRequest>> ownerJoinRequests(String teamId) async {
    final d = await _api.get(ApiEndpoints.teamJoinRequests(teamId));
    if (d is List) {
      return d
          .map((e) => JoinRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (d is Map && d['requests'] is List) {
      return (d['requests'] as List)
          .map((e) => JoinRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<void> approveJoinRequest(String teamId, String requestId) async {
    await _api.post(ApiEndpoints.approveJoinRequest(teamId, requestId));
  }

  Future<void> rejectJoinRequest(String teamId, String requestId) async {
    await _api.post(ApiEndpoints.rejectJoinRequest(teamId, requestId));
  }

  Future<void> cancelJoinRequest(String requestId) async {
    await _api.post(ApiEndpoints.cancelJoinRequest(requestId));
  }

  Future<List<JoinRequest>> myJoinRequests([String status = 'PENDING']) async {
    final d = await _api.get(ApiEndpoints.myJoinRequests(status));
    if (d is List) {
      return d
          .map((e) => JoinRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (d is Map && d['requests'] is List) {
      return (d['requests'] as List)
          .map((e) => JoinRequest.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  // ── Section 3: Roster Update & Registration Approval API ──

  Future<TournamentTeamModel> updatePlayingRoster(
      String teamId, List<String> mainUserIds) async {
    final data = await _api.put(
      ApiEndpoints.updatePlayingRoster(teamId),
      data: {'main_user_ids': mainUserIds},
    );
    return parseTeam(data);
  }

  Future<TournamentTeamModel> cancelRegistrationRequest(
      String tid, String teamId) async {
    final data = await _api.post(
      ApiEndpoints.cancelRegistrationRequest(tid, teamId),
    );
    return parseTeam(data);
  }

  Future<List<RegistrationApproval>> myApprovals([String status = 'PENDING']) async {
    final d = await _api.get(ApiEndpoints.myRegistrationApprovals(status));
    if (d is List) {
      return d
          .map((e) => RegistrationApproval.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (d is Map && d['approvals'] is List) {
      return (d['approvals'] as List)
          .map((e) => RegistrationApproval.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return [];
  }

  Future<RegistrationApproval> approvalDetail(String id) async {
    final d = await _api.get(ApiEndpoints.registrationApprovalDetail(id));
    final map = (d is Map && d['approval'] is Map) ? d['approval'] : d;
    return RegistrationApproval.fromJson(Map<String, dynamic>.from(map as Map));
  }

  Future<void> approveRegistration(String id) async {
    await _api.post(ApiEndpoints.approveRegistration(id));
  }

  Future<void> declineRegistration(String id) async {
    await _api.post(ApiEndpoints.declineRegistration(id));
  }

  // ── Section 7: Post-Confirmation Roster Change API ──

  Future<TournamentTeamModel> requestRosterChange(
    String teamId,
    List<String> mainUserIds, {
    List<String>? removeUserIds,
  }) async {
    final data = await _api.post(
      '/teams/$teamId/roster-change',
      data: {
        'main_user_ids': mainUserIds,
        if (removeUserIds != null && removeUserIds.isNotEmpty)
          'remove_user_ids': removeUserIds,
      },
    );
    return parseTeam(data);
  }

  Future<TournamentTeamModel> cancelRosterChange(String teamId) async {
    final data = await _api.post('/teams/$teamId/roster-change/cancel');
    return parseTeam(data);
  }
}

class _TeamException implements Exception {
  const _TeamException(this.message);
  final String message;
}

class TeamState {
  final TournamentTeamModel? team;
  final TeamPreview? previewTeam;
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
    TeamPreview? previewTeam,
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
  String get _taskKey => 'my_team_$arg';

  @override
  TeamState build(String arg) {
    final syncManager = ref.watch(realTimeSyncManagerProvider);

    ref.onDispose(() {
      syncManager.unregister(_taskKey);
    });

    syncManager.register(
      key: _taskKey,
      fetcher: () => _repo.myTeam(arg),
      onChanged: (data) {
        if (data == null) {
          state = state.copyWith(clearTeam: true);
        } else if (data is TournamentTeamModel) {
          state = state.copyWith(team: data);
        }
      },
      runImmediately: true,
    );

    return const TeamState();
  }

  String get _tid => arg;
  TeamRepository get _repo => ref.read(teamRepositoryProvider);

  static String _message(Object e) {
    if (e is _TeamException) return e.message;
    if (e is DioException) {
      final data = e.response?.data;
      final errCode = data is Map ? (data['code'] ?? data['error_code'])?.toString() : null;
      switch (errCode) {
        case 'ROSTER_LOCKED_BY_TIME':
          return 'Roster changes are locked by time limit';
        case 'ROSTER_CHANGE_PENDING':
          return 'A roster change request is already pending approval';
        case 'NO_ROSTER_CHANGE':
          return 'No roster changes were submitted';
        case 'DUO_NO_MANAGER':
          return 'Manager role is not available in Duo mode';
        case 'ROSTER_FULL':
          return 'Roster is full. Remove a player or reject this request';
        case 'TEAM_ROSTER_LOCKED':
          return 'Team registration is locked';
        case 'JOIN_REQUEST_LIMIT':
          return 'You have too many pending requests';
        case 'ALREADY_IN_TOURNAMENT':
        case 'ALREADY_REGISTERED':
          return 'You are already part of a team in this tournament';
        case 'COMPETITION_STARTED':
          return 'Registration can no longer be cancelled';
        case 'NOT_TEAM_OWNER':
          return 'Only the team owner can perform this action';
        case 'JOIN_REQUEST_NOT_PENDING':
          return 'This join request is no longer pending';
        case 'JOIN_REQUEST_NOT_FOUND':
          return 'Join request not found';
        case 'ROSTER_VERSION_MISMATCH':
        case 'APPROVAL_NOT_PENDING':
          return 'This request is no longer valid because the roster changed';
        case 'REGISTRATION_NOT_PENDING':
          return 'This registration request is no longer pending';
        case 'APPROVAL_NOT_FOUND':
          return 'Approval request not found';
        case 'NOT_APPROVER':
          return 'You are not an authorized approver for this request';
        case 'LEADER_MUST_PLAY':
          return 'The team leader must be in the playing roster';
        case 'MANAGER_CANNOT_PLAY':
          return 'The manager cannot be in the playing roster';
        case 'SUBSTITUTE_LIMIT':
          return 'Substitute limit exceeded';
        case 'INVALID_PLAYING_ROSTER':
          return 'Invalid playing roster configuration';
        case 'INVALID_MEMBER_COUNT':
        case 'INVALID_ROSTER_SIZE':
          return 'Team must have 4 confirmed main playing members to register.';
        case 'NON_LEADER_REGISTRATION_FORBIDDEN':
          return 'Only the team leader or manager can register for the tournament.';
        case 'PAID_TOURNAMENTS_UNAVAILABLE':
          return 'Paid entry is not available yet';
        case 'TOURNAMENT_FULL':
        case 'CAPACITY_FULL':
        case 'SLOTS_FULL':
          return 'Tournament is full. Registration is closed.';
        case 'TOURNAMENT_NOT_LIVE':
        case 'NOT_LIVE':
          return 'Registration is only available when tournament is LIVE.';
        case 'TEAM_NOT_FOUND':
          return 'Team not found. Please check the code and try again.';
        case 'TEAM_FULL':
          return 'This team is full.';
        case 'ALREADY_IN_TEAM':
          return 'You are already part of a team in this tournament.';
        case 'REGISTRATION_CLOSED':
          return 'Registration for this tournament has ended.';
        case 'CAPTAIN_MUST_TRANSFER':
          return 'Transfer ownership/captaincy before leaving the team.';
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

  /// Helper to sync tournament team to persistent squad state
  Future<void> _syncTeamToSquad(TournamentTeamModel team) async {
    if (team.isDuoMode || team.isSoloMode || team.maxMainPlayers <= 2) {
      return; // Duo and Solo teams must never appear in or change MySquad screens
    }
    final squadOwnerRole = team.isManagerOwned ? SquadRole.manager : SquadRole.leader;
    final squadMembers = team.members.map((m) {
      SquadRole role;
      if (m.isCaptain) {
        role = SquadRole.leader;
      } else if (m.isManager) {
        role = SquadRole.manager;
      } else {
        role = SquadRole.member;
      }
      return SquadMemberModel(
        userId: m.userId,
        name: m.name,
        avatarUrl: m.avatarUrl,
        ign: m.ign,
        uid: m.uid,
        role: role,
        rosterType: m.isSubstitute ? SquadRosterType.substitute : SquadRosterType.main,
      );
    }).toList();

    await ref.read(squadProvider.notifier).createOrSaveSquadFromRoster(
      squadName: team.name,
      tag: team.tag,
      members: squadMembers,
      ownerRole: squadOwnerRole,
    );
  }

  Future<bool> createTeam({
    required String teamName,
    required String tag,
    required String playerName,
    String ign = '',
    required String uid,
    TeamOwnerRole ownerRole = TeamOwnerRole.leader,
    String? logoUrl,
    bool acceptingSubstitutes = true,
  }) =>
      _guard(() async {
        final t = await _repo.create(_tid, {
          'name': teamName,
          'tag': tag,
          'logo_url': logoUrl ?? '',
          'owner_role': ownerRole.name.toUpperCase(),
          'accepting_substitutes': acceptingSubstitutes,
          'player': {'name': playerName, 'ign': ign, 'uid': uid},
        });
        state = state.copyWith(team: t);

        if (state.team != null) {
          await _syncTeamToSquad(state.team!);
        }
      });

  /// "Join with Previous Team": Leader or Manager initializes tournament lobby with previous squad members in pending state.
  Future<bool> createTeamWithPreviousSquad(SquadModel squad) => _guard(() async {
    final owner = squad.owner;
    final ownerUserId = owner?.userId ?? ref.read(squadProvider).viewerUserId;
    final isManager = squad.isManagerOwned;

    final teamMembers = <TeamMemberModel>[];

    // 1. Owner (Confirmed)
    teamMembers.add(
      TeamMemberModel(
        userId: ownerUserId,
        name: owner?.name ?? (isManager ? 'Apex Manager' : 'Phoenix Captain'),
        ign: owner?.ign ?? (isManager ? 'APEX_MGR' : '★PHOENIX★'),
        uid: owner?.uid ?? '827364129',
        role: isManager ? TeamRole.manager : TeamRole.captain,
        rosterType: RosterType.main,
        status: TeamMemberStatus.confirmed,
      ),
    );

    // 2. Main squad members (Pending / Invited state)
    final mainMembersToInvite = isManager
        ? squad.mainPlayers
        : squad.mainPlayers.where((m) => m.userId != ownerUserId);

    for (final member in mainMembersToInvite) {
      teamMembers.add(
        TeamMemberModel(
          userId: member.userId,
          name: member.name,
          ign: member.ign,
          uid: member.uid,
          role: TeamRole.member,
          rosterType: RosterType.main,
          status: TeamMemberStatus.pending,
        ),
      );
    }

    final team = TournamentTeamModel(
      id: 'team_${DateTime.now().millisecondsSinceEpoch}',
      tournamentId: _tid,
      code: 'PREV-${squad.tag.isNotEmpty ? squad.tag : "SQUAD"}',
      name: squad.name,
      tag: squad.tag,
      logoUrl: squad.logoUrl,
      captainId: ownerUserId,
      ownerRole: isManager ? TeamOwnerRole.manager : TeamOwnerRole.leader,
      viewerUserId: ownerUserId,
      members: teamMembers,
      status: TeamRegistrationStatus.forming,
      registrationState: TeamRegistrationState.forming,
    );

    state = state.copyWith(team: team);

    // Trigger sending invitations to squad members
    await ref.read(squadProvider.notifier).sendPreviousTeamInvitations(_tid);

    if (state.team != null) {
      await _syncTeamToSquad(state.team!);
    }
  });

  Future<bool> lookupTeam(String code) => _guard(() async {
    try {
      final preview = await _repo.lookupTeamPreview(_tid, code);
      state = state.copyWith(previewTeam: preview);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const _TeamException(
            'Team not found. Please check the code and try again.');
      }
      rethrow;
    }
  });

  /// Request to join or join team directly
  Future<JoinResult?> joinTeam({
    required String playerName,
    String ign = '',
    required String uid,
  }) async {
    JoinResult? result;
    final ok = await _guard(() async {
      final preview = state.previewTeam!;
      final isSub = preview.isMainFull;
      result = await _repo.requestToJoin(preview.id, {
        'invite_code': preview.code,
        'as_substitute': isSub,
        'rosterType': isSub ? 'SUBSTITUTE' : 'MAIN',
        'player': {'name': playerName, 'ign': ign, 'uid': uid},
      });

      if (result != null && result!.status == JoinResultStatus.joined) {
        if (result!.team != null) {
          state = state.copyWith(team: result!.team, clearPreview: true);
        } else {
          final t = await _repo.myTeam(_tid);
          if (t != null) state = state.copyWith(team: t, clearPreview: true);
        }
        if (state.team != null) {
          await _syncTeamToSquad(state.team!);
        }
      }
    });
    if (!ok) return null;
    return result;
  }

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
    try {
      await _repo.leave(state.team!.id);
    } catch (_) {}
    state = state.copyWith(clearTeam: true);
  });

  Future<bool> registerSolo({required String ign, required String uid}) => _guard(() async {
        await _repo.registerTournament(_tid, '');
        ref.read(profileProvider.notifier).updateFullProfile(
          name: ign.isNotEmpty ? ign : (ref.read(profileProvider).user?.name ?? ''),
          freeFireUid: uid,
          inGameName: ign,
        );
        ref.invalidate(tournamentByIdProvider(_tid));
      });

  Future<bool> completeRegistration({String mode = 'SQUAD'}) => _guard(() async {
        final team = state.team;
        if (team == null) return;

        final confirmedCount = team.confirmedMainCount;
        final modeUpper = mode.trim().toUpperCase();

        if (modeUpper == 'SQUAD' || modeUpper == 'CLASH_SQUAD' || modeUpper.contains('SQUAD') || modeUpper.contains('CLASH') || modeUpper.isEmpty) {
          if (confirmedCount < 4) {
            throw const _TeamException('Team must have 4 confirmed main playing members to register.');
          }
        } else if (modeUpper == 'DUO' || modeUpper.contains('DUO')) {
          if (confirmedCount < 2) {
            throw const _TeamException('Duo BR requires 2 confirmed main playing members.');
          }
        } else if (modeUpper == 'SOLO' || modeUpper.contains('SOLO')) {
          if (confirmedCount < 1) {
            throw const _TeamException('Solo BR requires 1 registered player.');
          }
        }

        final res = await _repo.registerTournament(_tid, team.id);
        if (res is Map && res['team'] != null) {
          state = state.copyWith(team: _repo.parseTeam(res));
        } else {
          final updated = await _repo.myTeam(_tid);
          if (updated != null) {
            state = state.copyWith(team: updated);
          }
        }

        // Save squad persistently upon registration completion
        if (state.team != null) {
          await _syncTeamToSquad(state.team!);
        }
      });

  Future<bool> updatePlayingRoster(List<String> mainUserIds) => _guard(() async {
        final t = await _repo.updatePlayingRoster(state.team!.id, mainUserIds);
        state = state.copyWith(team: t);
      });

  Future<bool> cancelRegistrationRequest() => _guard(() async {
        final t = await _repo.cancelRegistrationRequest(_tid, state.team!.id);
        state = state.copyWith(team: t);
      });

  Future<bool> requestRosterChange({
    required List<String> mainUserIds,
    List<String>? removeUserIds,
  }) => _guard(() async {
        final t = await _repo.requestRosterChange(
          state.team!.id,
          mainUserIds,
          removeUserIds: removeUserIds,
        );
        state = state.copyWith(team: t);
      });

  Future<bool> cancelRosterChange() => _guard(() async {
        final t = await _repo.cancelRosterChange(state.team!.id);
        state = state.copyWith(team: t);
      });

  Future<bool> leaveWaitlist() => _guard(() async {
        await _repo.unregisterTournament(_tid);
        final updated = await _repo.myTeam(_tid);
        if (updated != null) {
          state = state.copyWith(team: updated);
        } else {
          state = state.copyWith(clearTeam: true);
        }
        ref.invalidate(tournamentByIdProvider(_tid));
      });
}

final teamProvider =
NotifierProvider.family<TeamNotifier, TeamState, String>(TeamNotifier.new);

// ── Section 2: Owner Join Requests Notifier / Provider ──

class OwnerJoinRequestsState {
  final List<JoinRequest> requests;
  final bool isLoading;
  final String? error;
  final String? actioningRequestId; // ID of request currently approving/rejecting

  const OwnerJoinRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
    this.actioningRequestId,
  });

  OwnerJoinRequestsState copyWith({
    List<JoinRequest>? requests,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? actioningRequestId,
    bool clearActioningRequestId = false,
  }) {
    return OwnerJoinRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      actioningRequestId: clearActioningRequestId ? null : (actioningRequestId ?? this.actioningRequestId),
    );
  }
}

class OwnerJoinRequestsNotifier extends FamilyNotifier<OwnerJoinRequestsState, String> {
  String get _teamId => arg;
  TeamRepository get _repo => ref.read(teamRepositoryProvider);
  String get _taskKey => 'owner_join_requests_$_teamId';

  @override
  OwnerJoinRequestsState build(String arg) {
    final syncManager = ref.watch(realTimeSyncManagerProvider);

    ref.onDispose(() {
      syncManager.unregister(_taskKey);
    });

    if (_teamId.isNotEmpty) {
      syncManager.register(
        key: _taskKey,
        fetcher: () => _repo.ownerJoinRequests(_teamId),
        onChanged: (data) {
          if (data is List<JoinRequest>) {
            state = state.copyWith(requests: data);
          }
        },
        runImmediately: true,
      );
    }

    return const OwnerJoinRequestsState();
  }

  Future<void> fetchRequests() async {
    if (_teamId.isEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.ownerJoinRequests(_teamId);
      state = state.copyWith(requests: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: TeamNotifier._message(e));
    }
  }

  Future<bool> approveRequest(String requestId) async {
    state = state.copyWith(actioningRequestId: requestId, clearError: true);
    try {
      await _repo.approveJoinRequest(_teamId, requestId);
      state = state.copyWith(clearActioningRequestId: true);
      await fetchRequests();
      return true;
    } catch (e) {
      state = state.copyWith(clearActioningRequestId: true, error: TeamNotifier._message(e));
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    state = state.copyWith(actioningRequestId: requestId, clearError: true);
    try {
      await _repo.rejectJoinRequest(_teamId, requestId);
      state = state.copyWith(clearActioningRequestId: true);
      await fetchRequests();
      return true;
    } catch (e) {
      state = state.copyWith(clearActioningRequestId: true, error: TeamNotifier._message(e));
      return false;
    }
  }
}

final ownerJoinRequestsProvider =
NotifierProvider.family<OwnerJoinRequestsNotifier, OwnerJoinRequestsState, String>(
  OwnerJoinRequestsNotifier.new,
);

// ── Section 2: User's Pending Requests Notifier / Provider ──

class MyPendingRequestsState {
  final List<JoinRequest> pendingRequests;
  final bool isLoading;
  final String? error;

  const MyPendingRequestsState({
    this.pendingRequests = const [],
    this.isLoading = false,
    this.error,
  });

  MyPendingRequestsState copyWith({
    List<JoinRequest>? pendingRequests,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MyPendingRequestsState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MyPendingRequestsNotifier extends Notifier<MyPendingRequestsState> {
  TeamRepository get _repo => ref.read(teamRepositoryProvider);
  static const String _taskKey = 'my_pending_requests';

  @override
  MyPendingRequestsState build() {
    final syncManager = ref.watch(realTimeSyncManagerProvider);

    ref.onDispose(() {
      syncManager.unregister(_taskKey);
    });

    syncManager.register(
      key: _taskKey,
      fetcher: () => _repo.myJoinRequests('PENDING'),
      onChanged: (data) {
        if (data is List<JoinRequest>) {
          state = state.copyWith(pendingRequests: data);
        }
      },
      runImmediately: true,
    );

    return const MyPendingRequestsState();
  }

  Future<void> fetchPendingRequests() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.myJoinRequests('PENDING');
      state = state.copyWith(pendingRequests: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: TeamNotifier._message(e));
    }
  }

  Future<bool> cancelRequest(String requestId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.cancelJoinRequest(requestId);
      state = state.copyWith(isLoading: false);
      await fetchPendingRequests();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: TeamNotifier._message(e));
      return false;
    }
  }
}

final myPendingRequestsProvider =
NotifierProvider<MyPendingRequestsNotifier, MyPendingRequestsState>(
  MyPendingRequestsNotifier.new,
);

// ── Section 3: Registration Approvals Notifier & Provider ──

class ApprovalsState {
  final List<RegistrationApproval> pendingApprovals;
  final bool isLoading;
  final String? error;

  const ApprovalsState({
    this.pendingApprovals = const [],
    this.isLoading = false,
    this.error,
  });

  ApprovalsState copyWith({
    List<RegistrationApproval>? pendingApprovals,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ApprovalsState(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ApprovalsNotifier extends Notifier<ApprovalsState> {
  TeamRepository get _repo => ref.read(teamRepositoryProvider);
  static const String _taskKey = 'my_registration_approvals';

  @override
  ApprovalsState build() {
    final syncManager = ref.watch(realTimeSyncManagerProvider);

    ref.onDispose(() {
      syncManager.unregister(_taskKey);
    });

    syncManager.register(
      key: _taskKey,
      fetcher: () => _repo.myApprovals('PENDING'),
      onChanged: (data) {
        if (data is List<RegistrationApproval>) {
          state = state.copyWith(pendingApprovals: data);
        }
      },
      runImmediately: true,
    );

    return const ApprovalsState();
  }

  Future<void> fetchApprovals() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.myApprovals('PENDING');
      state = state.copyWith(pendingApprovals: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: TeamNotifier._message(e));
    }
  }

  Future<bool> approve(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.approveRegistration(id);
      state = state.copyWith(isLoading: false);
      await fetchApprovals();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: TeamNotifier._message(e));
      return false;
    }
  }

  Future<bool> decline(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.declineRegistration(id);
      state = state.copyWith(isLoading: false);
      await fetchApprovals();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: TeamNotifier._message(e));
      return false;
    }
  }
}

final approvalsProvider = NotifierProvider<ApprovalsNotifier, ApprovalsState>(
  ApprovalsNotifier.new,
);
