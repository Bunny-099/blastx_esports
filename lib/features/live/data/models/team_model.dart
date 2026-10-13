import 'team_member_model.dart';

/// ============================================================
/// TOURNAMENT TEAM MODEL & JOIN REQUEST MODELS
/// ============================================================

bool _parseBool(dynamic val, [bool fallback = false]) {
  if (val is bool) return val;
  if (val is num) return val > 0;
  if (val is String) {
    final lower = val.toLowerCase().trim();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
  }
  return fallback;
}

int _parseInt(dynamic val, [int fallback = 0]) {
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val.trim()) ?? fallback;
  return fallback;
}

String _parseString(dynamic val, [String fallback = '']) {
  if (val == null) return fallback;
  return val.toString();
}

enum TeamRegistrationStatus { forming, ready, registered, locked }

enum TeamRegistrationState {
  forming,
  pendingPlayerApproval,
  pendingPayment,
  confirmed,
  waitlisted,
  rosterChangeRequired;

  String toUppercaseString() {
    switch (this) {
      case TeamRegistrationState.pendingPlayerApproval:
        return 'PENDING_PLAYER_APPROVAL';
      case TeamRegistrationState.pendingPayment:
        return 'PENDING_PAYMENT';
      case TeamRegistrationState.rosterChangeRequired:
        return 'ROSTER_CHANGE_REQUIRED';
      case TeamRegistrationState.confirmed:
        return 'CONFIRMED';
      case TeamRegistrationState.waitlisted:
        return 'WAITLISTED';
      case TeamRegistrationState.forming:
        return 'FORMING';
    }
  }
}

enum TeamOwnerRole { leader, manager }

enum ApprovalStatus {
  pending,
  approved,
  declined,
  notRequired;

  static ApprovalStatus fromString(String? val) {
    if (val == null) return ApprovalStatus.pending;
    switch (val.toUpperCase().trim()) {
      case 'APPROVED':
        return ApprovalStatus.approved;
      case 'DECLINED':
        return ApprovalStatus.declined;
      case 'NOT_REQUIRED':
      case 'NOTREQUIRED':
        return ApprovalStatus.notRequired;
      case 'PENDING':
      default:
        return ApprovalStatus.pending;
    }
  }

  String toUppercaseString() =>
      name == 'notRequired' ? 'NOT_REQUIRED' : name.toUpperCase();
}

class RegistrationPlayer {
  final String userId;
  final String name;
  final String avatar;
  final String role; // CAPTAIN | MANAGER | PLAYER
  final bool isPlaying;
  final ApprovalStatus approvalStatus;

  const RegistrationPlayer({
    required this.userId,
    this.name = '',
    this.avatar = '',
    this.role = 'PLAYER',
    this.isPlaying = true,
    this.approvalStatus = ApprovalStatus.pending,
  });

  bool get isApproved => approvalStatus == ApprovalStatus.approved;
  bool get isPending => approvalStatus == ApprovalStatus.pending;
  bool get isDeclined => approvalStatus == ApprovalStatus.declined;

  factory RegistrationPlayer.fromJson(Map<String, dynamic> json) {
    return RegistrationPlayer(
      userId:
          (json['user_id'] ?? json['userId'] ?? json['id'] ?? '').toString(),
      name:
          (json['name'] ?? json['user_name'] ?? json['userName'] ?? '').toString(),
      avatar: (json['avatar'] ??
              json['avatar_url'] ??
              json['avatarUrl'] ??
              json['profile_pic'] ??
              '')
          .toString(),
      role: (json['role'] ?? 'PLAYER').toString().toUpperCase(),
      isPlaying: (json['is_playing'] ?? json['isPlaying'] as bool?) ?? true,
      approvalStatus: ApprovalStatus.fromString(
        (json['approval_status'] ?? json['approvalStatus'] ?? json['status'])
            ?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'avatar': avatar,
        'role': role,
        'is_playing': isPlaying,
        'approval_status': approvalStatus.toUppercaseString(),
      };
}

class RegistrationInfo {
  final String submissionId;
  final TeamRegistrationState state;
  final int rosterVersion;
  final bool requirePlayerApproval;
  final int requiredCount;
  final int approvedCount;
  final DateTime? submittedAt;
  final List<RegistrationPlayer> players;

  const RegistrationInfo({
    this.submissionId = '',
    this.state = TeamRegistrationState.forming,
    this.rosterVersion = 1,
    this.requirePlayerApproval = true,
    this.requiredCount = 0,
    this.approvedCount = 0,
    this.submittedAt,
    this.players = const [],
  });

  factory RegistrationInfo.fromJson(Map<String, dynamic> json) {
    final rawState = (json['state'] ?? json['registration_state'])?.toString();
    TeamRegistrationState parsedState = TeamRegistrationState.forming;
    if (rawState != null && rawState.isNotEmpty) {
      switch (rawState.toUpperCase()) {
        case 'PENDING_PLAYER_APPROVAL':
          parsedState = TeamRegistrationState.pendingPlayerApproval;
          break;
        case 'PENDING_PAYMENT':
          parsedState = TeamRegistrationState.pendingPayment;
          break;
        case 'CONFIRMED':
          parsedState = TeamRegistrationState.confirmed;
          break;
        case 'WAITLISTED':
          parsedState = TeamRegistrationState.waitlisted;
          break;
        case 'ROSTER_CHANGE_REQUIRED':
          parsedState = TeamRegistrationState.rosterChangeRequired;
          break;
        case 'FORMING':
        default:
          parsedState = TeamRegistrationState.forming;
          break;
      }
    }

    DateTime? parsedSubmittedAt;
    final rawDate = json['submitted_at'] ?? json['submittedAt'];
    if (rawDate != null) {
      parsedSubmittedAt = DateTime.tryParse(rawDate.toString());
    }

    final parsedPlayers = (json['players'] as List<dynamic>?)
            ?.map((e) => RegistrationPlayer.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return RegistrationInfo(
      submissionId:
          (json['submission_id'] ?? json['submissionId'] ?? '').toString(),
      state: parsedState,
      rosterVersion:
          (json['roster_version'] ?? json['rosterVersion'] as num?)?.toInt() ?? 1,
      requirePlayerApproval:
          (json['require_player_approval'] ?? json['requirePlayerApproval'] as bool?) ?? true,
      requiredCount:
          (json['required_count'] ?? json['requiredCount'] as num?)?.toInt() ?? 0,
      approvedCount:
          (json['approved_count'] ?? json['approvedCount'] as num?)?.toInt() ?? 0,
      submittedAt: parsedSubmittedAt,
      players: parsedPlayers,
    );
  }

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'state': state.name.toUpperCase(),
        'roster_version': rosterVersion,
        'require_player_approval': requirePlayerApproval,
        'required_count': requiredCount,
        'approved_count': approvedCount,
        'submitted_at': submittedAt?.toIso8601String(),
        'players': players.map((e) => e.toJson()).toList(),
      };
}

enum JoinRequestStatus {
  none,
  pending,
  approved,
  rejected,
  cancelled;

  static JoinRequestStatus fromString(String? val) {
    if (val == null) return JoinRequestStatus.none;
    switch (val.toUpperCase().trim()) {
      case 'PENDING':
        return JoinRequestStatus.pending;
      case 'APPROVED':
        return JoinRequestStatus.approved;
      case 'REJECTED':
        return JoinRequestStatus.rejected;
      case 'CANCELLED':
        return JoinRequestStatus.cancelled;
      case 'NONE':
      default:
        return JoinRequestStatus.none;
    }
  }

  String toUppercaseString() => name.toUpperCase();
}

class TeamPreviewMember {
  final String name;
  final String avatarUrl;
  final String role; // e.g. 'LEADER', 'MANAGER', 'MEMBER'
  final bool isSubstitute;

  const TeamPreviewMember({
    required this.name,
    this.avatarUrl = '',
    this.role = 'MEMBER',
    this.isSubstitute = false,
  });

  factory TeamPreviewMember.fromJson(Map<String, dynamic> json) {
    final roleRaw = (json['role'] ?? json['roster_type'] ?? json['rosterType'] ?? 'MEMBER').toString().toUpperCase();
    final rawSub = json['is_substitute'] ?? json['isSubstitute'];
    final bool isSub = rawSub != null
        ? _parseBool(rawSub)
        : (roleRaw == 'SUBSTITUTE' || roleRaw == 'SUB');
    return TeamPreviewMember(
      name: _parseString(json['name'] ?? json['user_name'] ?? json['userName'], 'Player'),
      avatarUrl: _parseString(json['avatar'] ?? json['avatar_url'] ?? json['avatarUrl'] ?? json['profile_pic']),
      role: roleRaw,
      isSubstitute: isSub,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatar': avatarUrl,
        'role': role,
        'is_substitute': isSubstitute,
      };
}

class ResponsiblePerson {
  final String name;
  final String role; // 'LEADER' | 'MANAGER'

  const ResponsiblePerson({
    required this.name,
    this.role = 'LEADER',
  });

  factory ResponsiblePerson.fromJson(Map<String, dynamic> json) {
    return ResponsiblePerson(
      name: (json['name'] ?? json['userName'] ?? json['user_name'] ?? '').toString(),
      role: (json['role'] ?? 'LEADER').toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
      };
}

class TeamPreview {
  final String id;
  final String name;
  final String tag;
  final String logoUrl;
  final String tournamentId;
  final String tournamentName;
  final String code;
  final ResponsiblePerson? responsiblePerson;
  final int mainCount;
  final int maxMain;
  final int substituteCount;
  final int maxSubstitutes;
  final bool acceptingSubstitutes;
  final bool slotsAvailable;
  final TeamRegistrationState registrationState;
  final bool rosterLocked;
  final bool requireJoinApproval;
  final bool isMember;
  final JoinRequestStatus myRequestStatus;
  final List<TeamPreviewMember> members;

  const TeamPreview({
    required this.id,
    required this.name,
    this.tag = '',
    this.logoUrl = '',
    this.tournamentId = '',
    this.tournamentName = '',
    this.code = '',
    this.responsiblePerson,
    this.mainCount = 0,
    this.maxMain = 4,
    this.substituteCount = 0,
    this.maxSubstitutes = 2,
    this.acceptingSubstitutes = false,
    this.slotsAvailable = true,
    this.registrationState = TeamRegistrationState.forming,
    this.rosterLocked = false,
    this.requireJoinApproval = false,
    this.isMember = false,
    this.myRequestStatus = JoinRequestStatus.none,
    this.members = const [],
  });

  bool get isMainFull => mainCount >= maxMain;
  bool get canJoinAsSubstitute =>
      isMainFull && acceptingSubstitutes && substituteCount < maxSubstitutes;
  int get mainSlotsLeft => (maxMain - mainCount).clamp(0, maxMain);

  factory TeamPreview.fromJson(Map<String, dynamic> json) {
    ResponsiblePerson? resp;
    if (json['responsible_person'] is Map) {
      resp = ResponsiblePerson.fromJson(Map<String, dynamic>.from(json['responsible_person'] as Map));
    } else if (json['responsiblePerson'] is Map) {
      resp = ResponsiblePerson.fromJson(Map<String, dynamic>.from(json['responsiblePerson'] as Map));
    } else {
      final respName = _parseString(json['captain_name'] ?? json['owner_name'] ?? json['responsible_person_name']);
      final respRole = _parseString(json['owner_role'], 'LEADER').toUpperCase();
      if (respName.isNotEmpty) {
        resp = ResponsiblePerson(name: respName, role: respRole);
      }
    }

    final rawRegState = (json['registration_state'] ?? json['registrationState'])?.toString();
    TeamRegistrationState regState = TeamRegistrationState.forming;
    if (rawRegState != null && rawRegState.isNotEmpty) {
      switch (rawRegState.toUpperCase()) {
        case 'CONFIRMED':
          regState = TeamRegistrationState.confirmed;
          break;
        case 'WAITLISTED':
          regState = TeamRegistrationState.waitlisted;
          break;
        case 'PENDING_PLAYER_APPROVAL':
          regState = TeamRegistrationState.pendingPlayerApproval;
          break;
        case 'PENDING_PAYMENT':
          regState = TeamRegistrationState.pendingPayment;
          break;
        case 'ROSTER_CHANGE_REQUIRED':
          regState = TeamRegistrationState.rosterChangeRequired;
          break;
        case 'FORMING':
        default:
          regState = TeamRegistrationState.forming;
          break;
      }
    }

    final parsedMembers = (json['members'] as List<dynamic>?)
            ?.map((e) => e is Map
                ? TeamPreviewMember.fromJson(Map<String, dynamic>.from(e as Map))
                : TeamPreviewMember(name: 'Player'))
            .toList() ??
        [];

    final mainCountParsed = json['main_count'] != null || json['mainCount'] != null
        ? _parseInt(json['main_count'] ?? json['mainCount'])
        : parsedMembers.where((m) => !m.isSubstitute).length;

    final maxMainParsed = _parseInt(json['max_main'] ?? json['maxMainPlayers'] ?? json['maxMain'], 4);

    final subCountParsed = json['substitute_count'] != null || json['substituteCount'] != null
        ? _parseInt(json['substitute_count'] ?? json['substituteCount'])
        : parsedMembers.where((m) => m.isSubstitute).length;

    final maxSubParsed = _parseInt(json['max_substitutes'] ?? json['maxSubstitutes'], 2);

    final bool accSub = _parseBool(json['accepting_substitutes'] ?? json['acceptingSubstitutes'], false);

    final rawSlots = json['slots_available'] ?? json['slotsAvailable'];
    final bool slotsAvail = rawSlots != null
        ? _parseBool(rawSlots, true)
        : (mainCountParsed < maxMainParsed || (accSub && subCountParsed < maxSubParsed));

    return TeamPreview(
      id: _parseString(json['id']),
      name: _parseString(json['name']),
      tag: _parseString(json['tag']),
      logoUrl: _parseString(json['logo_url'] ?? json['logoUrl']),
      tournamentId: _parseString(json['tournament_id'] ?? json['tournamentId']),
      tournamentName: _parseString(json['tournament_name'] ?? json['tournamentName']),
      code: _parseString(json['invite_code'] ?? json['code']),
      responsiblePerson: resp,
      mainCount: mainCountParsed,
      maxMain: maxMainParsed,
      substituteCount: subCountParsed,
      maxSubstitutes: maxSubParsed,
      acceptingSubstitutes: accSub,
      slotsAvailable: slotsAvail,
      registrationState: regState,
      rosterLocked: _parseBool(json['roster_locked'] ?? json['rosterLocked'], false),
      requireJoinApproval: _parseBool(json['require_join_approval'] ?? json['requireJoinApproval'], false),
      isMember: _parseBool(json['is_member'] ?? json['isMember'], false),
      myRequestStatus: JoinRequestStatus.fromString(
        (json['my_request_status'] ?? json['myRequestStatus'])?.toString(),
      ),
      members: parsedMembers,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tag': tag,
        'logo_url': logoUrl,
        'tournament_id': tournamentId,
        'tournament_name': tournamentName,
        'invite_code': code,
        'responsible_person': responsiblePerson?.toJson(),
        'main_count': mainCount,
        'max_main': maxMain,
        'substitute_count': substituteCount,
        'max_substitutes': maxSubstitutes,
        'accepting_substitutes': acceptingSubstitutes,
        'slots_available': slotsAvailable,
        'registration_state': registrationState.name.toUpperCase(),
        'roster_locked': rosterLocked,
        'require_join_approval': requireJoinApproval,
        'is_member': isMember,
        'my_request_status': myRequestStatus.name.toUpperCase(),
        'members': members.map((e) => e.toJson()).toList(),
      };
}

class JoinRequest {
  final String id;
  final JoinRequestStatus status;
  final String teamId;
  final String teamName;
  final String teamLogoUrl;
  final String tournamentId;
  final String userId;
  final String userName;
  final String userProfilePic;
  final String inGameName;
  final String inGameUid;
  final bool requestedAsSubstitute;
  final DateTime? createdAt;

  const JoinRequest({
    required this.id,
    this.status = JoinRequestStatus.pending,
    required this.teamId,
    this.teamName = '',
    this.teamLogoUrl = '',
    this.tournamentId = '',
    this.userId = '',
    this.userName = '',
    this.userProfilePic = '',
    this.inGameName = '',
    this.inGameUid = '',
    this.requestedAsSubstitute = false,
    this.createdAt,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    final userObj = json['user'] is Map<String, dynamic> ? json['user'] as Map<String, dynamic> : null;
    final teamObj = json['team'] is Map<String, dynamic> ? json['team'] as Map<String, dynamic> : null;

    DateTime? parsedCreatedAt;
    final rawDate = json['created_at'] ?? json['createdAt'];
    if (rawDate != null) {
      parsedCreatedAt = DateTime.tryParse(rawDate.toString());
    }

    return JoinRequest(
      id: (json['id'] ?? '') as String,
      status: JoinRequestStatus.fromString((json['status'] ?? 'PENDING').toString()),
      teamId: (json['team_id'] ?? json['teamId'] ?? teamObj?['id'] ?? '') as String,
      teamName: (json['team_name'] ?? json['teamName'] ?? teamObj?['name'] ?? '') as String,
      teamLogoUrl: (json['team_logo_url'] ?? json['teamLogoUrl'] ?? teamObj?['logo_url'] ?? teamObj?['logoUrl'] ?? '') as String,
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? teamObj?['tournament_id'] ?? '') as String,
      userId: (json['user_id'] ?? json['userId'] ?? userObj?['id'] ?? '') as String,
      userName: (json['user_name'] ?? json['userName'] ?? userObj?['name'] ?? '') as String,
      userProfilePic: (json['user_profile_pic'] ?? json['userProfilePic'] ?? userObj?['profile_pic'] ?? userObj?['avatar'] ?? '') as String,
      inGameName: (json['in_game_name'] ?? json['inGameName'] ?? json['ign'] ?? '') as String,
      inGameUid: (json['in_game_uid'] ?? json['inGameUid'] ?? json['uid'] ?? '') as String,
      requestedAsSubstitute: (json['requested_as_substitute'] ?? json['requestedAsSubstitute'] as bool?) ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name.toUpperCase(),
        'team_id': teamId,
        'team_name': teamName,
        'team_logo_url': teamLogoUrl,
        'tournament_id': tournamentId,
        'user': {
          'id': userId,
          'name': userName,
          'profile_pic': userProfilePic,
        },
        'in_game_name': inGameName,
        'in_game_uid': inGameUid,
        'requested_as_substitute': requestedAsSubstitute,
        'created_at': createdAt?.toIso8601String(),
      };
}

enum JoinResultStatus { joined, pending }

class JoinResult {
  final JoinResultStatus status;
  final TournamentTeamModel? team;
  final JoinRequest? request;
  final TeamPreview? preview;

  const JoinResult({
    required this.status,
    this.team,
    this.request,
    this.preview,
  });

  factory JoinResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['join_status'] ?? json['joinStatus'] ?? json['status'])?.toString().toUpperCase();
    final isPending = rawStatus == 'PENDING';

    TournamentTeamModel? teamParsed;
    if (json['team'] is Map<String, dynamic>) {
      teamParsed = TournamentTeamModel.fromJson(json['team'] as Map<String, dynamic>);
    }

    JoinRequest? reqParsed;
    if (json['request'] is Map<String, dynamic>) {
      reqParsed = JoinRequest.fromJson(json['request'] as Map<String, dynamic>);
    } else if (isPending && json['id'] != null) {
      reqParsed = JoinRequest.fromJson(json);
    }

    TeamPreview? previewParsed;
    if (json['preview'] is Map<String, dynamic>) {
      previewParsed = TeamPreview.fromJson(json['preview'] as Map<String, dynamic>);
    }

    return JoinResult(
      status: isPending ? JoinResultStatus.pending : JoinResultStatus.joined,
      team: teamParsed,
      request: reqParsed,
      preview: previewParsed,
    );
  }
}

class PendingRosterChange {
  final String submissionId;
  final int newRosterVersion;
  final List<RegistrationPlayer> addedPlayers;
  final List<String> removedUserIds;
  final DateTime? expiresAt;

  const PendingRosterChange({
    required this.submissionId,
    required this.newRosterVersion,
    this.addedPlayers = const [],
    this.removedUserIds = const [],
    this.expiresAt,
  });

  factory PendingRosterChange.fromJson(Map<String, dynamic> json) {
    DateTime? exp;
    final rawExp = json['expires_at'] ?? json['expiresAt'];
    if (rawExp != null) exp = DateTime.tryParse(rawExp.toString());

    final addedRaw = (json['added_players'] ?? json['addedPlayers']) as List<dynamic>?;
    final added = addedRaw
            ?.map((e) => RegistrationPlayer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        <RegistrationPlayer>[];

    final removedRaw = (json['removed_user_ids'] ?? json['removedUserIds']) as List<dynamic>?;
    final removed = removedRaw
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    return PendingRosterChange(
      submissionId: (json['submission_id'] ?? json['submissionId'] ?? '').toString(),
      newRosterVersion: (json['new_roster_version'] ?? json['newRosterVersion'] as num?)?.toInt() ?? 1,
      addedPlayers: added,
      removedUserIds: removed,
      expiresAt: exp,
    );
  }

  Map<String, dynamic> toJson() => {
        'submission_id': submissionId,
        'new_roster_version': newRosterVersion,
        'added_players': addedPlayers.map((e) => e.toJson()).toList(),
        'removed_user_ids': removedUserIds,
        'expires_at': expiresAt?.toIso8601String(),
      };
}

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
  final bool? isOwnerExplicit;
  final List<TeamMemberModel> members;
  final int maxMainPlayers;
  final int maxSubstitutes;
  final TeamRegistrationStatus status;
  final TeamRegistrationState registrationState;
  final int rosterVersion;
  final bool? canRegister;
  final bool registrationOpen;
  final bool acceptingSubstitutes;
  final bool isBackendReady;
  final int pendingJoinRequestsCount;
  final RegistrationInfo? registration;
  final String? myPendingApprovalId;
  final bool? canCancelRegistrationRequest;
  final int? waitlistPosition;
  final int? waitlistSize;
  final String teamMode; // 'SOLO' | 'DUO' | 'SQUAD'
  final PendingRosterChange? pendingRosterChange;
  final DateTime? rosterLockAt;
  final bool canChangeRoster;

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
    this.isOwnerExplicit,
    this.members = const [],
    this.maxMainPlayers = 4,
    this.maxSubstitutes = 2,
    this.status = TeamRegistrationStatus.forming,
    this.registrationState = TeamRegistrationState.forming,
    this.rosterVersion = 1,
    this.canRegister,
    this.registrationOpen = true,
    this.acceptingSubstitutes = false,
    this.isBackendReady = false,
    this.pendingJoinRequestsCount = 0,
    this.registration,
    this.myPendingApprovalId,
    this.canCancelRegistrationRequest,
    this.waitlistPosition,
    this.waitlistSize,
    this.teamMode = 'SQUAD',
    this.pendingRosterChange,
    this.rosterLockAt,
    this.canChangeRoster = true,
  });

  bool get isDuoMode => teamMode == 'DUO' || maxMainPlayers == 2;
  bool get isSoloMode => teamMode == 'SOLO' || maxMainPlayers == 1;

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
  bool get isReady => isBackendReady || confirmedMainCount >= maxMainPlayers || status == TeamRegistrationStatus.ready;
  int get mainSlotsLeft => (maxMainPlayers - confirmedMainCount).clamp(0, maxMainPlayers);
  bool get canJoinAsSubstitute =>
      isMainFull && acceptingSubstitutes && substituteCount < maxSubstitutes;
  bool get isLocked =>
      status == TeamRegistrationStatus.locked || !registrationOpen;
  bool get isRegistered =>
      registrationState == TeamRegistrationState.confirmed ||
      status == TeamRegistrationStatus.registered;

  bool get viewerIsCaptain =>
      (viewerUserId.isNotEmpty && viewerUserId == captainId) || (isOwnerExplicit == true);

  bool get viewerIsManager =>
      isManagerOwned &&
      manager != null &&
      ((viewerUserId.isNotEmpty && manager!.userId == viewerUserId) || (isOwnerExplicit == true));

  bool get viewerIsOwner => (isOwnerExplicit == true) || viewerIsCaptain || viewerIsManager || viewerIsOwnerMember;

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
    bool? isOwnerExplicit,
    List<TeamMemberModel>? members,
    int? maxMainPlayers,
    int? maxSubstitutes,
    TeamRegistrationStatus? status,
    TeamRegistrationState? registrationState,
    int? rosterVersion,
    bool? canRegister,
    bool? registrationOpen,
    bool? acceptingSubstitutes,
    bool? isBackendReady,
    int? pendingJoinRequestsCount,
    RegistrationInfo? registration,
    String? myPendingApprovalId,
    bool? canCancelRegistrationRequest,
    int? waitlistPosition,
    int? waitlistSize,
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
      isOwnerExplicit: isOwnerExplicit ?? this.isOwnerExplicit,
      members: members ?? this.members,
      maxMainPlayers: maxMainPlayers ?? this.maxMainPlayers,
      maxSubstitutes: maxSubstitutes ?? this.maxSubstitutes,
      status: status ?? this.status,
      registrationState: registrationState ?? this.registrationState,
      rosterVersion: rosterVersion ?? this.rosterVersion,
      canRegister: canRegister ?? this.canRegister,
      registrationOpen: registrationOpen ?? this.registrationOpen,
      acceptingSubstitutes: acceptingSubstitutes ?? this.acceptingSubstitutes,
      isBackendReady: isBackendReady ?? this.isBackendReady,
      pendingJoinRequestsCount: pendingJoinRequestsCount ?? this.pendingJoinRequestsCount,
      registration: registration ?? this.registration,
      myPendingApprovalId: myPendingApprovalId ?? this.myPendingApprovalId,
      canCancelRegistrationRequest: canCancelRegistrationRequest ?? this.canCancelRegistrationRequest,
      waitlistPosition: waitlistPosition ?? this.waitlistPosition,
      waitlistSize: waitlistSize ?? this.waitlistSize,
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

    final bool parsedIsReady = (json['is_ready'] ?? json['isReady'] as bool?) ?? false;

    List<TeamMemberModel> parsedMembers = (json['members'] as List<dynamic>?)
            ?.map((e) => TeamMemberModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final rawInvitations = json['invitations'] as List<dynamic>?;
    if (rawInvitations != null && rawInvitations.isNotEmpty) {
      final existingUserIds = parsedMembers.map((m) => m.userId).toSet();
      for (final inv in rawInvitations) {
        if (inv is Map<String, dynamic>) {
          final inviteeId = (inv['invitee_user_id'] ?? inv['inviteeUserId'] ?? '') as String;
          final status = (inv['status'] ?? 'PENDING').toString().toUpperCase();
          if (status == 'PENDING' && inviteeId.isNotEmpty && !existingUserIds.contains(inviteeId)) {
            final inviteeName = (inv['invitee_name'] ?? inv['inviteeName'] ?? 'Invited Player') as String;
            parsedMembers.add(
              TeamMemberModel(
                userId: inviteeId,
                name: inviteeName,
                role: TeamRole.member,
                rosterType: RosterType.main,
                status: TeamMemberStatus.pending,
              ),
            );
            existingUserIds.add(inviteeId);
          }
        }
      }
    }

    final String? rawRegState =
        (json['registration_state'] ?? json['registrationState'])?.toString();
    TeamRegistrationState parsedRegState;
    if (rawRegState != null && rawRegState.isNotEmpty) {
      switch (rawRegState.toUpperCase()) {
        case 'PENDING_PLAYER_APPROVAL':
          parsedRegState = TeamRegistrationState.pendingPlayerApproval;
          break;
        case 'PENDING_PAYMENT':
          parsedRegState = TeamRegistrationState.pendingPayment;
          break;
        case 'CONFIRMED':
          parsedRegState = TeamRegistrationState.confirmed;
          break;
        case 'WAITLISTED':
          parsedRegState = TeamRegistrationState.waitlisted;
          break;
        case 'ROSTER_CHANGE_REQUIRED':
          parsedRegState = TeamRegistrationState.rosterChangeRequired;
          break;
        case 'FORMING':
        default:
          parsedRegState = TeamRegistrationState.forming;
          break;
      }
    } else {
      if (parsedStatus == TeamRegistrationStatus.registered ||
          parsedStatus == TeamRegistrationStatus.locked) {
        parsedRegState = TeamRegistrationState.confirmed;
      } else {
        parsedRegState = TeamRegistrationState.forming;
      }
    }

    final int parsedRosterVersion =
        (json['roster_version'] ?? json['rosterVersion'] as num?)?.toInt() ?? 1;
    final bool? parsedCanRegister =
        json['can_register'] ?? json['canRegister'] as bool?;

    final int parsedPendingRequests =
        (json['pending_join_requests_count'] ?? json['pendingJoinRequestsCount'] as num?)?.toInt() ?? 0;

    RegistrationInfo? parsedRegistration;
    if (json['registration'] is Map<String, dynamic>) {
      parsedRegistration = RegistrationInfo.fromJson(json['registration'] as Map<String, dynamic>);
    }

    final String? parsedMyPendingApprovalId =
        (json['my_pending_approval_id'] ?? json['myPendingApprovalId'])?.toString();

    final bool? parsedCanCancel =
        json['can_cancel_registration_request'] ?? json['canCancelRegistrationRequest'] as bool?;

    final int parsedMaxMain = (rosterInfo?['max_main_players'] ?? json['maxMainPlayers'] as num?)?.toInt() ?? 4;
    final String parsedTeamMode = (json['team_mode'] ?? json['teamMode'] ?? (parsedMaxMain == 2 ? 'DUO' : (parsedMaxMain == 1 ? 'SOLO' : 'SQUAD'))).toString().toUpperCase();

    PendingRosterChange? parsedRosterChange;
    if (json['pending_roster_change'] is Map<String, dynamic>) {
      parsedRosterChange = PendingRosterChange.fromJson(json['pending_roster_change'] as Map<String, dynamic>);
    } else if (json['pendingRosterChange'] is Map<String, dynamic>) {
      parsedRosterChange = PendingRosterChange.fromJson(json['pendingRosterChange'] as Map<String, dynamic>);
    }

    DateTime? parsedRosterLockAt;
    final rawRosterLock = json['roster_lock_at'] ?? json['rosterLockAt'];
    if (rawRosterLock != null) {
      parsedRosterLockAt = DateTime.tryParse(rawRosterLock.toString());
    }

    final bool parsedCanChangeRoster = (json['can_change_roster'] ?? json['canChangeRoster'] as bool?) ?? true;

    final String parsedViewerUserId = (json['viewerUserId'] ??
            json['viewer_user_id'] ??
            json['viewer_id'] ??
            json['my_user_id'] ??
            json['user_id'] ??
            '')
        .toString();

    final bool? parsedIsOwner = (json['is_owner'] ??
            json['isOwner'] ??
            json['viewer_is_owner'] ??
            json['viewerIsOwner'] ??
            json['is_captain'] ??
            json['isCaptain']) as bool?;

    return TournamentTeamModel(
      id: (json['id'] ?? '') as String,
      tournamentId:
          (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
      tournamentName: (json['tournamentName'] ?? '') as String,
      code: (json['invite_code'] ?? json['code'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      tag: (json['tag'] ?? '') as String,
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '') as String,
      captainId: (json['captain_id'] ?? json['captainId'] ?? '') as String,
      ownerRole: ownerRoleParsed,
      viewerUserId: parsedViewerUserId,
      isOwnerExplicit: parsedIsOwner,
      members: parsedMembers,
      maxMainPlayers: parsedMaxMain,
      maxSubstitutes: (rosterInfo?['max_substitutes'] ??
              json['maxSubstitutes'] as num?)
          ?.toInt() ??
          (parsedTeamMode == 'DUO' ? 0 : 2),
      status: parsedStatus,
      registrationState: parsedRegState,
      rosterVersion: parsedRosterVersion,
      canRegister: parsedCanRegister,
      registrationOpen: (json['registrationOpen'] as bool?) ?? true,
      acceptingSubstitutes:
          (json['accepting_substitutes'] ?? json['acceptingSubstitutes'] as bool?) ??
              false,
      isBackendReady: parsedIsReady,
      pendingJoinRequestsCount: parsedPendingRequests,
      registration: parsedRegistration,
      myPendingApprovalId: parsedMyPendingApprovalId,
      canCancelRegistrationRequest: parsedCanCancel,
      waitlistPosition: (json['waitlist_position'] ?? json['waitlistPosition'] as num?)?.toInt(),
      waitlistSize: (json['waitlist_size'] ?? json['waitlistSize'] as num?)?.toInt(),
      teamMode: parsedTeamMode,
      pendingRosterChange: parsedRosterChange,
      rosterLockAt: parsedRosterLockAt,
      canChangeRoster: parsedCanChangeRoster,
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
        'registration_state': registrationState.toUppercaseString(),
        'roster_version': rosterVersion,
        'can_register': canRegister,
        'registrationOpen': registrationOpen,
        'acceptingSubstitutes': acceptingSubstitutes,
        'is_ready': isBackendReady,
        'pending_join_requests_count': pendingJoinRequestsCount,
        'registration': registration?.toJson(),
        'my_pending_approval_id': myPendingApprovalId,
        'can_cancel_registration_request': canCancelRegistrationRequest,
        'waitlist_position': waitlistPosition,
        'waitlist_size': waitlistSize,
      };
}
