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
  final List<BracketStageModel> stages;
  final String? streamUrl;
  final bool? isRegistered;
  final int registeredCount;
  final int slotsLeft;

  // New Optional Model Fields
  final DateTime? startsAt;
  final DateTime? registrationOpensAt;
  final DateTime? registrationClosesAt;
  final int? maxSlots;
  final int? filledSlots;
  final String description;

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
    this.stages = const [],
    this.streamUrl,
    this.isRegistered,
    this.registeredCount = 0,
    this.slotsLeft = 0,
    this.startsAt,
    this.registrationOpensAt,
    this.registrationClosesAt,
    this.maxSlots,
    this.filledSlots,
    this.description = '',
  });

  bool get isLive => status == TournamentStatus.live;
  bool get isFree => entryFee <= 0;

  /// Display title in app after stripping [FF Live] or [BlastX] prefix
  String get displayTitle {
    var t = name.trim();
    if (t.startsWith('[FF Live]')) {
      return t.substring('[FF Live]'.length).trim();
    }
    if (t.startsWith('[BlastX]')) {
      return t.substring('[BlastX]'.length).trim();
    }
    return t;
  }

  /// Filter check for Free Fire Live tab according to Mobile App Filter Rules:
  /// item.title.startsWith("[FF Live]") OR item.description?.includes("[SECTION:FREEFIRE_LIVE]")
  /// OR (item.game_slug === "free_fire" && !item.title.startsWith("[BlastX]"))
  bool get isFreeFireLiveSection {
    final titleLower = name.trim();
    final rulesStr = rules.join(' ');
    final descriptionMatch = description.contains('[SECTION:FREEFIRE_LIVE]') || rulesStr.contains('[SECTION:FREEFIRE_LIVE]');
    final titlePrefix = titleLower.startsWith('[FF Live]');
    final gameIsFF = game.toLowerCase().contains('free fire') || game.toLowerCase() == 'free_fire';

    if (titlePrefix || descriptionMatch) return true;
    if (gameIsFF && !titleLower.startsWith('[BlastX]')) return true;
    return false;
  }

  /// Filter check for BlastX E-Sports tab according to Mobile App Filter Rules:
  /// item.title.startsWith("[BlastX]") OR item.description?.includes("[SECTION:BLASTX]")
  bool get isBlastXSection {
    final titleLower = name.trim();
    final rulesStr = rules.join(' ');
    final descriptionMatch = description.contains('[SECTION:BLASTX]') || rulesStr.contains('[SECTION:BLASTX]');
    final titlePrefix = titleLower.startsWith('[BlastX]');

    if (titlePrefix || descriptionMatch) return true;
    return false;
  }

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

  // TODO(backend): remove mock - Fallback getters when new fields are null from backend
  int get effectiveFilledSlots =>
      filledSlots ?? (registeredCount > 0 ? registeredCount : (teams.isNotEmpty ? teams.length : 32));

  int get effectiveMaxSlots =>
      maxSlots ?? (maxTeams > 0 ? maxTeams : 48);

  DateTime get effectiveStartsAt => startsAt ?? startTime;

  bool get effectiveIsRegistered => isRegistered ?? false;

  /// Helper: Format slots as "32/48 slots"
  String get slotsText => '$effectiveFilledSlots/$effectiveMaxSlots slots';

  /// Helper: Progress fraction between 0.0 and 1.0
  double get slotsProgress {
    final max = effectiveMaxSlots;
    if (max <= 0) return 0.0;
    return (effectiveFilledSlots / max).clamp(0.0, 1.0);
  }

  /// Helper: Indicates if the tournament capacity has been reached
  bool get isFull => effectiveMaxSlots > 0 && effectiveFilledSlots >= effectiveMaxSlots;

  /// Checks if registration is currently open
  bool get isRegistrationOpen {
    if (status == TournamentStatus.completed) return false;
    if (isLive) return false;
    if (isFull) return false;

    final now = DateTime.now();
    if (registrationClosesAt != null && now.isAfter(registrationClosesAt!)) {
      return false;
    }
    if (now.isAfter(effectiveStartsAt)) {
      return false;
    }
    if (registrationOpensAt != null && now.isBefore(registrationOpensAt!)) {
      return false;
    }
    return true;
  }

  /// Checks if registration is closed
  bool get isRegistrationClosed {
    if (status == TournamentStatus.completed) return false;
    if (isLive) return false;
    if (isFull) return true;

    final now = DateTime.now();
    if (registrationClosesAt != null && now.isAfter(registrationClosesAt!)) {
      return true;
    }
    if (now.isAfter(effectiveStartsAt)) {
      return true;
    }
    return false;
  }

  /// Checks if registration opens in the future
  bool get isRegistrationOpensSoon {
    if (status == TournamentStatus.completed || isLive) return false;
    final now = DateTime.now();
    return registrationOpensAt != null && now.isBefore(registrationOpensAt!);
  }

  /// Button text CTA representation for cards
  String get actionButtonText {
    if (isLive) return 'WATCH';
    if (effectiveIsRegistered) return 'REGISTERED ✓';
    if (status == TournamentStatus.completed) return 'COMPLETED';
    if (isRegistrationOpen) return 'REGISTRATION OPEN';
    if (isRegistrationClosed) return 'REGISTRATION CLOSED';
    if (isRegistrationOpensSoon) return 'OPENS SOON';
    return 'VIEW';
  }

  /// Concise status badge text for top/bottom badges
  String get statusBadgeText {
    if (isLive) return 'LIVE';
    if (effectiveIsRegistered) return 'Registered ✓';
    if (status == TournamentStatus.completed) return 'Ended';
    if (isRegistrationOpen) return 'Registration Open';
    if (isRegistrationClosed) return 'Registration Closed';
    if (isRegistrationOpensSoon) return 'Opens Soon';
    return 'Upcoming';
  }

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
      stages: parseList('stages', BracketStageModel.fromJson),
      streamUrl: json['streamUrl'] as String?,
      isRegistered: json['is_registered'] as bool?,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      slotsLeft: (json['slots_left'] as num?)?.toInt() ?? 0,
      startsAt: json['starts_at'] != null ? DateTime.tryParse(json['starts_at'] as String) : null,
      registrationOpensAt: json['registration_opens_at'] != null ? DateTime.tryParse(json['registration_opens_at'] as String) : null,
      registrationClosesAt: json['registration_closes_at'] != null ? DateTime.tryParse(json['registration_closes_at'] as String) : null,
      maxSlots: (json['max_slots'] as num?)?.toInt(),
      filledSlots: (json['filled_slots'] as num?)?.toInt(),
      description: (json['description'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
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
    'stages': stages.map((e) => e.toJson()).toList(),
    'streamUrl': streamUrl,
    'is_registered': isRegistered,
    'registered_count': registeredCount,
    'slots_left': slotsLeft,
    'starts_at': startsAt?.toIso8601String(),
    'registration_opens_at': registrationOpensAt?.toIso8601String(),
    'registration_closes_at': registrationClosesAt?.toIso8601String(),
    'max_slots': maxSlots,
    'filled_slots': filledSlots,
  };

  /// Fallback effective stages generator if stages list from API is empty
  List<BracketStageModel> get effectiveStages {
    if (stages.isNotEmpty) return stages;

    // Build dynamic stages from tournament teams if API didn't supply 'stages'
    final allTeams = teams.isNotEmpty
        ? teams
        : List.generate(
            10,
            (i) => TeamModel(
              id: 'team_$i',
              name: 'Team ${String.fromCharCode(65 + i)}',
              logoUrl: '',
              score: (10 - i) * 12 + 5,
              status: i < 5 ? TeamStatus.qualified : TeamStatus.eliminated,
            ),
          );

    final round1Teams = allTeams.map((t) {
      final isElim = t.status == TeamStatus.eliminated || allTeams.indexOf(t) >= 5;
      return BracketTeamModel(
        id: t.id,
        name: t.name,
        logoUrl: t.logoUrl,
        points: t.score > 0 ? t.score : (10 - allTeams.indexOf(t)) * 10,
        kills: (allTeams.indexOf(t) + 1) * 3,
        rank: allTeams.indexOf(t) + 1,
        isEliminated: isElim,
        isQualified: !isElim,
      );
    }).toList();

    final semiTeams = round1Teams
        .where((t) => t.isQualified)
        .toList()
        .asMap()
        .entries
        .map((e) {
      final isElim = e.key >= 2;
      return BracketTeamModel(
        id: e.value.id,
        name: e.value.name,
        logoUrl: e.value.logoUrl,
        points: e.value.points + 25,
        kills: e.value.kills + 6,
        rank: e.key + 1,
        isEliminated: isElim,
        isQualified: !isElim,
      );
    }).toList();

    final finalTeams = semiTeams.where((t) => t.isQualified).toList().asMap().entries.map((e) {
      final isWin = e.key == 0;
      return BracketTeamModel(
        id: e.value.id,
        name: e.value.name,
        logoUrl: e.value.logoUrl,
        points: e.value.points + 40,
        kills: e.value.kills + 10,
        rank: e.key + 1,
        isEliminated: !isWin,
        isQualified: isWin,
        isWinner: isWin,
      );
    }).toList();

    return [
      BracketStageModel(
        stageId: 'stage_1',
        stageName: 'Round 1 (Qualifiers)',
        stageNumber: 1,
        isCompleted: status != TournamentStatus.upcoming,
        isCurrentStage: status == TournamentStatus.upcoming,
        teams: round1Teams,
      ),
      BracketStageModel(
        stageId: 'stage_2',
        stageName: 'Semi Finals (Top 5)',
        stageNumber: 2,
        isCompleted: status == TournamentStatus.completed,
        isCurrentStage: status == TournamentStatus.live,
        teams: semiTeams,
      ),
      BracketStageModel(
        stageId: 'stage_3',
        stageName: 'Grand Finals',
        stageNumber: 3,
        isCompleted: status == TournamentStatus.completed,
        isCurrentStage: false,
        teams: finalTeams,
      ),
    ];
  }
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
  final int matchNumber;
  final String map;
  final MatchStatus status;
  final DateTime startsAt;
  final DateTime? endedAt;
  final String? winnerTeamName;
  final String? topKillerName;
  final String? streamUrl;

  // Preserved for backward compatibility
  final TeamModel teamA;
  final TeamModel teamB;

  const MatchModel({
    required this.id,
    this.tournamentId = '',
    required this.round,
    this.matchNumber = 1,
    this.map = 'Bermuda',
    this.status = MatchStatus.upcoming,
    required this.startsAt,
    this.endedAt,
    this.winnerTeamName,
    this.topKillerName,
    this.streamUrl,
    this.teamA = const TeamModel(id: '', name: 'Team A', logoUrl: ''),
    this.teamB = const TeamModel(id: '', name: 'Team B', logoUrl: ''),
  });

  bool get isLive => status == MatchStatus.live;

  // Backward compatibility getters
  DateTime get matchTime => startsAt;
  String? get mapOrMode => map;

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String? ?? 'upcoming').toLowerCase();
    final parsedStatus = MatchStatus.values.firstWhere(
      (e) => e.name == rawStatus,
      orElse: () => MatchStatus.upcoming,
    );

    final rawStartsAt = json['starts_at'] ?? json['startsAt'] ?? json['match_time'] ?? json['matchTime'];
    final parsedStartsAt = DateTime.tryParse(rawStartsAt as String? ?? '') ?? DateTime.now();

    final rawEndedAt = json['ended_at'] ?? json['endedAt'];
    final parsedEndedAt = rawEndedAt != null ? DateTime.tryParse(rawEndedAt as String? ?? '') : null;

    final parsedMatchNum = (json['match_number'] ?? json['matchNumber'] as num?)?.toInt() ?? 1;
    final parsedMap = (json['map'] ?? json['map_or_mode'] ?? json['mapOrMode'] ?? 'Bermuda') as String;

    return MatchModel(
      id: (json['id'] ?? '') as String,
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
      round: (json['round'] ?? 'Round 1') as String,
      matchNumber: parsedMatchNum,
      map: parsedMap,
      status: parsedStatus,
      startsAt: parsedStartsAt,
      endedAt: parsedEndedAt,
      winnerTeamName: (json['winner_team_name'] ?? json['winnerTeamName']) as String?,
      topKillerName: (json['top_killer_name'] ?? json['topKillerName']) as String?,
      streamUrl: (json['stream_url'] ?? json['streamUrl']) as String?,
      teamA: json['teamA'] != null
          ? TeamModel.fromJson(json['teamA'] as Map<String, dynamic>)
          : const TeamModel(id: '', name: 'Team A', logoUrl: ''),
      teamB: json['teamB'] != null
          ? TeamModel.fromJson(json['teamB'] as Map<String, dynamic>)
          : const TeamModel(id: '', name: 'Team B', logoUrl: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tournament_id': tournamentId,
    'round': round,
    'match_number': matchNumber,
    'map': map,
    'status': status.name,
    'starts_at': startsAt.toIso8601String(),
    'ended_at': endedAt?.toIso8601String(),
    'winner_team_name': winnerTeamName,
    'top_killer_name': topKillerName,
    'stream_url': streamUrl,
    'teamA': teamA.toJson(),
    'teamB': teamB.toJson(),
    'mapOrMode': map,
    'matchTime': startsAt.toIso8601String(),
  };
}

/// ------------------------------------------------------------
/// BRACKET / ROADMAP MODELS
/// ------------------------------------------------------------

class BracketTeamModel {
  final String id;
  final String name;
  final String logoUrl;
  final int points;
  final int kills;
  final int rank;
  final bool isEliminated;
  final bool isQualified;
  final bool isWinner;

  const BracketTeamModel({
    required this.id,
    required this.name,
    this.logoUrl = '',
    this.points = 0,
    this.kills = 0,
    this.rank = 0,
    this.isEliminated = false,
    this.isQualified = false,
    this.isWinner = false,
  });

  factory BracketTeamModel.fromJson(Map<String, dynamic> json) => BracketTeamModel(
    id: (json['id'] ?? json['team_id'] ?? '') as String,
    name: (json['name'] ?? json['team_name'] ?? 'Team') as String,
    logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '') as String,
    points: (json['points'] ?? json['total_points'] as num?)?.toInt() ?? 0,
    kills: (json['kills'] as num?)?.toInt() ?? 0,
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    isEliminated: (json['is_eliminated'] ?? json['isEliminated'] as bool?) ?? false,
    isQualified: (json['is_qualified'] ?? json['isQualified'] as bool?) ?? false,
    isWinner: (json['is_winner'] ?? json['isWinner'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
    'points': points,
    'kills': kills,
    'rank': rank,
    'is_eliminated': isEliminated,
    'is_qualified': isQualified,
    'is_winner': isWinner,
  };
}

class BracketStageModel {
  final String stageId;
  final String stageName; // e.g. "Round 1 (Qualifiers)", "Semi Finals", "Finals"
  final int stageNumber;
  final bool isCurrentStage;
  final bool isCompleted;
  final List<BracketTeamModel> teams;

  const BracketStageModel({
    required this.stageId,
    required this.stageName,
    required this.stageNumber,
    this.isCurrentStage = false,
    this.isCompleted = false,
    this.teams = const [],
  });

  factory BracketStageModel.fromJson(Map<String, dynamic> json) {
    return BracketStageModel(
      stageId: (json['stage_id'] ?? json['id'] ?? '') as String,
      stageName: (json['stage_name'] ?? json['name'] ?? '') as String,
      stageNumber: (json['stage_number'] ?? json['number'] as num?)?.toInt() ?? 1,
      isCurrentStage: (json['is_current'] ?? json['isCurrentStage'] as bool?) ?? false,
      isCompleted: (json['is_completed'] ?? json['isCompleted'] as bool?) ?? false,
      teams: (json['teams'] as List<dynamic>?)
              ?.map((e) => BracketTeamModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'stage_id': stageId,
    'stage_name': stageName,
    'stage_number': stageNumber,
    'is_current': isCurrentStage,
    'is_completed': isCompleted,
    'teams': teams.map((e) => e.toJson()).toList(),
  };
}
