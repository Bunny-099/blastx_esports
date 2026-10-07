// ============================================================
// SQUAD MODEL & SQUAD MEMBER MODEL (Persistent Squad System)
// ============================================================

enum SquadRole { leader, manager, member }

enum SquadRosterType { main, substitute }

T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final s = (raw as String? ?? '').toLowerCase();
  return values.firstWhere((e) => e.name == s, orElse: () => fallback);
}

class SquadMemberModel {
  final String userId;
  final String name;
  final String avatarUrl;
  final String ign; // Free Fire in-game name
  final String uid; // Free Fire UID
  final SquadRole role;
  final SquadRosterType rosterType;
  final DateTime? joinedAt;

  const SquadMemberModel({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
    this.ign = '',
    this.uid = '',
    this.role = SquadRole.member,
    this.rosterType = SquadRosterType.main,
    this.joinedAt,
  });

  bool get isLeader => role == SquadRole.leader;
  bool get isManager => role == SquadRole.manager;
  bool get isMember => role == SquadRole.member;
  bool get isPlaying => role != SquadRole.manager;

  bool get isSubstitute => rosterType == SquadRosterType.substitute;
  bool get isMain => rosterType == SquadRosterType.main;

  SquadMemberModel copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    String? ign,
    String? uid,
    SquadRole? role,
    SquadRosterType? rosterType,
    DateTime? joinedAt,
  }) {
    return SquadMemberModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ign: ign ?? this.ign,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      rosterType: rosterType ?? this.rosterType,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  factory SquadMemberModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final gameProfile = userMap?['game_profile'] is Map
        ? userMap!['game_profile'] as Map<String, dynamic>
        : null;

    final resolvedUserId = (json['user_id'] ?? json['userId'] ?? userMap?['id'] ?? json['id'] ?? '') as String;
    final resolvedName = (userMap?['name'] ?? json['name'] ?? '') as String;
    final resolvedAvatar = (userMap?['profile_pic'] ?? json['avatarUrl'] ?? json['profile_pic'] ?? '') as String;
    final resolvedIgn = (gameProfile?['in_game_name'] ?? json['ign'] ?? json['in_game_name'] ?? '') as String;
    final resolvedUid = (gameProfile?['in_game_uid'] ?? json['uid'] ?? json['in_game_uid'] ?? '') as String;

    DateTime? parsedJoinedAt;
    if (json['joined_at'] != null || json['joinedAt'] != null) {
      parsedJoinedAt = DateTime.tryParse((json['joined_at'] ?? json['joinedAt']).toString());
    }

    return SquadMemberModel(
      userId: resolvedUserId,
      name: resolvedName,
      avatarUrl: resolvedAvatar,
      ign: resolvedIgn,
      uid: resolvedUid,
      role: _enumFrom(SquadRole.values, json['role'], SquadRole.member),
      rosterType: _enumFrom(
        SquadRosterType.values,
        json['roster_type'] ?? json['rosterType'],
        SquadRosterType.main,
      ),
      joinedAt: parsedJoinedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'avatarUrl': avatarUrl,
    'ign': ign,
    'uid': uid,
    'role': role.name.toUpperCase(),
    'rosterType': rosterType.name.toUpperCase(),
    'joinedAt': joinedAt?.toIso8601String(),
  };
}

class SquadModel {
  final String id;
  final String name;
  final String tag;
  final String logoUrl;
  final String leaderId;
  final SquadRole ownerRole;
  final List<SquadMemberModel> members;
  final int maxMainPlayers;
  final int maxSubstitutes;
  final DateTime? createdAt;

  const SquadModel({
    required this.id,
    required this.name,
    required this.leaderId,
    this.ownerRole = SquadRole.leader,
    this.tag = '',
    this.logoUrl = '',
    this.members = const [],
    this.maxMainPlayers = 4,
    this.maxSubstitutes = 2,
    this.createdAt,
  });

  bool get isManagerOwned => ownerRole == SquadRole.manager;

  /// Main playing players (Manager is non-playing so excluded from main player slots)
  List<SquadMemberModel> get mainPlayers => members
      .where((m) => m.isMain && m.isPlaying)
      .toList()
    ..sort((a, b) => a.isLeader == b.isLeader ? 0 : (a.isLeader ? -1 : 1));

  /// Substitute playing players
  List<SquadMemberModel> get substitutes =>
      members.where((m) => m.isSubstitute && m.isPlaying).toList();

  int get mainCount => mainPlayers.length;
  int get substituteCount => substitutes.length;
  int get totalPlayingMembers => mainCount + substituteCount;
  int get totalMembers => members.length;

  bool get isMainFull => mainCount >= maxMainPlayers;
  bool get isSubstituteFull => substituteCount >= maxSubstitutes;
  bool get isFull => totalPlayingMembers >= (maxMainPlayers + maxSubstitutes);

  bool isOwner(String userId) =>
      (leaderId.isNotEmpty && leaderId == userId) ||
      members.any((m) => m.userId == userId && (m.isLeader || m.isManager));

  bool isLeader(String userId) =>
      members.any((m) => m.userId == userId && m.isLeader) ||
      (leaderId.isNotEmpty && leaderId == userId && !isManagerOwned);

  bool isManager(String userId) =>
      members.any((m) => m.userId == userId && m.isManager) ||
      (leaderId.isNotEmpty && leaderId == userId && isManagerOwned);

  bool isMember(String userId) => members.any((m) => m.userId == userId);

  SquadMemberModel? get owner {
    for (final m in members) {
      if (m.isLeader || m.isManager || m.userId == leaderId) return m;
    }
    return null;
  }

  SquadMemberModel? get leader => owner;

  SquadMemberModel? get manager {
    for (final m in members) {
      if (m.isManager) return m;
    }
    return isManagerOwned ? owner : null;
  }

  SquadMemberModel? getMember(String userId) {
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (_) {
      return null;
    }
  }

  SquadModel copyWith({
    String? id,
    String? name,
    String? tag,
    String? logoUrl,
    String? leaderId,
    SquadRole? ownerRole,
    List<SquadMemberModel>? members,
    int? maxMainPlayers,
    int? maxSubstitutes,
    DateTime? createdAt,
  }) {
    return SquadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      logoUrl: logoUrl ?? this.logoUrl,
      leaderId: leaderId ?? this.leaderId,
      ownerRole: ownerRole ?? this.ownerRole,
      members: members ?? this.members,
      maxMainPlayers: maxMainPlayers ?? this.maxMainPlayers,
      maxSubstitutes: maxSubstitutes ?? this.maxSubstitutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SquadModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['members'] as List<dynamic>?;
    DateTime? parsedCreated;
    if (json['created_at'] != null || json['createdAt'] != null) {
      parsedCreated = DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString());
    }

    final ownerRoleRaw = (json['owner_role'] ?? json['ownerRole'] ?? 'leader').toString().toLowerCase();
    final ownerRoleParsed = ownerRoleRaw == 'manager' ? SquadRole.manager : SquadRole.leader;

    return SquadModel(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      tag: (json['tag'] ?? '') as String,
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '') as String,
      leaderId: (json['leader_id'] ?? json['leaderId'] ?? '') as String,
      ownerRole: ownerRoleParsed,
      members: rawMembers
              ?.map((e) => SquadMemberModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      maxMainPlayers: (json['max_main_players'] ?? json['maxMainPlayers'] as num?)?.toInt() ?? 4,
      maxSubstitutes: (json['max_substitutes'] ?? json['maxSubstitutes'] as num?)?.toInt() ?? 2,
      createdAt: parsedCreated,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tag': tag,
        'logoUrl': logoUrl,
        'leaderId': leaderId,
        'ownerRole': ownerRole.name.toUpperCase(),
        'members': members.map((e) => e.toJson()).toList(),
        'maxMainPlayers': maxMainPlayers,
        'maxSubstitutes': maxSubstitutes,
        'createdAt': createdAt?.toIso8601String(),
      };
}
