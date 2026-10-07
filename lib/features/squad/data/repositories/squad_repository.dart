import 'package:blastix_esports/core/api/api_client.dart';
import 'package:blastix_esports/core/api/api_endpoints.dart';
import '../models/squad_invitation_model.dart';
import '../models/squad_model.dart';

/// Abstract Squad Repository Interface
abstract class SquadRepository {
  Future<SquadModel?> getMySquad();
  Future<SquadModel> createOrSaveSquad([SquadModel? squad]);
  Future<void> leaveSquad(String squadId, String userId);
  Future<SquadModel> removeMember(String squadId, String userId);
  Future<SquadModel> transferLeadership(String squadId, String newLeaderId);
  Future<SquadModel> updateMemberRole(String squadId, String userId, SquadRosterType newRosterType);
  Future<SquadModel> swapPlayers(String squadId, String mainUserId, String subUserId);
  Future<Map<String, dynamic>> getWaitlistDetails(String squadId);
  Future<List<SquadInvitationModel>> getPendingInvitations();
  Future<Map<String, dynamic>> sendPreviousTeamInvitations(String squadId, String tournamentId);
  Future<SquadInvitationModel> respondToInvitation(String invitationId, bool accept);
}

/// Real API Client Implementation for Persistent Squad System
class RealSquadRepository implements SquadRepository {
  final ApiClient _api;

  RealSquadRepository(this._api);

  @override
  Future<SquadModel?> getMySquad() async {
    try {
      final data = await _api.get(ApiEndpoints.mySquad);
      if (data == null) return null;

      Map<String, dynamic>? squadMap;
      if (data is Map) {
        if (data.containsKey('squad')) {
          final s = data['squad'];
          if (s is Map) squadMap = Map<String, dynamic>.from(s);
        } else if (data['id'] != null || data['name'] != null) {
          squadMap = Map<String, dynamic>.from(data);
        }
      }

      if (squadMap == null) return null;
      final squad = SquadModel.fromJson(squadMap);
      if (squad.id.isEmpty && squad.name.isEmpty) return null;
      return squad;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SquadModel> createOrSaveSquad([SquadModel? squad]) async {
    final payload = squad != null ? squad.toJson() : {};
    final data = await _api.post(ApiEndpoints.createSquad, data: payload);
    final map = (data is Map && data['squad'] is Map) ? data['squad'] : data;
    return SquadModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  @override
  Future<void> leaveSquad(String squadId, String userId) async {
    await _api.post(
      ApiEndpoints.leaveSquad(squadId),
      data: {'user_id': userId},
    );
  }

  @override
  Future<SquadModel> removeMember(String squadId, String userId) async {
    final data = await _api.post(ApiEndpoints.removeSquadMember(squadId, userId));
    final map = (data is Map && data['squad'] is Map) ? data['squad'] : data;
    return SquadModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  @override
  Future<SquadModel> transferLeadership(String squadId, String newLeaderId) async {
    final data = await _api.post(
      ApiEndpoints.transferSquadLeader(squadId),
      data: {'new_leader_id': newLeaderId},
    );
    final map = (data is Map && data['squad'] is Map) ? data['squad'] : data;
    return SquadModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  @override
  Future<SquadModel> updateMemberRole(
    String squadId,
    String userId,
    SquadRosterType newRosterType,
  ) async {
    final data = await _api.patch(
      ApiEndpoints.updateSquadMemberRole(squadId, userId),
      data: {'roster_type': newRosterType.name.toUpperCase()},
    );
    final map = (data is Map && data['squad'] is Map) ? data['squad'] : data;
    return SquadModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  @override
  Future<SquadModel> swapPlayers(
    String squadId,
    String mainUserId,
    String subUserId,
  ) async {
    final data = await _api.post(
      ApiEndpoints.swapSquadMembers(squadId),
      data: {'main_user_id': mainUserId, 'sub_user_id': subUserId},
    );
    final map = (data is Map && data['squad'] is Map) ? data['squad'] : data;
    return SquadModel.fromJson(Map<String, dynamic>.from(map as Map));
  }

  @override
  Future<Map<String, dynamic>> getWaitlistDetails(String squadId) async {
    try {
      final data = await _api.get(ApiEndpoints.squadWaitlist(squadId));
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return {
      'status': 'Waitlisted',
      'reason': 'Roster incomplete or waiting for tournament lobby slot assignment.',
      'main_players_count': 3,
      'required_players': 4,
    };
  }

  @override
  Future<List<SquadInvitationModel>> getPendingInvitations() async {
    try {
      final data = await _api.get(ApiEndpoints.pendingInvitations);
      final rawList = (data is Map && data['invitations'] is List)
          ? data['invitations'] as List
          : (data is List ? data : []);
      return rawList
          .map((e) => SquadInvitationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> sendPreviousTeamInvitations(
    String squadId,
    String tournamentId,
  ) async {
    final data = await _api.post(ApiEndpoints.sendSquadInvitations(squadId, tournamentId));
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  @override
  Future<SquadInvitationModel> respondToInvitation(
    String invitationId,
    bool accept,
  ) async {
    final data = await _api.post(
      ApiEndpoints.respondInvitation(invitationId),
      data: {'action': accept ? 'ACCEPT' : 'REJECT'},
    );
    final map = (data is Map && data['invitation'] is Map) ? data['invitation'] : data;
    return SquadInvitationModel.fromJson(Map<String, dynamic>.from(map as Map));
  }
}
