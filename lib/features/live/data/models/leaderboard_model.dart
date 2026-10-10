import 'tournament_matches_model.dart';

// ============================================================
// LEADERBOARD MODEL — Free Fire Tournament Standings
// ============================================================

enum LeaderboardEntryStatus {
  active,
  eliminated,
  qualified,
  qualifiedRound2,
  qualifiedRound3,
  qualifiedGrandFinal,
  directFinalist,
}

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
  final QualificationStatus qualificationStatus;
  final bool isDirectFinalist; // Round 2 Top 2 Teams
  final String? customNote;

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
    this.qualificationStatus = QualificationStatus.waitingResult,
    this.isDirectFinalist = false,
    this.customNote,
  });

  /// Helper: Rank change relative to previous rank.
  int get rankChange {
    if (prevRank == null) return 0;
    return prevRank! - rank;
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'active').toLowerCase();
    final qualStr = (json['qualification_status'] ?? json['qualificationStatus'] ?? '')
        .toString()
        .toUpperCase();

    QualificationStatus parsedQual = QualificationStatus.waitingResult;
    if (qualStr == 'QUALIFIED_ROUND_2') {
      parsedQual = QualificationStatus.qualifiedRound2;
    } else if (qualStr == 'QUALIFIED_ROUND_3') {
      parsedQual = QualificationStatus.qualifiedRound3;
    } else if (qualStr == 'QUALIFIED_GRAND_FINAL') {
      parsedQual = QualificationStatus.qualifiedGrandFinal;
    } else if (qualStr == 'ELIMINATED') {
      parsedQual = QualificationStatus.eliminated;
    }

    LeaderboardEntryStatus parsedStatus = LeaderboardEntryStatus.active;
    if (parsedQual == QualificationStatus.qualifiedRound2) {
      parsedStatus = LeaderboardEntryStatus.qualifiedRound2;
    } else if (parsedQual == QualificationStatus.qualifiedRound3) {
      parsedStatus = LeaderboardEntryStatus.qualifiedRound3;
    } else if (parsedQual == QualificationStatus.qualifiedGrandFinal) {
      parsedStatus = LeaderboardEntryStatus.qualifiedGrandFinal;
    } else if (parsedQual == QualificationStatus.eliminated || statusStr == 'eliminated') {
      parsedStatus = LeaderboardEntryStatus.eliminated;
    } else if (statusStr == 'qualified') {
      parsedStatus = LeaderboardEntryStatus.qualified;
    }

    final isDirect = (json['is_direct_finalist'] ?? json['isDirectFinalist'] ?? false) as bool;
    if (isDirect) {
      parsedStatus = LeaderboardEntryStatus.directFinalist;
    }

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
      qualificationStatus: parsedQual,
      isDirectFinalist: isDirect,
      customNote: json['custom_note']?.toString(),
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
        'qualification_status': qualificationStatus.name,
        'is_direct_finalist': isDirectFinalist,
        'custom_note': customNote,
      };
}

class LeaderboardResponse {
  final String tournamentId;
  final DateTime? updatedAt;
  final String round;
  final RoundType roundType;
  final RoundStatus roundStatus;
  final bool isTieBreakerPending;
  final List<LeaderboardEntry> entries;

  const LeaderboardResponse({
    required this.tournamentId,
    this.updatedAt,
    required this.round,
    this.roundType = RoundType.round1,
    this.roundStatus = RoundStatus.scheduled,
    this.isTieBreakerPending = false,
    required this.entries,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>?;

    final rawRoundType = (json['round_type'] ?? json['roundType'] ?? '').toString().toUpperCase();
    final parsedRoundType = switch (rawRoundType) {
      'ROUND_2' => RoundType.round2,
      'ROUND_3' => RoundType.round3,
      'GRAND_FINAL' => RoundType.grandFinal,
      _ => RoundType.round1,
    };

    final rawStatus = (json['round_status'] ?? json['status'] ?? '').toString().toUpperCase();
    final isTiePending = (json['is_tie_breaker_pending'] ?? json['isTieBreakerPending'] ?? false) as bool ||
        rawStatus == 'TIE_BREAKER_PENDING';

    final parsedStatus = switch (rawStatus) {
      'LIVE' => RoundStatus.live,
      'TIE_BREAKER_PENDING' => RoundStatus.tieBreakerPending,
      'COMPLETED' => RoundStatus.completed,
      _ => RoundStatus.scheduled,
    };

    return LeaderboardResponse(
      tournamentId: (json['tournament_id'] ?? json['tournamentId'] ?? '') as String,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      round: (json['round'] ?? '') as String,
      roundType: parsedRoundType,
      roundStatus: parsedStatus,
      isTieBreakerPending: isTiePending,
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
        'round_type': roundType.rawValue,
        'round_status': roundStatus.name,
        'is_tie_breaker_pending': isTieBreakerPending,
        'entries': entries.map((e) => e.toJson()).toList(),
      };
}
