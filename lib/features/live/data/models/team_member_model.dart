/// ============================================================
/// TEAM MEMBER MODEL (tournament roster player)
/// ============================================================
/// Free Fire details (IGN / UID) are collected in the team flow;
/// they are not part of the user account model.
/// ============================================================

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

  factory TeamMemberModel.fromJson(Map<String, dynamic> json) =>
      TeamMemberModel(
        userId: (json['userId'] ?? json['id'] ?? '') as String,
        name: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        ign: json['ign'] as String? ?? '',
        uid: json['uid'] as String? ?? '',
        role: _enumFrom(TeamRole.values, json['role'], TeamRole.member),
        rosterType:
        _enumFrom(RosterType.values, json['rosterType'], RosterType.main),
      );

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