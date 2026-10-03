// ============================================================
// LEADERBOARD MODEL — Free Fire Tournament Standings
// ============================================================

enum LeaderboardEntryStatus { active, eliminated, qualified }

class LeaderboardEntry {
  final int rank;
  final int? prevRank;
  final String teamId;
  final String teamName;
  final String logoUrl;
  final int kills;
  final int placementPoints;
  final int totalPoints;
  final LeaderboardEntryStatus status;

  const LeaderboardEntry({
    required this.rank,
    this.prevRank,
    required this.teamId,
    required this.teamName,
    required this.logoUrl,
    required this.kills,
    required this.placementPoints,
    required this.totalPoints,
    required this.status,
  });

  /// Helper: Rank change relative to previous rank.
  /// Positive value means rank improved (e.g. prevRank 3 -> rank 1 => 3 - 1 = +2, ▲2).
  /// Negative value means rank dropped (e.g. prevRank 1 -> rank 2 => 1 - 2 = -1, ▼1).
  /// 0 means no change or no previous rank.
  int get rankChange {
    if (prevRank == null) return 0;
    return prevRank! - rank;
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'active').toLowerCase();
    final parsedStatus = switch (statusStr) {
      'eliminated' => LeaderboardEntryStatus.eliminated,
      'qualified' => LeaderboardEntryStatus.qualified,
      _ => LeaderboardEntryStatus.active,
    };

    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      prevRank: (json['prev_rank'] ?? json['prevRank'] as num?)?.toInt(),
      teamId: (json['team_id'] ?? json['registration_id'] ?? json['teamId'] ?? '') as String,
      teamName: (json['participant_name'] ?? json['team_name'] ?? json['teamName'] ?? 'Team') as String,
      logoUrl: (json['logo_url'] ?? json['logoUrl'] ?? '') as String,
      kills: (json['total_kills'] ?? json['kills'] ?? json['kill_points'] as num?)?.toInt() ?? 0,
      placementPoints: (json['placement_points'] ?? json['placementPoints'] as num?)?.toInt() ?? 0,
      totalPoints: (json['total_points'] ?? json['totalPoints'] as num?)?.toInt() ?? 0,
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'prev_rank': prevRank,
    'team_id': teamId,
    'team_name': teamName,
    'logo_url': logoUrl,
    'kills': kills,
    'placement_points': placementPoints,
    'total_points': totalPoints,
    'status': status.name,
  };
}

class LeaderboardResponse {
  final String tournamentId;
  final DateTime? updatedAt;
  final String round;
  final List<LeaderboardEntry> entries;

  const LeaderboardResponse({
    required this.tournamentId,
    this.updatedAt,
    required this.round,
    required this.entries,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>?;
    return LeaderboardResponse(
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      round: (json['round'] ?? '') as String,
      entries: rawEntries
              ?.map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'tournament_id': tournamentId,
    'updated_at': updatedAt?.toIso8601String(),
    'round': round,
    'entries': entries.map((e) => e.toJson()).toList(),
  };
}
