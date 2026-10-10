import 'package:flutter/foundation.dart';

/// ============================================================
/// TOURNAMENT MATCHES & ROOM CREDENTIALS DTO
/// Supports Round -> Group -> Teams hierarchy with User Group Context
/// ============================================================

enum TeamRoundStatus {
  upcoming,
  live,
  completed,
  qualified,
  disqualified,
}

extension TeamRoundStatusX on TeamRoundStatus {
  String get label => switch (this) {
        TeamRoundStatus.upcoming => 'UPCOMING',
        TeamRoundStatus.live => 'LIVE NOW',
        TeamRoundStatus.completed => 'COMPLETED',
        TeamRoundStatus.qualified => 'QUALIFIED',
        TeamRoundStatus.disqualified => 'ELIMINATED',
      };
}

/// Details for a team participating in a group match
@immutable
class GroupTeamModel {
  final String id;
  final String name;
  final String logoUrl;
  final bool isMyTeam;

  const GroupTeamModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    this.isMyTeam = false,
  });

  factory GroupTeamModel.fromJson(Map<String, dynamic> json) {
    return GroupTeamModel(
      id: (json['id'] ?? json['team_id'] ?? '').toString(),
      name: (json['name'] ?? json['team_name'] ?? 'Team').toString(),
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '').toString(),
      isMyTeam: (json['is_my_team'] ?? json['isMyTeam'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_url': logoUrl,
        'is_my_team': isMyTeam,
      };
}

/// Group Model representing a single custom room/match in a round
@immutable
class GroupModel {
  final String id;
  final String groupName; // e.g., "Group 1", "Group 2"
  final int groupNumber;
  final String map; // "Bermuda", "Purgatory", "Kalahari"
  final String status; // "upcoming", "live", "completed"
  final List<GroupTeamModel> teams;
  final String? roomId;
  final String? password;
  final bool isPublished;
  final DateTime startsAt;
  final DateTime? endedAt;
  final String? winnerTeamName;
  final String? topMvpName;

  const GroupModel({
    required this.id,
    required this.groupName,
    this.groupNumber = 1,
    this.map = 'Bermuda',
    this.status = 'upcoming',
    this.teams = const [],
    this.roomId,
    this.password,
    this.isPublished = false,
    required this.startsAt,
    this.endedAt,
    this.winnerTeamName,
    this.topMvpName,
  });

  bool get isLive => status.toLowerCase() == 'live';
  bool get isCompleted => status.toLowerCase() == 'completed';

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final rawStartsAt = json['starts_at'] ?? json['startsAt'];
    final parsedStartsAt = rawStartsAt != null
        ? DateTime.tryParse(rawStartsAt.toString()) ?? DateTime.now()
        : DateTime.now();

    final rawEndedAt = json['ended_at'] ?? json['endedAt'];
    final parsedEndedAt =
        rawEndedAt != null ? DateTime.tryParse(rawEndedAt.toString()) : null;

    final rawTeams = (json['teams'] as List<dynamic>?) ?? [];
    final teamsList = rawTeams
        .map((e) => GroupTeamModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return GroupModel(
      id: (json['id'] ?? json['group_id'] ?? '').toString(),
      groupName: (json['group_name'] ?? json['groupName'] ?? 'Group 1').toString(),
      groupNumber: (json['group_number'] ?? json['groupNumber'] as num?)?.toInt() ?? 1,
      map: (json['map'] ?? 'Bermuda').toString(),
      status: (json['status'] ?? 'upcoming').toString(),
      teams: teamsList,
      roomId: (json['room_id'] ?? json['roomId'])?.toString(),
      password: (json['password'] ?? json['room_password'])?.toString(),
      isPublished: (json['is_published'] ?? json['isPublished'] ?? false) as bool,
      startsAt: parsedStartsAt,
      endedAt: parsedEndedAt,
      winnerTeamName: (json['winner_team_name'] ?? json['winnerTeamName'])?.toString(),
      topMvpName: (json['top_mvp_name'] ?? json['topMvpName'] ?? json['topKillerName'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_name': groupName,
        'group_number': groupNumber,
        'map': map,
        'status': status,
        'teams': teams.map((e) => e.toJson()).toList(),
        'room_id': roomId,
        'password': password,
        'is_published': isPublished,
        'starts_at': startsAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'winner_team_name': winnerTeamName,
        'top_mvp_name': topMvpName,
      };
}

/// Round Model representing a stage in the tournament containing groups
@immutable
class RoundModel {
  final String id;
  final String roundName; // e.g., "Round 1 (Qualifiers)", "Round 2 (Semi Finals)", "Grand Finals"
  final int roundNumber;
  final String status; // "upcoming", "live", "completed"
  final List<GroupModel> groups;

  const RoundModel({
    required this.id,
    required this.roundName,
    this.roundNumber = 1,
    this.status = 'upcoming',
    this.groups = const [],
  });

  factory RoundModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = (json['groups'] as List<dynamic>?) ?? [];
    final groupsList = rawGroups
        .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return RoundModel(
      id: (json['id'] ?? json['round_id'] ?? '').toString(),
      roundName: (json['round_name'] ?? json['roundName'] ?? 'Round 1').toString(),
      roundNumber: (json['round_number'] ?? json['roundNumber'] as num?)?.toInt() ?? 1,
      status: (json['status'] ?? 'upcoming').toString(),
      groups: groupsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'round_name': roundName,
        'round_number': roundNumber,
        'status': status,
        'groups': groups.map((e) => e.toJson()).toList(),
      };
}

/// Logged-in User's Group & Match Context
@immutable
class UserMatchContext {
  final String teamId;
  final String teamName;
  final String roundId;
  final String roundName;
  final String groupId;
  final String groupName;
  final TeamRoundStatus status; // upcoming, live, completed, qualified, disqualified
  final List<String> opponentTeamNames;
  final String? roomId;
  final String? password;
  final bool isPublished;
  final DateTime? revealAt;
  final DateTime? startsAt;
  final String map;

  const UserMatchContext({
    required this.teamId,
    required this.teamName,
    this.roundId = '',
    required this.roundName,
    this.groupId = '',
    required this.groupName,
    required this.status,
    this.opponentTeamNames = const [],
    this.roomId,
    this.password,
    this.isPublished = false,
    this.revealAt,
    this.startsAt,
    this.map = 'Bermuda',
  });

  bool get isEliminated => status == TeamRoundStatus.disqualified;
  bool get isQualified => status == TeamRoundStatus.qualified;
  bool get hasCredentials =>
      isPublished && roomId != null && roomId!.isNotEmpty;

  factory UserMatchContext.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'upcoming').toString().toLowerCase();
    final parsedStatus = switch (rawStatus) {
      'live' => TeamRoundStatus.live,
      'completed' => TeamRoundStatus.completed,
      'qualified' => TeamRoundStatus.qualified,
      'disqualified' || 'eliminated' => TeamRoundStatus.disqualified,
      _ => TeamRoundStatus.upcoming,
    };

    final rawRevealAt = json['reveal_at'] ?? json['revealAt'] ?? json['visible_from'];
    final parsedRevealAt =
        rawRevealAt != null ? DateTime.tryParse(rawRevealAt.toString()) : null;

    final rawStartsAt = json['starts_at'] ?? json['startsAt'];
    final parsedStartsAt =
        rawStartsAt != null ? DateTime.tryParse(rawStartsAt.toString()) : null;

    final rawOpponents = (json['opponent_team_names'] ?? json['opponentTeams'] as List<dynamic>?) ?? [];
    final opponentList = rawOpponents.map((e) => e.toString()).toList();

    return UserMatchContext(
      teamId: (json['team_id'] ?? json['teamId'] ?? '').toString(),
      teamName: (json['team_name'] ?? json['teamName'] ?? 'Your Team').toString(),
      roundId: (json['round_id'] ?? json['roundId'] ?? '').toString(),
      roundName: (json['round_name'] ?? json['roundName'] ?? 'Round 1').toString(),
      groupId: (json['group_id'] ?? json['groupId'] ?? '').toString(),
      groupName: (json['group_name'] ?? json['groupName'] ?? 'Group 1').toString(),
      status: parsedStatus,
      opponentTeamNames: opponentList,
      roomId: (json['room_id'] ?? json['roomId'])?.toString(),
      password: (json['password'] ?? json['room_password'])?.toString(),
      isPublished: (json['is_published'] ?? json['isPublished'] ?? false) as bool,
      revealAt: parsedRevealAt,
      startsAt: parsedStartsAt,
      map: (json['map'] ?? 'Bermuda').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'team_name': teamName,
        'round_id': roundId,
        'round_name': roundName,
        'group_id': groupId,
        'group_name': groupName,
        'status': status.name,
        'opponent_team_names': opponentTeamNames,
        'room_id': roomId,
        'password': password,
        'is_published': isPublished,
        'reveal_at': revealAt?.toIso8601String(),
        'starts_at': startsAt?.toIso8601String(),
        'map': map,
      };
}

/// Overall Response for Tournament Matches endpoint
@immutable
class TournamentMatchesResponse {
  final String tournamentId;
  final UserMatchContext? userContext;
  final List<RoundModel> rounds;
  final int maxTeamsPerGroup;
  final bool isUserRegistered;

  const TournamentMatchesResponse({
    required this.tournamentId,
    this.userContext,
    this.rounds = const [],
    this.maxTeamsPerGroup = 12,
    this.isUserRegistered = false,
  });

  factory TournamentMatchesResponse.fromJson(Map<String, dynamic> json) {
    final rawUserContext = json['user_context'] ?? json['userContext'];
    final parsedUserContext = rawUserContext is Map
        ? UserMatchContext.fromJson(Map<String, dynamic>.from(rawUserContext as Map))
        : null;

    final rawRounds = (json['rounds'] as List<dynamic>?) ?? [];
    final parsedRounds = rawRounds
        .map((e) => RoundModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return TournamentMatchesResponse(
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '').toString(),
      userContext: parsedUserContext,
      rounds: parsedRounds,
      maxTeamsPerGroup: (json['max_teams_per_group'] ?? json['maxTeamsPerGroup'] as num?)?.toInt() ?? 12,
      isUserRegistered: (json['is_user_registered'] ?? json['isUserRegistered'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'tournament_id': tournamentId,
        'user_context': userContext?.toJson(),
        'rounds': rounds.map((e) => e.toJson()).toList(),
        'max_teams_per_group': maxTeamsPerGroup,
        'is_user_registered': isUserRegistered,
      };
}
