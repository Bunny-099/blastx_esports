// ============================================================
// TOURNAMENT MODEL
// ============================================================

enum TournamentStatus { live, upcoming, completed }

class PrizeTier {
  final String label; // "1st", "2nd", "4th-10th"
  final double amount;
  const PrizeTier({required this.label, required this.amount});

  factory PrizeTier.fromJson(Map<String, dynamic> j) => PrizeTier(
    label: j['label'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0,
  );
  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};
}

class PointsRow {
  final String label; // "1st", "Per Kill"
  final String points; // "12", "+1"
  const PointsRow({required this.label, required this.points});

  factory PointsRow.fromJson(Map<String, dynamic> j) => PointsRow(
    label: j['label'] as String? ?? '',
    points: j['points'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {'label': label, 'points': points};
}

class ScheduleStep {
  final String title; // "Registration Opens"
  final String time; // "20 Sep, 10:00 AM"
  final bool done;
  const ScheduleStep(
      {required this.title, required this.time, this.done = false});

  factory ScheduleStep.fromJson(Map<String, dynamic> j) => ScheduleStep(
    title: j['title'] as String? ?? '',
    time: j['time'] as String? ?? '',
    done: j['done'] as bool? ?? false,
  );
  Map<String, dynamic> toJson() =>
      {'title': title, 'time': time, 'done': done};
}

class TournamentModel {
  final String id;
  final String name;
  final String game;
  final String bannerImageUrl;
  final String gameLogoUrl;
  final double prizePool;
  final String currency;
  final int viewersCount;
  final TournamentStatus status;
  final DateTime startTime;
  final String organizer;
  final List<TeamModel> teams;
  final List<MatchModel> matches;
  final String accentColorHex;

  // Command Center & Backend Fields
  final String tournamentCode; // e.g. "BX-2049"
  final int maxTeams;
  final String mode; // SOLO / DUO / SQUAD
  final String mapName; // BERMUDA
  final String matchType; // BATTLE_ROYALE / CLASH_SQUAD
  final double entryFee; // 0 = free
  final bool organizerVerified;
  final double perKillReward;
  final double booyahBonus;
  final List<PrizeTier> prizeDistribution;
  final List<PointsRow> pointsSystem;
  final List<ScheduleStep> schedule;
  final List<String> rules;
  final List<String> announcements;
  final String? streamUrl;
  final bool isRegistered;
  final int registeredCount;
  final int slotsLeft;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.game,
    required this.bannerImageUrl,
    required this.gameLogoUrl,
    required this.prizePool,
    required this.viewersCount,
    required this.status,
    required this.startTime,
    required this.organizer,
    this.currency = '₹',
    this.teams = const [],
    this.matches = const [],
    this.accentColorHex = '#9B5CFF',
    this.tournamentCode = '',
    this.maxTeams = 0,
    this.mode = '',
    this.mapName = '',
    this.matchType = '',
    this.entryFee = 0,
    this.organizerVerified = false,
    this.perKillReward = 0,
    this.booyahBonus = 0,
    this.prizeDistribution = const [],
    this.pointsSystem = const [],
    this.schedule = const [],
    this.rules = const [],
    this.announcements = const [],
    this.streamUrl,
    this.isRegistered = false,
    this.registeredCount = 0,
    this.slotsLeft = 0,
  });

  bool get isLive => status == TournamentStatus.live;
  bool get isFree => entryFee <= 0;

  String get formattedViewers {
    if (viewersCount >= 1000000) {
      return '${(viewersCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewersCount >= 1000) {
      return '${(viewersCount / 1000).toStringAsFixed(1)}K';
    }
    return viewersCount.toString();
  }

  String money(double v) => '$currency${v.toInt()}';
  String get formattedPrizePool => money(prizePool);
  String get formattedEntryFee => isFree ? 'FREE' : money(entryFee);
  String get teamsFilled =>
      maxTeams > 0 ? '${registeredCount > 0 ? registeredCount : teams.length}/$maxTeams' : '${teams.length}';

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List<dynamic>?)
            ?.map((e) => f(e as Map<String, dynamic>))
            .toList() ??
            <T>[];

    // Status parsing mapping
    final rawStatus = (json['status'] as String? ?? 'UPCOMING').toUpperCase();
    TournamentStatus parsedStatus;
    if (rawStatus == 'LIVE') {
      parsedStatus = TournamentStatus.live;
    } else if (rawStatus == 'COMPLETED') {
      parsedStatus = TournamentStatus.completed;
    } else {
      parsedStatus = TournamentStatus.upcoming;
    }

    // Prize distribution map or list parser
    List<PrizeTier> parsedPrizes = [];
    if (json['prize_distribution'] is List) {
      parsedPrizes = parseList('prize_distribution', PrizeTier.fromJson);
    } else if (json['prize_distribution'] is Map) {
      final map = json['prize_distribution'] as Map;
      parsedPrizes = map.entries.map((e) {
        final rankStr = e.key.toString();
        final suffix = rankStr == '1' ? 'st' : rankStr == '2' ? 'nd' : rankStr == '3' ? 'rd' : 'th';
        return PrizeTier(
          label: '$rankStr$suffix Place',
          amount: (e.value as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } else {
      parsedPrizes = parseList('prizeDistribution', PrizeTier.fromJson);
    }

    return TournamentModel(
      id: (json['id'] ?? '') as String,
      name: (json['title'] ?? json['name'] ?? 'Tournament') as String,
      game: (json['game'] ?? 'Free Fire') as String,
      bannerImageUrl: (json['banner_url'] ?? json['bannerImageUrl'] ?? '') as String,
      gameLogoUrl: (json['gameLogoUrl'] ?? '') as String,
      prizePool: (json['prize_pool'] ?? json['prizePool'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? '₹') as String,
      viewersCount: (json['viewersCount'] as num?)?.toInt() ?? 0,
      status: parsedStatus,
      startTime: DateTime.tryParse((json['starts_at'] ?? json['startTime'] ?? '') as String) ?? DateTime.now(),
      organizer: (json['organizer'] ?? 'BlastX Esports') as String,
      accentColorHex: (json['accentColorHex'] ?? '#9B5CFF') as String,
      teams: parseList('teams', TeamModel.fromJson),
      matches: parseList('matches', MatchModel.fromJson),
      tournamentCode: (json['tournamentCode'] ?? '') as String,
      maxTeams: (json['max_slots'] ?? json['maxTeams'] as num?)?.toInt() ?? 0,
      mode: (json['team_mode'] ?? json['mode'] ?? '') as String,
      mapName: (json['map'] ?? json['mapName'] ?? '') as String,
      matchType: (json['format'] ?? json['matchType'] ?? '') as String,
      entryFee: (json['entry_fee'] ?? json['entryFee'] as num?)?.toDouble() ?? 0,
      organizerVerified: (json['organizerVerified'] as bool?) ?? false,
      perKillReward: (json['perKillReward'] as num?)?.toDouble() ?? 0,
      booyahBonus: (json['booyahBonus'] as num?)?.toDouble() ?? 0,
      prizeDistribution: parsedPrizes,
      pointsSystem: parseList('pointsSystem', PointsRow.fromJson),
      schedule: parseList('schedule', ScheduleStep.fromJson),
      rules: (json['rules'] as List<dynamic>?)?.cast<String>() ??
          ((json['description'] is String && (json['description'] as String).isNotEmpty)
              ? [(json['description'] as String)]
              : const []),
      announcements: (json['announcements'] as List<dynamic>?)?.cast<String>() ?? const [],
      streamUrl: json['streamUrl'] as String?,
      isRegistered: (json['is_registered'] as bool?) ?? false,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      slotsLeft: (json['slots_left'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'game': game,
    'bannerImageUrl': bannerImageUrl,
    'gameLogoUrl': gameLogoUrl,
    'prizePool': prizePool,
    'currency': currency,
    'viewersCount': viewersCount,
    'status': status.name,
    'startTime': startTime.toIso8601String(),
    'organizer': organizer,
    'accentColorHex': accentColorHex,
    'teams': teams.map((e) => e.toJson()).toList(),
    'matches': matches.map((e) => e.toJson()).toList(),
    'tournamentCode': tournamentCode,
    'maxTeams': maxTeams,
    'mode': mode,
    'mapName': mapName,
    'matchType': matchType,
    'entryFee': entryFee,
    'organizerVerified': organizerVerified,
    'perKillReward': perKillReward,
    'booyahBonus': booyahBonus,
    'prizeDistribution': prizeDistribution.map((e) => e.toJson()).toList(),
    'pointsSystem': pointsSystem.map((e) => e.toJson()).toList(),
    'schedule': schedule.map((e) => e.toJson()).toList(),
    'rules': rules,
    'announcements': announcements,
    'streamUrl': streamUrl,
    'is_registered': isRegistered,
    'registered_count': registeredCount,
    'slots_left': slotsLeft,
  };
}

/// ------------------------------------------------------------
/// TEAM MODEL
/// ------------------------------------------------------------
enum TeamStatus { winning, losing, eliminated, qualified, playing }

class TeamModel {
  final String id;
  final String name;
  final String logoUrl;
  final int score;
  final TeamStatus status;
  final String captain;
  final int playersCount;

  const TeamModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.score = 0,
    this.status = TeamStatus.playing,
    this.captain = '',
    this.playersCount = 0,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) => TeamModel(
    id: (json['id'] ?? '') as String,
    name: (json['team_name'] ?? json['name'] ?? '') as String,
    logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '') as String,
    score: (json['total_points'] ?? json['score'] as num?)?.toInt() ?? 0,
    status: TeamStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'playing').toLowerCase(),
      orElse: () => TeamStatus.playing,
    ),
    captain: (json['captain'] ?? '') as String,
    playersCount: (json['playersCount'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'score': score,
    'status': status.name,
    'captain': captain,
    'playersCount': playersCount,
  };
}

/// ------------------------------------------------------------
/// MATCH MODEL
/// ------------------------------------------------------------
enum MatchStatus { live, upcoming, completed }

class MatchModel {
  final String id;
  final String tournamentId;
  final String round;
  final TeamModel teamA;
  final TeamModel teamB;
  final DateTime matchTime;
  final MatchStatus status;
  final String? mapOrMode;

  const MatchModel({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.teamA,
    required this.teamB,
    required this.matchTime,
    this.status = MatchStatus.upcoming,
    this.mapOrMode,
  });

  bool get isLive => status == MatchStatus.live;

  factory MatchModel.fromJson(Map<String, dynamic> json) => MatchModel(
    id: (json['id'] ?? '') as String,
    tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
    round: (json['round'] ?? '') as String,
    teamA: json['teamA'] != null
        ? TeamModel.fromJson(json['teamA'] as Map<String, dynamic>)
        : const TeamModel(id: '', name: 'Team A', logoUrl: ''),
    teamB: json['teamB'] != null
        ? TeamModel.fromJson(json['teamB'] as Map<String, dynamic>)
        : const TeamModel(id: '', name: 'Team B', logoUrl: ''),
    matchTime: DateTime.tryParse((json['match_time'] ?? json['matchTime'] ?? '') as String) ??
        DateTime.now(),
    status: MatchStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'upcoming').toLowerCase(),
      orElse: () => MatchStatus.upcoming,
    ),
    mapOrMode: (json['map_or_mode'] ?? json['mapOrMode']) as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournamentId': tournamentId,
    'round': round,
    'teamA': teamA.toJson(),
    'teamB': teamB.toJson(),
    'matchTime': matchTime.toIso8601String(),
    'status': status.name,
    'mapOrMode': mapOrMode,
  };
}
