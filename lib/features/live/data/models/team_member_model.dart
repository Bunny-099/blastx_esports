// ============================================================
// TEAM MEMBER MODEL (tournament roster player)
// ============================================================

enum TeamRole { captain, member }

enum RosterType { main, substitute }

T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) {
  final s = (raw as String? ?? '').toLowerCase();
  return values.firstWhere((e) => e.name == s, orElse: () => fallback);
}

class TeamMemberModel {
  final String userId;
  final String name;
  final String avatarUrl;
  final String ign; // Free Fire in-game name
  final String uid; // Free Fire UID
  final TeamRole role;
  final RosterType rosterType;

  const TeamMemberModel({
    required this.userId,
    required this.name,
    this.avatarUrl = '',
    this.ign = '',
    this.uid = '',
    this.role = TeamRole.member,
    this.rosterType = RosterType.main,
  });

  bool get isCaptain => role == TeamRole.captain;
  bool get isSubstitute => rosterType == RosterType.substitute;

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map ? json['user'] as Map<String, dynamic> : null;
    final gameProfile = userMap?['game_profile'] is Map
        ? userMap!['game_profile'] as Map<String, dynamic>
        : null;

    final resolvedUserId = (json['user_id'] ?? json['userId'] ?? userMap?['id'] ?? json['id'] ?? '') as String;
    final resolvedName = (userMap?['name'] ?? json['name'] ?? '') as String;
    final resolvedAvatar = (userMap?['profile_pic'] ?? json['avatarUrl'] ?? json['profile_pic'] ?? '') as String;
    final resolvedIgn = (gameProfile?['in_game_name'] ?? json['ign'] ?? json['in_game_name'] ?? '') as String;
    final resolvedUid = (gameProfile?['in_game_uid'] ?? json['uid'] ?? json['in_game_uid'] ?? '') as String;

    return TeamMemberModel(
      userId: resolvedUserId,
      name: resolvedName,
      avatarUrl: resolvedAvatar,
      ign: resolvedIgn,
      uid: resolvedUid,
      role: _enumFrom(TeamRole.values, json['role'], TeamRole.member),
      rosterType: _enumFrom(
        RosterType.values,
        json['roster_type'] ?? json['rosterType'],
        RosterType.main,
      ),
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
  };
}
