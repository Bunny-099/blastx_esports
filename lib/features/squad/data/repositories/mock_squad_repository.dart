import 'dart:async';
import '../models/squad_invitation_model.dart';
import '../models/squad_model.dart';
import 'squad_repository.dart';

/// Fake / Mock Repository for Persistent Squad System
class MockSquadRepository implements SquadRepository {
  // Flag to simulate empty squad state for testing first-time flow
  bool forceEmptySquad = false;
  bool forceError = false;

  late SquadModel? _currentSquad;
  final List<SquadInvitationModel> _invitations = [];

  MockSquadRepository() {
    _initSampleData();
  }

  void _initSampleData() {
    final now = DateTime.now();
    _currentSquad = SquadModel(
      id: 'squad_alpha_001',
      name: 'ALPHA ELITE',
      tag: 'AEL',
      logoUrl: 'assets/images/top_banner.jpg',
      leaderId: 'user_001',
      ownerRole: SquadRole.leader,
      createdAt: now.subtract(const Duration(days: 30)),
      members: [
        SquadMemberModel(
          userId: 'user_001',
          name: 'Phoenix (You)',
          avatarUrl: '',
          ign: '★PHOENIX★',
          uid: '827364129',
          role: SquadRole.leader,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 30)),
        ),
        SquadMemberModel(
          userId: 'user_002',
          name: 'Viper Pro',
          avatarUrl: '',
          ign: 'VIPER⚡99',
          uid: '918237465',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 28)),
        ),
        SquadMemberModel(
          userId: 'user_003',
          name: 'Shadow Sniper',
          avatarUrl: '',
          ign: 'SHADOW🎯',
          uid: '736182940',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 25)),
        ),
        SquadMemberModel(
          userId: 'user_004',
          name: 'Ghost Rider',
          avatarUrl: '',
          ign: 'GHOST👻',
          uid: '625143987',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 20)),
        ),
        SquadMemberModel(
          userId: 'user_005',
          name: 'Blaze Sub',
          avatarUrl: '',
          ign: 'BLAZE🔥',
          uid: '514238976',
          role: SquadRole.member,
          rosterType: SquadRosterType.substitute,
          joinedAt: now.subtract(const Duration(days: 15)),
        ),
        SquadMemberModel(
          userId: 'user_006',
          name: 'Frost Sub',
          avatarUrl: '',
          ign: 'FROST❄️',
          uid: '403127865',
          role: SquadRole.member,
          rosterType: SquadRosterType.substitute,
          joinedAt: now.subtract(const Duration(days: 10)),
        ),
      ],
    );

    // Initial sample invitation
    _invitations.add(
      SquadInvitationModel(
        id: 'inv_001',
        squadId: 'squad_alpha_001',
        squadName: 'ALPHA ELITE',
        leaderId: 'user_001',
        leaderName: 'Phoenix Captain',
        tournamentId: 'tourney_ff_001',
        tournamentName: 'BlastX Grand Invitational S4',
        inviteeUserId: 'user_002',
        inviteeName: 'Viper Pro',
        status: InvitationStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    );
  }

  void resetToEmpty() {
    _currentSquad = null;
    forceEmptySquad = true;
  }

  void resetToDefaultSquad() {
    forceEmptySquad = false;
    _initSampleData();
  }

  void resetToManagerSquad() {
    forceEmptySquad = false;
    final now = DateTime.now();
    _currentSquad = SquadModel(
      id: 'squad_omega_999',
      name: 'OMEGA LEGENDS',
      tag: 'OMG',
      logoUrl: 'assets/images/top_banner.jpg',
      leaderId: 'user_001',
      ownerRole: SquadRole.manager,
      createdAt: now.subtract(const Duration(days: 45)),
      members: [
        SquadMemberModel(
          userId: 'user_001',
          name: 'Apex Manager (You)',
          avatarUrl: '',
          ign: 'APEX_MGR',
          uid: '100000001',
          role: SquadRole.manager,
          rosterType: SquadRosterType.main, // non-playing manager
          joinedAt: now.subtract(const Duration(days: 45)),
        ),
        SquadMemberModel(
          userId: 'user_002',
          name: 'Phoenix Pro',
          avatarUrl: '',
          ign: '★PHOENIX★',
          uid: '827364129',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 40)),
        ),
        SquadMemberModel(
          userId: 'user_003',
          name: 'Viper Speed',
          avatarUrl: '',
          ign: 'VIPER⚡99',
          uid: '918237465',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 38)),
        ),
        SquadMemberModel(
          userId: 'user_004',
          name: 'Shadow Aim',
          avatarUrl: '',
          ign: 'SHADOW🎯',
          uid: '736182940',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 35)),
        ),
        SquadMemberModel(
          userId: 'user_005',
          name: 'Ghost Force',
          avatarUrl: '',
          ign: 'GHOST👻',
          uid: '625143987',
          role: SquadRole.member,
          rosterType: SquadRosterType.main,
          joinedAt: now.subtract(const Duration(days: 30)),
        ),
        SquadMemberModel(
          userId: 'user_006',
          name: 'Blaze Sub',
          avatarUrl: '',
          ign: 'BLAZE🔥',
          uid: '514238976',
          role: SquadRole.member,
          rosterType: SquadRosterType.substitute,
          joinedAt: now.subtract(const Duration(days: 20)),
        ),
      ],
    );
  }

  @override
  Future<SquadModel?> getMySquad() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (forceError) {
      throw Exception('Network error fetching squad details.');
    }
    if (forceEmptySquad) return null;
    return _currentSquad;
  }

  @override
  Future<SquadModel> createOrSaveSquad([SquadModel? squad]) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (squad != null) {
      _currentSquad = squad;
    }
    forceEmptySquad = false;
    return _currentSquad ??
        SquadModel(
          id: 'squad_${DateTime.now().millisecondsSinceEpoch}',
          name: 'NEW SQUAD',
          leaderId: 'user_001',
        );
  }

  @override
  Future<SquadModel> removeMember(String squadId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentSquad == null) throw Exception('Squad not found.');

    final updatedMembers = _currentSquad!.members.where((m) => m.userId != userId).toList();
    _currentSquad = _currentSquad!.copyWith(members: updatedMembers);
    return _currentSquad!;
  }

  @override
  Future<SquadModel> transferLeadership(String squadId, String newLeaderId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentSquad == null) throw Exception('Squad not found.');

    final newRole = _currentSquad!.ownerRole;
    final updatedMembers = _currentSquad!.members.map((m) {
      if (m.userId == newLeaderId) {
        return m.copyWith(role: newRole);
      } else if (m.isLeader || m.isManager) {
        return m.copyWith(role: SquadRole.member);
      }
      return m;
    }).toList();

    _currentSquad = _currentSquad!.copyWith(
      leaderId: newLeaderId,
      members: updatedMembers,
    );
    return _currentSquad!;
  }

  @override
  Future<SquadModel> updateMemberRole(
    String squadId,
    String userId,
    SquadRosterType newRosterType,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentSquad == null) throw Exception('Squad not found.');

    final member = _currentSquad!.getMember(userId);
    if (member == null) throw Exception('Member not found in squad.');

    // Enforce limits
    if (newRosterType == SquadRosterType.main && _currentSquad!.isMainFull && member.isSubstitute) {
      throw Exception('Main squad is full (4/4). Move a main player to substitute first.');
    }
    if (newRosterType == SquadRosterType.substitute && _currentSquad!.isSubstituteFull && member.isMain) {
      throw Exception('Substitute slots full (2/2). Swap players instead.');
    }

    final updatedMembers = _currentSquad!.members.map((m) {
      if (m.userId == userId) {
        return m.copyWith(rosterType: newRosterType);
      }
      return m;
    }).toList();

    _currentSquad = _currentSquad!.copyWith(members: updatedMembers);
    return _currentSquad!;
  }

  @override
  Future<SquadModel> swapPlayers(
    String squadId,
    String mainUserId,
    String subUserId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentSquad == null) throw Exception('Squad not found.');

    final mainMember = _currentSquad!.getMember(mainUserId);
    final subMember = _currentSquad!.getMember(subUserId);

    if (mainMember == null || subMember == null) {
      throw Exception('Players not found for swap.');
    }

    final updatedMembers = _currentSquad!.members.map((m) {
      if (m.userId == mainUserId) {
        return m.copyWith(rosterType: SquadRosterType.substitute);
      } else if (m.userId == subUserId) {
        return m.copyWith(rosterType: SquadRosterType.main);
      }
      return m;
    }).toList();

    _currentSquad = _currentSquad!.copyWith(members: updatedMembers);
    return _currentSquad!;
  }

  @override
  Future<List<SquadInvitationModel>> getPendingInvitations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _invitations.where((i) => i.isPending).toList();
  }

  @override
  Future<Map<String, dynamic>> sendPreviousTeamInvitations(
    String squadId,
    String tournamentId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_currentSquad == null) return {};

    final now = DateTime.now();
    final inviteCandidates = _currentSquad!.isManagerOwned
        ? _currentSquad!.mainPlayers
        : _currentSquad!.mainPlayers.where((m) => m.userId != _currentSquad!.leaderId);

    final generatedInvites = <Map<String, dynamic>>[];

    for (final member in inviteCandidates) {
      final exists = _invitations.any(
        (i) => i.squadId == squadId && i.tournamentId == tournamentId && i.inviteeUserId == member.userId,
      );
      if (!exists) {
        final inv = SquadInvitationModel(
          id: 'inv_${DateTime.now().millisecondsSinceEpoch}_${member.userId}',
          squadId: squadId,
          squadName: _currentSquad!.name,
          leaderId: _currentSquad!.leaderId,
          leaderName: _currentSquad!.owner?.name ?? 'Squad Owner',
          tournamentId: tournamentId,
          tournamentName: 'Tournament #$tournamentId',
          inviteeUserId: member.userId,
          inviteeName: member.name,
          status: InvitationStatus.pending,
          createdAt: now,
        );
        _invitations.add(inv);
        generatedInvites.add(inv.toJson());
      }
    }

    return {
      'team_id': 'team_lobby_${DateTime.now().millisecondsSinceEpoch}',
      'invitations': generatedInvites,
    };
  }

  @override
  Future<SquadInvitationModel> respondToInvitation(
    String invitationId,
    bool accept,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index == -1) throw Exception('Invitation not found.');

    final inv = _invitations[index];
    final updated = inv.copyWith(
      status: accept ? InvitationStatus.accepted : InvitationStatus.rejected,
    );
    _invitations[index] = updated;

    // Requirement: "Reject: the player is NOT counted, and is removed from the squad"
    if (!accept && _currentSquad != null) {
      await removeMember(_currentSquad!.id, inv.inviteeUserId);
    }

    return updated;
  }
}
