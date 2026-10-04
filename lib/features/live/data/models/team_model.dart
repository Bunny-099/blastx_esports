import 'team_member_model.dart';

/// ============================================================
/// TOURNAMENT TEAM MODEL
/// ============================================================

enum TeamRegistrationStatus { forming, ready, registered, locked }

enum TeamOwnerRole { leader, manager }

class TournamentTeamModel {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String code;
  final String name;
  final String tag;
  final String logoUrl;
  final String captainId;
  final TeamOwnerRole ownerRole;
  final String viewerUserId;
  final List<TeamMemberModel> members;
  final int maxMainPlayers;
  final int maxSubstitutes;
  final TeamRegistrationStatus status;
  final bool registrationOpen;
  final bool acceptingSubstitutes;

  const TournamentTeamModel({
    required this.id,
    required this.tournamentId,
    required this.code,
    required this.name,
    required this.captainId,
    this.ownerRole = TeamOwnerRole.leader,
    this.tournamentName = '',
    this.tag = '',
    this.logoUrl = '',
    this.viewerUserId = '',
    this.members = const [],
    this.maxMainPlayers = 4,
    this.maxSubstitutes = 2,
    this.status = TeamRegistrationStatus.forming,
    this.registrationOpen = true,
    this.acceptingSubstitutes = false,
  });

  bool get isManagerOwned => ownerRole == TeamOwnerRole.manager;

  /// Main playing players (Manager is non-playing so excluded from player slots)
  List<TeamMemberModel> get mainPlayers => members
      .where((m) => !m.isSubstitute && m.isPlaying)
      .toList()
    ..sort((a, b) =>
    a.isCaptain == b.isCaptain ? 0 : (a.isCaptain ? -1 : 1));

  /// Substitute playing players
  List<TeamMemberModel> get substitutes =>
      members.where((m) => m.isSubstitute && m.isPlaying).toList();

  int get mainCount => mainPlayers.length;
  int get substituteCount => substitutes.length;
  int get confirmedMainCount => mainPlayers.where((m) => m.isConfirmed).length;
  int get pendingMainCount => mainPlayers.where((m) => m.isPending).length;

  bool get isMainFull => mainCount >= maxMainPlayers;
  bool get isReady => confirmedMainCount >= maxMainPlayers;
  int get mainSlotsLeft => (maxMainPlayers - confirmedMainCount).clamp(0, maxMainPlayers);
  bool get canJoinAsSubstitute =>
      isMainFull && acceptingSubstitutes && substituteCount < maxSubstitutes;
  bool get isLocked =>
      status == TeamRegistrationStatus.locked || !registrationOpen;
  bool get isRegistered => status == TeamRegistrationStatus.registered;

  bool get viewerIsCaptain =>
      viewerUserId.isNotEmpty && viewerUserId == captainId;

  bool get viewerIsManager =>
      isManagerOwned && manager != null && manager!.userId == viewerUserId;

  bool get viewerIsOwner => viewerIsCaptain || viewerIsManager || viewerIsOwnerMember;

  bool get viewerIsOwnerMember => members.any(
        (m) => m.userId == viewerUserId && (m.isCaptain || m.isManager),
      );

  TeamMemberModel? get captain {
    for (final m in members) {
      if (m.isCaptain || m.userId == captainId) return m;
    }
    return null;
  }

  TeamMemberModel? get manager {
    for (final m in members) {
      if (m.isManager) return m;
    }
    if (isManagerOwned && viewerIsCaptain) {
      return captain;
    }
    return null;
  }

  TeamMemberModel? get owner => isManagerOwned ? manager ?? captain : captain;

  String get captainName => captain?.name ?? '';
  String get managerName => manager?.name ?? '';
  String get ownerName => isManagerOwned ? (managerName.isNotEmpty ? managerName : captainName) : captainName;

  String get shareText =>
      'Join my team "$name" for ${tournamentName.isEmpty ? 'the tournament' : tournamentName} '
          'on BlastiX Arena! 🔥\nTeam Code: $code';

  TournamentTeamModel copyWith({
    String? id,
    String? tournamentId,
    String? tournamentName,
    String? code,
    String? name,
    String? tag,
    String? logoUrl,
    String? captainId,
    TeamOwnerRole? ownerRole,
    String? viewerUserId,
    List<TeamMemberModel>? members,
    int? maxMainPlayers,
    int? maxSubstitutes,
    TeamRegistrationStatus? status,
    bool? registrationOpen,
    bool? acceptingSubstitutes,
  }) {
    return TournamentTeamModel(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      code: code ?? this.code,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      logoUrl: logoUrl ?? this.logoUrl,
      captainId: captainId ?? this.captainId,
      ownerRole: ownerRole ?? this.ownerRole,
      viewerUserId: viewerUserId ?? this.viewerUserId,
      members: members ?? this.members,
      maxMainPlayers: maxMainPlayers ?? this.maxMainPlayers,
      maxSubstitutes: maxSubstitutes ?? this.maxSubstitutes,
      status: status ?? this.status,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      acceptingSubstitutes: acceptingSubstitutes ?? this.acceptingSubstitutes,
    );
  }

  factory TournamentTeamModel.fromJson(Map<String, dynamic> json) {
    final statusRaw = ((json['registration_status'] ?? json['status']) as String? ?? 'forming').toLowerCase();
    TeamRegistrationStatus parsedStatus;
    if (statusRaw == 'confirmed' || statusRaw == 'registered') {
      parsedStatus = TeamRegistrationStatus.registered;
    } else if (statusRaw == 'locked') {
      parsedStatus = TeamRegistrationStatus.locked;
    } else if (statusRaw == 'ready') {
      parsedStatus = TeamRegistrationStatus.ready;
    } else {
      parsedStatus = TeamRegistrationStatus.forming;
    }

    final ownerRoleRaw = (json['owner_role'] ?? json['ownerRole'] ?? 'leader').toString().toLowerCase();
    final ownerRoleParsed = ownerRoleRaw == 'manager' ? TeamOwnerRole.manager : TeamOwnerRole.leader;

    final rosterInfo = json['roster_info'] is Map ? json['roster_info'] as Map<String, dynamic> : null;

    return TournamentTeamModel(
      id: (json['id'] ?? '') as String,
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
      tournamentName: (json['tournamentName'] ?? '') as String,
      code: (json['invite_code'] ?? json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      tag: (json['tag'] ?? '') as String,
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '') as String,
      captainId: (json['captain_id'] ?? json['captainId'] ?? '') as String,
      ownerRole: ownerRoleParsed,
      viewerUserId: (json['viewerUserId'] ?? '') as String,
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      maxMainPlayers: (rosterInfo?['max_main_players'] ?? json['maxMainPlayers'] as num?)?.toInt() ?? 4,
      maxSubstitutes: (rosterInfo?['max_substitutes'] ?? json['maxSubstitutes'] as num?)?.toInt() ?? 2,
      status: parsedStatus,
      registrationOpen: (json['registrationOpen'] as bool?) ?? true,
      acceptingSubstitutes: (json['accepting_substitutes'] ?? json['acceptingSubstitutes'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'tournamentName': tournamentName,
    'code': code,
    'name': name,
    'tag': tag,
    'logoUrl': logoUrl,
    'captainId': captainId,
    'ownerRole': ownerRole.name.toUpperCase(),
    'viewerUserId': viewerUserId,
    'members': members.map((e) => e.toJson()).toList(),
    'maxMainPlayers': maxMainPlayers,
    'maxSubstitutes': maxSubstitutes,
    'status': status.name.toUpperCase(),
    'registrationOpen': registrationOpen,
    'acceptingSubstitutes': acceptingSubstitutes,
  };
}
