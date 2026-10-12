import 'package:flutter/foundation.dart';

/// User access level to match credentials and participation
enum MyAccess {
  playing,
  nonPlaying,
  none;

  static MyAccess fromString(String? val) {
    if (val == null) return MyAccess.none;
    switch (val.toUpperCase().trim()) {
      case 'PLAYING':
        return MyAccess.playing;
      case 'NON_PLAYING':
      case 'NONPLAYING':
      case 'MANAGER':
      case 'SUBSTITUTE':
        return MyAccess.nonPlaying;
      default:
        return MyAccess.none;
    }
  }

  bool get isPlaying => this == MyAccess.playing;
  bool get isNonPlaying => this == MyAccess.nonPlaying;
  bool get isNone => this == MyAccess.none;
}

/// Team / player state in tournament match center
enum MatchCenterState {
  active,
  qualified,
  eliminated,
  disqualified,
  completed;

  static MatchCenterState fromString(String? val) {
    if (val == null) return MatchCenterState.active;
    switch (val.toUpperCase().trim()) {
      case 'ACTIVE':
        return MatchCenterState.active;
      case 'QUALIFIED':
        return MatchCenterState.qualified;
      case 'ELIMINATED':
        return MatchCenterState.eliminated;
      case 'DISQUALIFIED':
        return MatchCenterState.disqualified;
      case 'COMPLETED':
        return MatchCenterState.completed;
      default:
        return MatchCenterState.active;
    }
  }

  String get label => switch (this) {
        MatchCenterState.active => 'ACTIVE',
        MatchCenterState.qualified => 'QUALIFIED',
        MatchCenterState.eliminated => 'ELIMINATED',
        MatchCenterState.disqualified => 'DISQUALIFIED',
        MatchCenterState.completed => 'COMPLETED',
      };
}

/// Status of an individual match unit
enum MatchUnitStatus {
  scheduled,
  live,
  completed;

  static MatchUnitStatus fromString(String? val) {
    if (val == null) return MatchUnitStatus.scheduled;
    switch (val.toUpperCase().trim()) {
      case 'SCHEDULED':
      case 'UPCOMING':
        return MatchUnitStatus.scheduled;
      case 'LIVE':
        return MatchUnitStatus.live;
      case 'COMPLETED':
      case 'FINISHED':
        return MatchUnitStatus.completed;
      default:
        return MatchUnitStatus.scheduled;
    }
  }

  String get label => switch (this) {
        MatchUnitStatus.scheduled => 'SCHEDULED',
        MatchUnitStatus.live => 'LIVE NOW',
        MatchUnitStatus.completed => 'COMPLETED',
      };
}

/// Status of room credentials availability for a match
enum RoomState {
  hidden,
  published,
  notEligible;

  static RoomState fromString(String? val) {
    if (val == null) return RoomState.hidden;
    switch (val.toUpperCase().trim()) {
      case 'HIDDEN':
      case 'LOCKED':
        return RoomState.hidden;
      case 'PUBLISHED':
      case 'RERELEASED':
      case 'READY':
        return RoomState.published;
      case 'NOT_ELIGIBLE':
      case 'INELIGIBLE':
      case 'NOT_PLAYING':
        return RoomState.notEligible;
      default:
        return RoomState.hidden;
    }
  }

  bool get isHidden => this == RoomState.hidden;
  bool get isPublished => this == RoomState.published;
  bool get isNotEligible => this == RoomState.notEligible;
}

/// Player's status summary in match center
class MyStatusModel {
  final MatchCenterState state;
  final String? currentRound;
  final String? eliminatedInRound;
  final int? finalRank;
  final int? rank;
  final int totalPoints;
  final int totalKills;

  const MyStatusModel({
    required this.state,
    this.currentRound,
    this.eliminatedInRound,
    this.finalRank,
    this.rank,
    this.totalPoints = 0,
    this.totalKills = 0,
  });

  factory MyStatusModel.fromJson(Map<String, dynamic> json) {
    return MyStatusModel(
      state: MatchCenterState.fromString(json['state']?.toString()),
      currentRound: json['current_round']?.toString() ?? json['currentRound']?.toString(),
      eliminatedInRound: json['eliminated_in_round']?.toString() ?? json['eliminatedInRound']?.toString(),
      finalRank: (json['final_rank'] ?? json['finalRank']) as int?,
      rank: (json['rank']) as int?,
      totalPoints: (json['total_points'] ?? json['totalPoints'] ?? 0) as int,
      totalKills: (json['total_kills'] ?? json['totalKills'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'state': state.name.toUpperCase(),
        'current_round': currentRound,
        'eliminated_in_round': eliminatedInRound,
        'final_rank': finalRank,
        'rank': rank,
        'total_points': totalPoints,
        'total_kills': totalKills,
      };
}

/// Result for a completed match unit
class MyMatchResultModel {
  final int placement;
  final int kills;
  final int totalPoints;

  const MyMatchResultModel({
    required this.placement,
    required this.kills,
    required this.totalPoints,
  });

  factory MyMatchResultModel.fromJson(Map<String, dynamic> json) {
    return MyMatchResultModel(
      placement: (json['placement'] ?? 0) as int,
      kills: (json['kills'] ?? 0) as int,
      totalPoints: (json['total_points'] ?? json['totalPoints'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'placement': placement,
        'kills': kills,
        'total_points': totalPoints,
      };
}

/// Single match unit in a round
class MatchCenterMatchItemModel {
  final String matchKey;
  final int matchNumber;
  final String groupName;
  final String map;
  final MatchUnitStatus status;
  final DateTime scheduledAt;
  final RoomState roomState;
  final DateTime? roomRevealAt;
  final MyMatchResultModel? myResult;
  final String? recordingStatus;
  final String? streamUrl;

  const MatchCenterMatchItemModel({
    required this.matchKey,
    required this.matchNumber,
    required this.groupName,
    required this.map,
    required this.status,
    required this.scheduledAt,
    required this.roomState,
    this.roomRevealAt,
    this.myResult,
    this.recordingStatus,
    this.streamUrl,
  });

  factory MatchCenterMatchItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final rawResult = json['my_result'] ?? json['myResult'];

    return MatchCenterMatchItemModel(
      matchKey: json['match_key']?.toString() ?? json['matchKey']?.toString() ?? '',
      matchNumber: (json['match_number'] ?? json['matchNumber'] ?? 1) as int,
      groupName: json['group_name']?.toString() ?? json['groupName']?.toString() ?? 'Group A',
      map: json['map']?.toString() ?? 'Bermuda',
      status: MatchUnitStatus.fromString(json['status']?.toString()),
      scheduledAt: parseDate(json['scheduled_at'] ?? json['scheduledAt']),
      roomState: RoomState.fromString(json['room_state']?.toString() ?? json['roomState']?.toString()),
      roomRevealAt: parseNullableDate(json['room_reveal_at'] ?? json['roomRevealAt']),
      myResult: rawResult is Map<String, dynamic>
          ? MyMatchResultModel.fromJson(rawResult)
          : (rawResult is Map ? MyMatchResultModel.fromJson(Map<String, dynamic>.from(rawResult)) : null),
      recordingStatus: json['recording_status']?.toString() ?? json['recordingStatus']?.toString(),
      streamUrl: json['stream_url']?.toString() ?? json['streamUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'match_key': matchKey,
        'match_number': matchNumber,
        'group_name': groupName,
        'map': map,
        'status': status.name.toUpperCase(),
        'scheduled_at': scheduledAt.toIso8601String(),
        'room_state': roomState.name.toUpperCase(),
        'room_reveal_at': roomRevealAt?.toIso8601String(),
        'my_result': myResult?.toJson(),
        'recording_status': recordingStatus,
        'stream_url': streamUrl,
      };
}

/// Round item containing matches
class MatchCenterRoundModel {
  final String key;
  final String name;
  final String? roundType;
  final String? status;
  final List<MatchCenterMatchItemModel> matches;

  const MatchCenterRoundModel({
    required this.key,
    required this.name,
    this.roundType,
    this.status,
    required this.matches,
  });

  factory MatchCenterRoundModel.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    final matchItems = <MatchCenterMatchItemModel>[];
    if (rawMatches is List) {
      for (final m in rawMatches) {
        if (m is Map) {
          matchItems.add(MatchCenterMatchItemModel.fromJson(Map<String, dynamic>.from(m)));
        }
      }
    }

    return MatchCenterRoundModel(
      key: json['key']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Round 1',
      roundType: json['round_type']?.toString() ?? json['roundType']?.toString(),
      status: json['status']?.toString(),
      matches: matchItems,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
        'round_type': roundType,
        'status': status,
        'matches': matches.map((m) => m.toJson()).toList(),
      };
}

/// Root Match Center response payload
class MatchCenterModel {
  final MyAccess myAccess;
  final String? myRole;
  final MyStatusModel? myStatus;
  final List<MatchCenterRoundModel> rounds;

  const MatchCenterModel({
    required this.myAccess,
    this.myRole,
    this.myStatus,
    required this.rounds,
  });

  factory MatchCenterModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;

    final rawStatus = rawData['my_status'] ?? rawData['myStatus'];
    final rawRounds = rawData['rounds'];

    final roundList = <MatchCenterRoundModel>[];
    if (rawRounds is List) {
      for (final r in rawRounds) {
        if (r is Map) {
          roundList.add(MatchCenterRoundModel.fromJson(Map<String, dynamic>.from(r)));
        }
      }
    }

    return MatchCenterModel(
      myAccess: MyAccess.fromString(rawData['my_access']?.toString() ?? rawData['myAccess']?.toString()),
      myRole: rawData['my_role']?.toString() ?? rawData['myRole']?.toString(),
      myStatus: rawStatus is Map<String, dynamic>
          ? MyStatusModel.fromJson(rawStatus)
          : (rawStatus is Map ? MyStatusModel.fromJson(Map<String, dynamic>.from(rawStatus)) : null),
      rounds: roundList,
    );
  }

  Map<String, dynamic> toJson() => {
        'my_access': myAccess.name.toUpperCase(),
        'my_role': myRole,
        'my_status': myStatus?.toJson(),
        'rounds': rounds.map((r) => r.toJson()).toList(),
      };
}
