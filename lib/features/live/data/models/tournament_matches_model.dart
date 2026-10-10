import 'package:flutter/foundation.dart';

/// ============================================================
/// TOURNAMENT MATCHES & ROOM CREDENTIALS DTO
/// Master Prompt Synchronized Engine for iOS & Android
/// ============================================================

/// Exact Backend Tournament Status
enum TournamentEngineStatus {
  upcoming,
  registrationOpen,
  registrationClosed,
  live,
  completed,
  cancelled,
}

extension TournamentEngineStatusX on TournamentEngineStatus {
  String get rawValue => switch (this) {
        TournamentEngineStatus.upcoming => 'UPCOMING',
        TournamentEngineStatus.registrationOpen => 'REGISTRATION_OPEN',
        TournamentEngineStatus.registrationClosed => 'REGISTRATION_CLOSED',
        TournamentEngineStatus.live => 'LIVE',
        TournamentEngineStatus.completed => 'COMPLETED',
        TournamentEngineStatus.cancelled => 'CANCELLED',
      };
}

/// Exact Backend Round Type
enum RoundType {
  round1,
  round2,
  round3,
  grandFinal,
}

extension RoundTypeX on RoundType {
  String get rawValue => switch (this) {
        RoundType.round1 => 'ROUND_1',
        RoundType.round2 => 'ROUND_2',
        RoundType.round3 => 'ROUND_3',
        RoundType.grandFinal => 'GRAND_FINAL',
      };

  String get displayName => switch (this) {
        RoundType.round1 => 'Round 1 (Qualifiers)',
        RoundType.round2 => 'Round 2 (Quarter/Semi Finals)',
        RoundType.round3 => 'Round 3 (Wild Card & Advance)',
        RoundType.grandFinal => 'Grand Final',
      };
}

/// Exact Backend Round Status
enum RoundStatus {
  scheduled,
  live,
  tieBreakerPending,
  completed,
}

/// Exact Backend Qualification Status
enum QualificationStatus {
  qualifiedRound2, // Green Badge
  qualifiedRound3, // Amber Badge
  qualifiedGrandFinal, // Gold / Cyan Badge
  eliminated, // Gray / Dimmed
  waitingResult, // Neutral / In Progress
}

extension QualificationStatusX on QualificationStatus {
  String get badgeLabel => switch (this) {
        QualificationStatus.qualifiedRound2 => '✅ QUALIFIED FOR ROUND 2',
        QualificationStatus.qualifiedRound3 => '⚡ ADVANCED TO ROUND 3',
        QualificationStatus.qualifiedGrandFinal => '🏆 QUALIFIED FOR GRAND FINAL',
        QualificationStatus.eliminated => '❌ ELIMINATED',
        QualificationStatus.waitingResult => '⏳ WAITING RESULT',
      };
}

/// Wild Card Window Status
enum WildCardStatus {
  closed,
  open,
  locked,
}

extension WildCardStatusX on WildCardStatus {
  String get rawValue => switch (this) {
        WildCardStatus.closed => 'CLOSED',
        WildCardStatus.open => 'OPEN',
        WildCardStatus.locked => 'LOCKED',
      };
}

/// Wild Card Window Model
@immutable
class WildCardWindowModel {
  final WildCardStatus status;
  final int claimedSlots;
  final int maxSlots; // Default 8
  final String bannerText;

  const WildCardWindowModel({
    this.status = WildCardStatus.closed,
    this.claimedSlots = 0,
    this.maxSlots = 8,
    this.bannerText = '🔥 Wild Card Open: 8 Exclusive Slots for Direct Round 3 Entry!',
  });

  bool get isOpen => status == WildCardStatus.open && claimedSlots < maxSlots;
  bool get isFull => claimedSlots >= maxSlots;

  factory WildCardWindowModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'CLOSED').toString().toUpperCase();
    final parsedStatus = switch (rawStatus) {
      'OPEN' => WildCardStatus.open,
      'LOCKED' => WildCardStatus.locked,
      _ => WildCardStatus.closed,
    };

    return WildCardWindowModel(
      status: parsedStatus,
      claimedSlots: (json['claimed_slots'] ?? json['claimedSlots'] as num?)?.toInt() ?? 0,
      maxSlots: (json['max_slots'] ?? json['maxSlots'] as num?)?.toInt() ?? 8,
      bannerText: (json['banner_text'] ?? json['bannerText'] ??
              '🔥 Wild Card Open: 8 Exclusive Slots for Direct Round 3 Entry!')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.rawValue,
        'claimed_slots': claimedSlots,
        'max_slots': maxSlots,
        'banner_text': bannerText,
      };
}

/// Team Round Status (Backwards Compatibility)
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
  final String groupName; // e.g., "Group 1", "Group A"
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
  final String roundName; // e.g., "Round 1 (Qualifiers)", "Round 2", "Grand Finals"
  final int roundNumber;
  final RoundType roundType;
  final RoundStatus status;
  final List<GroupModel> groups;

  const RoundModel({
    required this.id,
    required this.roundName,
    this.roundNumber = 1,
    this.roundType = RoundType.round1,
    this.status = RoundStatus.scheduled,
    this.groups = const [],
  });

  bool get isTieBreakerPending => status == RoundStatus.tieBreakerPending;

  factory RoundModel.fromJson(Map<String, dynamic> json) {
    final rawGroups = (json['groups'] as List<dynamic>?) ?? [];
    final groupsList = rawGroups
        .map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawRoundType = (json['round_type'] ?? json['roundType'] ?? '').toString().toUpperCase();
    final parsedRoundType = switch (rawRoundType) {
      'ROUND_2' => RoundType.round2,
      'ROUND_3' => RoundType.round3,
      'GRAND_FINAL' => RoundType.grandFinal,
      _ => RoundType.round1,
    };

    final rawStatus = (json['status'] ?? '').toString().toUpperCase();
    final parsedStatus = switch (rawStatus) {
      'LIVE' => RoundStatus.live,
      'TIE_BREAKER_PENDING' => RoundStatus.tieBreakerPending,
      'COMPLETED' => RoundStatus.completed,
      _ => RoundStatus.scheduled,
    };

    return RoundModel(
      id: (json['id'] ?? json['round_id'] ?? '').toString(),
      roundName: (json['round_name'] ?? json['roundName'] ?? 'Round 1').toString(),
      roundNumber: (json['round_number'] ?? json['roundNumber'] as num?)?.toInt() ?? 1,
      roundType: parsedRoundType,
      status: parsedStatus,
      groups: groupsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'round_name': roundName,
        'round_number': roundNumber,
        'round_type': roundType.rawValue,
        'status': status.name,
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
  final RoundType roundType;
  final String groupId;
  final String groupName;
  final TeamRoundStatus status; // upcoming, live, completed, qualified, disqualified
  final QualificationStatus qualificationStatus;
  final bool isDirectFinalist; // Round 2 Top 2 Teams
  final String? messageBanner;
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
    this.roundType = RoundType.round1,
    this.groupId = '',
    required this.groupName,
    required this.status,
    this.qualificationStatus = QualificationStatus.waitingResult,
    this.isDirectFinalist = false,
    this.messageBanner,
    this.opponentTeamNames = const [],
    this.roomId,
    this.password,
    this.isPublished = false,
    this.revealAt,
    this.startsAt,
    this.map = 'Bermuda',
  });

  bool get isEliminated =>
      status == TeamRoundStatus.disqualified ||
      qualificationStatus == QualificationStatus.eliminated;

  bool get isQualified =>
      status == TeamRoundStatus.qualified ||
      qualificationStatus == QualificationStatus.qualifiedRound2 ||
      qualificationStatus == QualificationStatus.qualifiedRound3 ||
      qualificationStatus == QualificationStatus.qualifiedGrandFinal;

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

    final rawQual = (json['qualification_status'] ?? json['qualificationStatus'] ?? '')
        .toString()
        .toUpperCase();
    final parsedQual = switch (rawQual) {
      'QUALIFIED_ROUND_2' => QualificationStatus.qualifiedRound2,
      'QUALIFIED_ROUND_3' => QualificationStatus.qualifiedRound3,
      'QUALIFIED_GRAND_FINAL' => QualificationStatus.qualifiedGrandFinal,
      'ELIMINATED' => QualificationStatus.eliminated,
      _ => QualificationStatus.waitingResult,
    };

    final rawRoundType = (json['round_type'] ?? json['roundType'] ?? '').toString().toUpperCase();
    final parsedRoundType = switch (rawRoundType) {
      'ROUND_2' => RoundType.round2,
      'ROUND_3' => RoundType.round3,
      'GRAND_FINAL' => RoundType.grandFinal,
      _ => RoundType.round1,
    };

    final rawRevealAt = json['reveal_at'] ?? json['revealAt'] ?? json['visible_from'];
    final parsedRevealAt =
        rawRevealAt != null ? DateTime.tryParse(rawRevealAt.toString()) : null;

    final rawStartsAt = json['starts_at'] ?? json['startsAt'];
    final parsedStartsAt =
        rawStartsAt != null ? DateTime.tryParse(rawStartsAt.toString()) : null;

    final rawOpponentsList = json['opponent_team_names'] ?? json['opponentTeams'];
    final opponentList = rawOpponentsList is List
        ? rawOpponentsList.map((e) => e.toString()).toList()
        : <String>[];

    return UserMatchContext(
      teamId: (json['team_id'] ?? json['teamId'] ?? '').toString(),
      teamName: (json['team_name'] ?? json['teamName'] ?? 'Your Team').toString(),
      roundId: (json['round_id'] ?? json['roundId'] ?? '').toString(),
      roundName: (json['round_name'] ?? json['roundName'] ?? 'Round 1').toString(),
      roundType: parsedRoundType,
      groupId: (json['group_id'] ?? json['groupId'] ?? '').toString(),
      groupName: (json['group_name'] ?? json['groupName'] ?? 'Group 1').toString(),
      status: parsedStatus,
      qualificationStatus: parsedQual,
      isDirectFinalist: (json['is_direct_finalist'] ?? json['isDirectFinalist'] ?? false) as bool,
      messageBanner: (json['message_banner'] ?? json['messageBanner'])?.toString(),
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
        'round_type': roundType.rawValue,
        'group_id': groupId,
        'group_name': groupName,
        'status': status.name,
        'qualification_status': qualificationStatus.name,
        'is_direct_finalist': isDirectFinalist,
        'message_banner': messageBanner,
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
  final WildCardWindowModel? wildCardWindow;
  final int maxTeamsPerGroup;
  final bool isUserRegistered;

  const TournamentMatchesResponse({
    required this.tournamentId,
    this.userContext,
    this.rounds = const [],
    this.wildCardWindow,
    this.maxTeamsPerGroup = 12,
    this.isUserRegistered = false,
  });

  factory TournamentMatchesResponse.fromJson(Map<String, dynamic> json) {
    final rawUserContext = json['user_context'] ?? json['userContext'];
    final parsedUserContext = rawUserContext is Map
        ? UserMatchContext.fromJson(Map<String, dynamic>.from(rawUserContext))
        : null;

    final rawRounds = (json['rounds'] as List<dynamic>?) ?? [];
    final parsedRounds = rawRounds
        .map((e) => RoundModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawWildCard = json['wild_card_window'] ?? json['wildCardWindow'];
    final parsedWildCard = rawWildCard is Map
        ? WildCardWindowModel.fromJson(Map<String, dynamic>.from(rawWildCard))
        : null;

    return TournamentMatchesResponse(
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '').toString(),
      userContext: parsedUserContext,
      rounds: parsedRounds,
      wildCardWindow: parsedWildCard,
      maxTeamsPerGroup: (json['max_teams_per_group'] ?? json['maxTeamsPerGroup'] as num?)?.toInt() ?? 12,
      isUserRegistered: (json['is_user_registered'] ?? json['isUserRegistered'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'tournament_id': tournamentId,
        'user_context': userContext?.toJson(),
        'rounds': rounds.map((e) => e.toJson()).toList(),
        'wild_card_window': wildCardWindow?.toJson(),
        'max_teams_per_group': maxTeamsPerGroup,
        'is_user_registered': isUserRegistered,
      };
}
