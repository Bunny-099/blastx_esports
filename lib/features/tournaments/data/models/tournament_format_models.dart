// ============================================================
// TOURNAMENT FORMAT ENGINE & MULTI-STAGE MODELS
// Conforming to Section 2 of the Mobile Developer Prompt
// ============================================================

import 'package:flutter/foundation.dart';

/// ------------------------------------------------------------
/// ENUMS & VALUE TYPES
/// ------------------------------------------------------------

enum TournamentFormat {
  BATTLE_ROYALE,
  CLASH_SQUAD;

  static TournamentFormat fromJson(String? raw) {
    if (raw == null) return TournamentFormat.BATTLE_ROYALE;
    final upper = raw.trim().toUpperCase();
    if (upper == 'CLASH_SQUAD' || upper == 'CLASH SQUAD' || upper == 'CS') {
      return TournamentFormat.CLASH_SQUAD;
    }
    return TournamentFormat.BATTLE_ROYALE;
  }

  String toJson() => name;
}

enum TeamMode {
  SOLO,
  DUO,
  SQUAD;

  static TeamMode fromJson(String? raw) {
    if (raw == null) return TeamMode.SQUAD;
    final upper = raw.trim().toUpperCase();
    if (upper == 'SOLO') return TeamMode.SOLO;
    if (upper == 'DUO') return TeamMode.DUO;
    return TeamMode.SQUAD;
  }

  int get requiredPlayersCount {
    switch (this) {
      case TeamMode.SOLO:
        return 1;
      case TeamMode.DUO:
        return 2;
      case TeamMode.SQUAD:
        return 4;
    }
  }

  String toJson() => name;
}

enum TournamentStatus {
  DRAFT,
  UPCOMING,
  REGISTRATION_OPEN,
  REGISTRATION_CLOSED,
  LIVE,
  COMPLETED,
  CANCELLED;

  static TournamentStatus fromJson(String? raw) {
    if (raw == null) return TournamentStatus.UPCOMING;
    final upper = raw.trim().toUpperCase();
    for (final val in TournamentStatus.values) {
      if (val.name == upper) return val;
    }
    if (upper == 'LIVE') return TournamentStatus.LIVE;
    if (upper == 'COMPLETED' || upper == 'ENDED') return TournamentStatus.COMPLETED;
    return TournamentStatus.UPCOMING;
  }

  String toJson() => name;
}

enum StageStatus {
  SCHEDULED,
  LIVE,
  COMPLETED;

  static StageStatus fromJson(String? raw) {
    if (raw == null) return StageStatus.SCHEDULED;
    final upper = raw.trim().toUpperCase();
    for (final val in StageStatus.values) {
      if (val.name == upper) return val;
    }
    if (upper == 'LIVE' || upper == 'ACTIVE') return StageStatus.LIVE;
    if (upper == 'COMPLETED' || upper == 'FINISHED') return StageStatus.COMPLETED;
    return StageStatus.SCHEDULED;
  }

  String toJson() => name;
}

enum QualificationStatus {
  QUALIFIED,
  ELIMINATED,
  WILD_CARD,
  PENDING;

  static QualificationStatus fromJson(String? raw) {
    if (raw == null) return QualificationStatus.PENDING;
    final upper = raw.trim().toUpperCase();
    for (final val in QualificationStatus.values) {
      if (val.name == upper) return val;
    }
    if (upper.contains('QUALIFIED') || upper == 'ADVANCED' || upper == 'PASSED') {
      return QualificationStatus.QUALIFIED;
    }
    if (upper.contains('ELIMINATED') || upper == 'OUT' || upper == 'LOST') {
      return QualificationStatus.ELIMINATED;
    }
    if (upper.contains('WILD') || upper == 'WILDCARD') {
      return QualificationStatus.WILD_CARD;
    }
    return QualificationStatus.PENDING;
  }

  String toJson() => name;
}

/// ------------------------------------------------------------
/// STANDING ENTRY MODEL
/// ------------------------------------------------------------

class GroupStandingEntry {
  final int rank;
  final String unitId; // Team ID or User ID (Solo)
  final String unitName;
  final String? avatarUrl;
  final int slotNumber;
  final int matchesPlayed;
  final int kills;
  final int placementPoints;
  final int totalPoints;
  final QualificationStatus status;

  const GroupStandingEntry({
    required this.rank,
    required this.unitId,
    required this.unitName,
    this.avatarUrl,
    required this.slotNumber,
    required this.matchesPlayed,
    required this.kills,
    required this.placementPoints,
    required this.totalPoints,
    required this.status,
  });

  factory GroupStandingEntry.fromJson(Map<String, dynamic> json) {
    return GroupStandingEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      unitId: (json['unit_id'] ?? json['unitId'] ?? json['team_id'] ?? json['id'] ?? '').toString(),
      unitName: (json['unit_name'] ?? json['unitName'] ?? json['team_name'] ?? json['name'] ?? 'Team').toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? json['logo_url'] ?? json['logoUrl'])?.toString(),
      slotNumber: (json['slot_number'] ?? json['slotNumber'] ?? json['slot'] as num?)?.toInt() ?? 0,
      matchesPlayed: (json['matches_played'] ?? json['matchesPlayed'] ?? json['matches'] as num?)?.toInt() ?? 0,
      kills: (json['kills'] as num?)?.toInt() ?? 0,
      placementPoints: (json['placement_points'] ?? json['placementPoints'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] ?? json['totalPoints'] ?? json['points'] as num?)?.toInt() ?? 0,
      status: QualificationStatus.fromJson(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'unit_id': unitId,
    'unit_name': unitName,
    'avatar_url': avatarUrl,
    'slot_number': slotNumber,
    'matches_played': matchesPlayed,
    'kills': kills,
    'placement_points': placementPoints,
    'total_points': totalPoints,
    'status': status.toJson(),
  };
}

/// ------------------------------------------------------------
/// TOURNAMENT GROUP MODEL
/// ------------------------------------------------------------

class TournamentGroupModel {
  final String id;
  final int groupNumber;
  final String groupName; // e.g. "Group A"
  final String? roomId;
  final String? roomPassword;
  final DateTime? roomReleasedAt;
  final List<GroupStandingEntry> standings;

  const TournamentGroupModel({
    required this.id,
    required this.groupNumber,
    required this.groupName,
    this.roomId,
    this.roomPassword,
    this.roomReleasedAt,
    required this.standings,
  });

  factory TournamentGroupModel.fromJson(Map<String, dynamic> json) {
    final rawStandings = json['standings'] as List<dynamic>? ?? [];
    return TournamentGroupModel(
      id: (json['id'] ?? json['group_id'] ?? '').toString(),
      groupNumber: (json['group_number'] ?? json['groupNumber'] as num?)?.toInt() ?? 1,
      groupName: (json['group_name'] ?? json['groupName'] ?? json['name'] ?? 'Group A').toString(),
      roomId: json['room_id']?.toString() ?? json['roomId']?.toString(),
      roomPassword: json['room_password']?.toString() ?? json['roomPassword']?.toString(),
      roomReleasedAt: json['room_released_at'] != null
          ? DateTime.tryParse(json['room_released_at'].toString())
          : (json['roomReleasedAt'] != null ? DateTime.tryParse(json['roomReleasedAt'].toString()) : null),
      standings: rawStandings
          .map((e) => GroupStandingEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_number': groupNumber,
    'group_name': groupName,
    'room_id': roomId,
    'room_password': roomPassword,
    'room_released_at': roomReleasedAt?.toIso8601String(),
    'standings': standings.map((e) => e.toJson()).toList(),
  };
}

/// ------------------------------------------------------------
/// TOURNAMENT STAGE MODEL
/// ------------------------------------------------------------

class TournamentStageModel {
  final int stageNumber;
  final String stageName; // e.g. "Round 1 (Qualifiers)", "Semi-Finals", "Grand Final"
  final StageStatus status;
  final int lobbyCount;
  final int unitsPerLobby;
  final int qualifiersPerLobby;
  final bool isGrandFinal;
  final bool isCompleted;
  final bool isActive;
  final List<TournamentGroupModel> groups;

  const TournamentStageModel({
    required this.stageNumber,
    required this.stageName,
    required this.status,
    required this.lobbyCount,
    required this.unitsPerLobby,
    required this.qualifiersPerLobby,
    required this.isGrandFinal,
    this.isCompleted = false,
    this.isActive = false,
    required this.groups,
  });

  factory TournamentStageModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['groups'] as List<dynamic>? ?? [];
    final stageNum = (json['stage_number'] ?? json['stageNumber'] as num?)?.toInt() ?? 1;
    final stageNameStr = (json['stage_name'] ?? json['stageName'] ?? 'Stage $stageNum').toString();
    final isGrand = json['is_grand_final'] as bool? ??
        json['isGrandFinal'] as bool? ??
        stageNameStr.toLowerCase().contains('grand');

    final isComp = json['is_completed'] as bool? ?? json['isCompleted'] as bool? ?? false;
    final isAct = json['is_active'] as bool? ?? json['isActive'] as bool? ?? false;

    return TournamentStageModel(
      stageNumber: stageNum,
      stageName: stageNameStr,
      status: StageStatus.fromJson(json['status']?.toString()),
      lobbyCount: (json['lobby_count'] ?? json['lobbyCount'] as num?)?.toInt() ?? 1,
      unitsPerLobby: (json['units_per_lobby'] ?? json['unitsPerLobby'] as num?)?.toInt() ?? 12,
      qualifiersPerLobby: (json['qualifiers_per_lobby'] ?? json['qualifiersPerLobby'] as num?)?.toInt() ?? 3,
      isGrandFinal: isGrand,
      isCompleted: isComp,
      isActive: isAct,
      groups: rawGroups
          .map((e) => TournamentGroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stage_number': stageNumber,
    'stage_name': stageName,
    'status': status.toJson(),
    'lobby_count': lobbyCount,
    'units_per_lobby': unitsPerLobby,
    'qualifiers_per_lobby': qualifiersPerLobby,
    'is_grand_final': isGrandFinal,
    'is_completed': isCompleted,
    'is_active': isActive,
    'groups': groups.map((e) => e.toJson()).toList(),
  };
}

/// ------------------------------------------------------------
/// MY ACTIVE ASSIGNMENT MODEL
/// ------------------------------------------------------------

class MyActiveAssignmentModel {
  final int currentStageNumber;
  final String stageName;
  final String groupId;
  final String groupName;
  final int assignedSlot;
  final bool roomCredentialsReleased;
  final String? roomId;
  final String? roomPassword;
  final DateTime? roomReleasedAt;
  final QualificationStatus myStatus;

  const MyActiveAssignmentModel({
    required this.currentStageNumber,
    required this.stageName,
    required this.groupId,
    required this.groupName,
    required this.assignedSlot,
    required this.roomCredentialsReleased,
    this.roomId,
    this.roomPassword,
    this.roomReleasedAt,
    required this.myStatus,
  });

  factory MyActiveAssignmentModel.fromJson(Map<String, dynamic> json) {
    return MyActiveAssignmentModel(
      currentStageNumber: (json['current_stage_number'] ?? json['currentStageNumber'] ?? json['stage_number'] as num?)?.toInt() ?? 1,
      stageName: (json['stage_name'] ?? json['stageName'] ?? 'Stage 1').toString(),
      groupId: (json['group_id'] ?? json['groupId'] ?? '').toString(),
      groupName: (json['group_name'] ?? json['groupName'] ?? 'Group A').toString(),
      assignedSlot: (json['assigned_slot'] ?? json['assignedSlot'] ?? json['slot_number'] as num?)?.toInt() ?? 1,
      roomCredentialsReleased: json['room_credentials_released'] as bool? ??
          json['roomCredentialsReleased'] as bool? ??
          (json['room_id'] != null && json['room_id'].toString().isNotEmpty),
      roomId: json['room_id']?.toString() ?? json['roomId']?.toString(),
      roomPassword: json['room_password']?.toString() ?? json['roomPassword']?.toString(),
      roomReleasedAt: json['room_released_at'] != null
          ? DateTime.tryParse(json['room_released_at'].toString())
          : (json['roomReleasedAt'] != null ? DateTime.tryParse(json['roomReleasedAt'].toString()) : null),
      myStatus: QualificationStatus.fromJson((json['my_status'] ?? json['myStatus'] ?? json['status'])?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'current_stage_number': currentStageNumber,
    'stage_name': stageName,
    'group_id': groupId,
    'group_name': groupName,
    'assigned_slot': assignedSlot,
    'room_credentials_released': roomCredentialsReleased,
    'room_id': roomId,
    'room_password': roomPassword,
    'room_released_at': roomReleasedAt?.toIso8601String(),
    'my_status': myStatus.toJson(),
  };
}

/// ------------------------------------------------------------
/// CLASH SQUAD KNOCKOUT BRACKET MODELS
/// ------------------------------------------------------------

class ClashSquadMatchModel {
  final String matchId;
  final String roundName; // e.g. "Round of 16", "Quarterfinals", "Semifinals", "Final"
  final int matchNumber;
  final String teamAId;
  final String teamAName;
  final String? teamALogo;
  final int scoreA;
  final String teamBId;
  final String teamBName;
  final String? teamBLogo;
  final int scoreB;
  final String? winnerId;
  final bool isCompleted;
  final bool isLive;

  const ClashSquadMatchModel({
    required this.matchId,
    required this.roundName,
    required this.matchNumber,
    required this.teamAId,
    required this.teamAName,
    this.teamALogo,
    this.scoreA = 0,
    required this.teamBId,
    required this.teamBName,
    this.teamBLogo,
    this.scoreB = 0,
    this.winnerId,
    this.isCompleted = false,
    this.isLive = false,
  });

  factory ClashSquadMatchModel.fromJson(Map<String, dynamic> json) {
    return ClashSquadMatchModel(
      matchId: (json['match_id'] ?? json['id'] ?? '').toString(),
      roundName: (json['round_name'] ?? json['round'] ?? 'Match').toString(),
      matchNumber: (json['match_number'] ?? json['matchNumber'] as num?)?.toInt() ?? 1,
      teamAId: (json['team_a_id'] ?? json['teamAId'] ?? json['team_a']?['id'] ?? '').toString(),
      teamAName: (json['team_a_name'] ?? json['teamAName'] ?? json['team_a']?['name'] ?? 'TBD').toString(),
      teamALogo: (json['team_a_logo'] ?? json['teamA']?['logo_url'])?.toString(),
      scoreA: (json['score_a'] ?? json['scoreA'] as num?)?.toInt() ?? 0,
      teamBId: (json['team_b_id'] ?? json['teamBId'] ?? json['team_b']?['id'] ?? '').toString(),
      teamBName: (json['team_b_name'] ?? json['teamBName'] ?? json['team_b']?['name'] ?? 'TBD').toString(),
      teamBLogo: (json['team_b_logo'] ?? json['teamB']?['logo_url'])?.toString(),
      scoreB: (json['score_b'] ?? json['scoreB'] as num?)?.toInt() ?? 0,
      winnerId: json['winner_id']?.toString() ?? json['winnerId']?.toString(),
      isCompleted: json['is_completed'] as bool? ?? json['isCompleted'] as bool? ?? false,
      isLive: json['is_live'] as bool? ?? json['isLive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'match_id': matchId,
    'round_name': roundName,
    'match_number': matchNumber,
    'team_a_id': teamAId,
    'team_a_name': teamAName,
    'team_a_logo': teamALogo,
    'score_a': scoreA,
    'team_b_id': teamBId,
    'team_b_name': teamBName,
    'team_b_logo': teamBLogo,
    'score_b': scoreB,
    'winner_id': winnerId,
    'is_completed': isCompleted,
    'is_live': isLive,
  };
}

class ClashSquadRoundModel {
  final int roundIndex;
  final String roundName; // e.g. "Quarterfinals"
  final List<ClashSquadMatchModel> matches;

  const ClashSquadRoundModel({
    required this.roundIndex,
    required this.roundName,
    required this.matches,
  });

  factory ClashSquadRoundModel.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'] as List<dynamic>? ?? [];
    return ClashSquadRoundModel(
      roundIndex: (json['round_index'] ?? json['roundIndex'] as num?)?.toInt() ?? 0,
      roundName: (json['round_name'] ?? json['roundName'] ?? json['name'] ?? 'Round').toString(),
      matches: rawMatches
          .map((e) => ClashSquadMatchModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'round_index': roundIndex,
    'round_name': roundName,
    'matches': matches.map((e) => e.toJson()).toList(),
  };
}

class ClashSquadBracketModel {
  final String tournamentId;
  final List<ClashSquadRoundModel> rounds;

  const ClashSquadBracketModel({
    required this.tournamentId,
    required this.rounds,
  });

  factory ClashSquadBracketModel.fromJson(Map<String, dynamic> json) {
    final rawRounds = (json['rounds'] ?? json['data'] ?? json['bracket']) as List<dynamic>? ?? [];
    return ClashSquadBracketModel(
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '').toString(),
      rounds: rawRounds
          .map((e) => ClashSquadRoundModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'tournament_id': tournamentId,
    'rounds': rounds.map((e) => e.toJson()).toList(),
  };
}
