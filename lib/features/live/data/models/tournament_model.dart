/// ============================================================
/// TOURNAMENT MODEL
/// ============================================================
/// Data structure for Live Tournaments screen.
/// Contains:
///  - TournamentModel : top level tournament info (shown on cards)
///  - TeamModel       : team info (shown inside detail screen)
///  - MatchModel      : specific match info (shown inside detail screen)
/// ============================================================

enum TournamentStatus { live, upcoming, completed }

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

  /// Accent color hex used for the card's neon border (e.g "#9B5CFF").
  /// Lets each game/tournament have a slightly different glow on its card.
  final String accentColorHex;

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
  });

  bool get isLive => status == TournamentStatus.live;

  /// Formatted viewer count e.g 1200 -> "1.2K", 15000 -> "15K"
  String get formattedViewers {
    if (viewersCount >= 1000000) {
      return '${(viewersCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewersCount >= 1000) {
      return '${(viewersCount / 1000).toStringAsFixed(1)}K';
    }
    return viewersCount.toString();
  }

  /// Formatted prize pool e.g 500000 -> "₹5,00,000" (kept simple here)
  String get formattedPrizePool {
    final str = prizePool.toInt().toString();
    return '$currency$str';
  }

  factory TournamentModel.fromJson(Map<String, dynamic> json) {
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
      teams: (json['teams'] as List<dynamic>?)
          ?.map((e) => TeamModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
      matches: (json['matches'] as List<dynamic>?)
          ?.map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  TournamentModel copyWith({
    String? id,
    String? name,
    String? game,
    String? bannerImageUrl,
    String? gameLogoUrl,
    double? prizePool,
    String? currency,
    int? viewersCount,
    TournamentStatus? status,
    DateTime? startTime,
    String? organizer,
    String? accentColorHex,
    List<TeamModel>? teams,
    List<MatchModel>? matches,
  }) {
    return TournamentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      game: game ?? this.game,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      gameLogoUrl: gameLogoUrl ?? this.gameLogoUrl,
      prizePool: prizePool ?? this.prizePool,
      currency: currency ?? this.currency,
      viewersCount: viewersCount ?? this.viewersCount,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      organizer: organizer ?? this.organizer,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      teams: teams ?? this.teams,
      matches: matches ?? this.matches,
    );
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

  const TeamModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.score = 0,
    this.status = TeamStatus.playing,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logoUrl'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      status: TeamStatus.values.firstWhere(
            (e) => e.name == (json['status'] as String? ?? 'playing'),
        orElse: () => TeamStatus.playing,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'score': score,
      'status': status.name,
    };
  }
}

/// ------------------------------------------------------------
/// MATCH MODEL
/// ------------------------------------------------------------
enum MatchStatus { live, upcoming, completed }

class MatchModel {
  final String id;
  final String tournamentId;
  final String round; // e.g "Quarter Final", "Group Stage - Day 2"
  final TeamModel teamA;
  final TeamModel teamB;
  final DateTime matchTime;
  final MatchStatus status;
  final String? mapOrMode; // e.g "Erangel", "Bo3"

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

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
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
  }

  Map<String, dynamic> toJson() {
    return {
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
}