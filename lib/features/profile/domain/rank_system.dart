import 'package:flutter/material.dart';
import '../data/models/rank_model.dart';

/// Centralized, data-driven Rank System and XP Threshold utility.
class RankSystem {
  RankSystem._();

  /// All 14 data-driven Rank Tiers configured in ascending XP order.
  static const List<RankTier> ranks = [
    RankTier(
      number: 1,
      name: 'Rookie',
      minXP: 0,
      nextRankMinXP: 500,
      icon: Icons.shield_outlined,
    ),
    RankTier(
      number: 2,
      name: 'Recruit',
      minXP: 500,
      nextRankMinXP: 1500,
      icon: Icons.military_tech_outlined,
    ),
    RankTier(
      number: 3,
      name: 'Fighter',
      minXP: 1500,
      nextRankMinXP: 3000,
      icon: Icons.sports_kabaddi,
    ),
    RankTier(
      number: 4,
      name: 'Warrior',
      minXP: 3000,
      nextRankMinXP: 5500,
      icon: Icons.shield_rounded,
    ),
    RankTier(
      number: 5,
      name: 'Veteran',
      minXP: 5500,
      nextRankMinXP: 9000,
      icon: Icons.security,
    ),
    RankTier(
      number: 6,
      name: 'Elite',
      minXP: 9000,
      nextRankMinXP: 14000,
      icon: Icons.workspace_premium,
    ),
    RankTier(
      number: 7,
      name: 'Specialist',
      minXP: 14000,
      nextRankMinXP: 20000,
      icon: Icons.star_half_rounded,
    ),
    RankTier(
      number: 8,
      name: 'Champion',
      minXP: 20000,
      nextRankMinXP: 28000,
      icon: Icons.emoji_events_outlined,
    ),
    RankTier(
      number: 9,
      name: 'Master',
      minXP: 28000,
      nextRankMinXP: 38000,
      icon: Icons.star_rounded,
    ),
    RankTier(
      number: 10,
      name: 'Grandmaster',
      minXP: 38000,
      nextRankMinXP: 50000,
      icon: Icons.stars_rounded,
    ),
    RankTier(
      number: 11,
      name: 'Legend',
      minXP: 50000,
      nextRankMinXP: 65000,
      icon: Icons.military_tech_rounded,
    ),
    RankTier(
      number: 12,
      name: 'Mythic',
      minXP: 65000,
      nextRankMinXP: 85000,
      icon: Icons.diamond_outlined,
    ),
    RankTier(
      number: 13,
      name: 'Immortal',
      minXP: 85000,
      nextRankMinXP: 110000,
      icon: Icons.whatshot_rounded,
    ),
    RankTier(
      number: 14,
      name: 'Apex',
      minXP: 110000,
      nextRankMinXP: null,
      icon: Icons.local_fire_department_rounded,
    ),
  ];

  /// Safely sanitizes negative or invalid XP to 0.
  static int sanitizeXP(int totalXP) {
    if (totalXP < 0) return 0;
    return totalXP;
  }

  /// Returns the player's current [RankTier] based on total XP.
  static RankTier getRankFromXP(int totalXP) {
    final xp = sanitizeXP(totalXP);
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (xp >= ranks[i].minXP) {
        return ranks[i];
      }
    }
    return ranks.first;
  }

  /// Alias for [getRankFromXP].
  static RankTier getCurrentRank(int totalXP) => getRankFromXP(totalXP);

  /// Returns the next [RankTier] above the current XP, or `null` if at Max Rank (Apex).
  static RankTier? getNextRank(int totalXP) {
    final current = getRankFromXP(totalXP);
    if (current.isMaxRank || current.number >= ranks.length) {
      return null;
    }
    return ranks[current.number]; // ranks is 0-indexed, so ranks[current.number] is rank number + 1
  }

  /// Returns the minimum XP required to reach the next rank.
  /// If already at max rank, returns the current rank's minXP.
  static int getXPForNextRank(int totalXP) {
    final next = getNextRank(totalXP);
    if (next == null) {
      return getRankFromXP(totalXP).minXP;
    }
    return next.minXP;
  }

  /// Returns the remaining XP required to reach the next rank.
  /// Returns 0 if max rank.
  static int getXPRemaining(int totalXP) {
    final xp = sanitizeXP(totalXP);
    final next = getNextRank(xp);
    if (next == null) return 0;
    final remaining = next.minXP - xp;
    return remaining > 0 ? remaining : 0;
  }

  /// Calculates the progression percentage (0.0 to 1.0) toward the next rank.
  /// For Max Rank (Apex), returns 1.0.
  static double getXPProgress(int totalXP) {
    final xp = sanitizeXP(totalXP);
    final current = getRankFromXP(xp);
    if (current.isMaxRank || current.nextRankMinXP == null) {
      return 1.0;
    }

    final tierMin = current.minXP;
    final tierMax = current.nextRankMinXP!;
    final span = tierMax - tierMin;
    if (span <= 0) return 1.0;

    final earnedInTier = xp - tierMin;
    final progress = earnedInTier / span;
    return progress.clamp(0.0, 1.0);
  }

  /// Returns a complete [RankProgressInfo] summary object for UI presentation.
  static RankProgressInfo getRankProgress(int totalXP) {
    final xp = sanitizeXP(totalXP);
    final current = getRankFromXP(xp);
    final next = getNextRank(xp);
    final isMax = current.isMaxRank || next == null;

    final xpInCurrentTier = xp - current.minXP;
    final xpRequiredForTier = isMax ? 0 : (next.minXP - current.minXP);
    final xpRemaining = getXPRemaining(xp);
    final progress = getXPProgress(xp);

    return RankProgressInfo(
      currentRank: current,
      nextRank: next,
      totalXP: xp,
      xpInCurrentTier: xpInCurrentTier,
      xpRequiredForTier: xpRequiredForTier,
      xpRemaining: xpRemaining,
      progress: progress,
      isMaxRank: isMax,
    );
  }

  /// Evaluates whether adding [claimedXP] to [currentXP] results in a rank promotion.
  static RankChangeResult calculateXPClaim({
    required int currentXP,
    required int claimedXP,
  }) {
    final safeCurrent = sanitizeXP(currentXP);
    final safeClaimed = claimedXP < 0 ? 0 : claimedXP;
    final oldRank = getRankFromXP(safeCurrent);
    final newTotalXP = safeCurrent + safeClaimed;
    final newRank = getRankFromXP(newTotalXP);
    final rankChanged = newRank.number > oldRank.number;

    return RankChangeResult(
      claimedXP: safeClaimed,
      totalXP: newTotalXP,
      previousRank: oldRank,
      currentRank: newRank,
      rankChanged: rankChanged,
    );
  }
}
