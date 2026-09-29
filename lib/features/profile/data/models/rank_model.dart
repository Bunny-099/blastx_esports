import 'package:flutter/material.dart';

/// Represents a specific rank tier (1 to 14) in the rank system.
class RankTier {
  final int number;
  final String name;
  final int minXP;
  final int? nextRankMinXP;
  final IconData icon;

  const RankTier({
    required this.number,
    required this.name,
    required this.minXP,
    this.nextRankMinXP,
    required this.icon,
  });

  bool get isMaxRank => nextRankMinXP == null;

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': name,
      'minXP': minXP,
      if (nextRankMinXP != null) 'nextRankMinXP': nextRankMinXP,
    };
  }

  factory RankTier.fromJson(Map<String, dynamic> json) {
    final rankNum = (json['number'] as num?)?.toInt() ?? 1;
    final name = json['name'] as String? ?? 'Rookie';
    final minXP = (json['minXP'] as num?)?.toInt() ?? 0;
    final nextMinXP = (json['nextRankMinXP'] as num?)?.toInt();
    return RankTier(
      number: rankNum,
      name: name,
      minXP: minXP,
      nextRankMinXP: nextMinXP,
      icon: _getIconForRank(rankNum),
    );
  }

  static IconData _getIconForRank(int rankNumber) {
    switch (rankNumber) {
      case 1:
        return Icons.shield_outlined;
      case 2:
        return Icons.military_tech_outlined;
      case 3:
        return Icons.sports_kabaddi;
      case 4:
        return Icons.shield_rounded;
      case 5:
        return Icons.security;
      case 6:
        return Icons.workspace_premium;
      case 7:
        return Icons.star_half_rounded;
      case 8:
        return Icons.emoji_events_outlined;
      case 9:
        return Icons.star_rounded;
      case 10:
        return Icons.stars_rounded;
      case 11:
        return Icons.military_tech_rounded;
      case 12:
        return Icons.diamond_outlined;
      case 13:
        return Icons.whatshot_rounded;
      case 14:
      default:
        return Icons.local_fire_department_rounded;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankTier &&
          runtimeType == other.runtimeType &&
          number == other.number &&
          name == other.name &&
          minXP == other.minXP &&
          nextRankMinXP == other.nextRankMinXP;

  @override
  int get hashCode =>
      number.hashCode ^ name.hashCode ^ minXP.hashCode ^ nextRankMinXP.hashCode;

  @override
  String toString() => 'RankTier(Rank $number: $name, minXP: $minXP)';
}

/// Contains complete XP progress metrics calculated from total XP.
class RankProgressInfo {
  final RankTier currentRank;
  final RankTier? nextRank;
  final int totalXP;
  final int xpInCurrentTier;
  final int xpRequiredForTier;
  final int xpRemaining;
  final double progress;
  final bool isMaxRank;

  const RankProgressInfo({
    required this.currentRank,
    this.nextRank,
    required this.totalXP,
    required this.xpInCurrentTier,
    required this.xpRequiredForTier,
    required this.xpRemaining,
    required this.progress,
    required this.isMaxRank,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalXP': totalXP,
      'currentRank': currentRank.toJson(),
      if (nextRank != null) 'nextRank': nextRank!.toJson(),
      'xpRemaining': xpRemaining,
      'progress': progress,
      'isMaxRank': isMaxRank,
    };
  }
}

/// Represents the result of claiming challenge XP and updating rank.
class RankChangeResult {
  final int claimedXP;
  final int totalXP;
  final RankTier previousRank;
  final RankTier currentRank;
  final bool rankChanged;

  const RankChangeResult({
    required this.claimedXP,
    required this.totalXP,
    required this.previousRank,
    required this.currentRank,
    required this.rankChanged,
  });
}
