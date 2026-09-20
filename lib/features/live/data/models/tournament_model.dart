/// ============================================================
/// TOURNAMENT MODEL (v2 - command center fields)
/// ============================================================
/// All new fields have defaults, so existing mock data and
/// JSON keep working unchanged.
/// ============================================================

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

  // ---- New fields ----
  final String tournamentCode; // e.g. "BX-2049"
  final int maxTeams;
  final String mode; // Solo / Duo / Squad
  final String mapName; // Bermuda
  final String matchType; // BR Ranked / CS
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
      maxTeams > 0 ? '${teams.length}/$maxTeams' : '${teams.length}';

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) f) =>
        (json[key] as List<dynamic>?)
            ?.map((e) => f(e as Map<String, dynamic>))
            .toList() ??
            <T>[];

    return TournamentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      game: json['game'] as String,
      bannerImageUrl: json['bannerImageUrl'] as String? ?? '',
      gameLogoUrl: json['gameLogoUrl'] as String? ?? '',
      prizePool: (json['prizePool'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? '₹',
      viewersCount: json['viewersCount'] as int? ?? 0,
      status: TournamentStatus.values.firstWhere(
            (e) => e.name == (json['status'] as String? ?? 'upcoming'),
        orElse: () => TournamentStatus.upcoming,
      ),
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      organizer: json['organizer'] as String? ?? '',
      accentColorHex: json['accentColorHex'] as String? ?? '#9B5CFF',
      teams: list('teams', TeamModel.fromJson),
      matches: list('matches', MatchModel.fromJson),
      tournamentCode: json['tournamentCode'] as String? ?? '',
      maxTeams: json['maxTeams'] as int? ?? 0,
      mode: json['mode'] as String? ?? '',
      mapName: json['mapName'] as String? ?? '',
      matchType: json['matchType'] as String? ?? '',
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0,
      organizerVerified: json['organizerVerified'] as bool? ?? false,
      perKillReward: (json['perKillReward'] as num?)?.toDouble() ?? 0,
      booyahBonus: (json['booyahBonus'] as num?)?.toDouble() ?? 0,
      prizeDistribution: list('prizeDistribution', PrizeTier.fromJson),
      pointsSystem: list('pointsSystem', PointsRow.fromJson),
      schedule: list('schedule', ScheduleStep.fromJson),
      rules: (json['rules'] as List<dynamic>?)?.cast<String>() ?? const [],
      announcements:
      (json['announcements'] as List<dynamic>?)?.cast<String>() ??
          const [],
      streamUrl: json['streamUrl'] as String?,
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
  final String captain; // new
  final int playersCount; // new

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
    id: json['id'] as String,
    name: json['name'] as String,
    logoUrl: json['logoUrl'] as String? ?? '',
    score: json['score'] as int? ?? 0,
    status: TeamStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'playing'),
      orElse: () => TeamStatus.playing,
    ),
    captain: json['captain'] as String? ?? '',
    playersCount: json['playersCount'] as int? ?? 0,
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
/// MATCH MODEL (unchanged)
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
    id: json['id'] as String,
    tournamentId: json['tournamentId'] as String,
    round: json['round'] as String? ?? '',
    teamA: TeamModel.fromJson(json['teamA'] as Map<String, dynamic>),
    teamB: TeamModel.fromJson(json['teamB'] as Map<String, dynamic>),
    matchTime: DateTime.tryParse(json['matchTime'] as String? ?? '') ??
        DateTime.now(),
    status: MatchStatus.values.firstWhere(
          (e) => e.name == (json['status'] as String? ?? 'upcoming'),
      orElse: () => MatchStatus.upcoming,
    ),
    mapOrMode: json['mapOrMode'] as String?,
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