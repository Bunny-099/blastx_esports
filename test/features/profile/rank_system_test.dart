import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/profile/domain/rank_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Player Ranking & XP Progression System Tests', () {
    test('Verify Exact Rank Threshold Boundaries', () {
      expect(RankSystem.getRankFromXP(0).name, equals('Rookie'));
      expect(RankSystem.getRankFromXP(0).number, equals(1));

      expect(RankSystem.getRankFromXP(499).name, equals('Rookie'));
      expect(RankSystem.getRankFromXP(499).number, equals(1));

      expect(RankSystem.getRankFromXP(500).name, equals('Recruit'));
      expect(RankSystem.getRankFromXP(500).number, equals(2));

      expect(RankSystem.getRankFromXP(1499).name, equals('Recruit'));
      expect(RankSystem.getRankFromXP(1499).number, equals(2));

      expect(RankSystem.getRankFromXP(1500).name, equals('Fighter'));
      expect(RankSystem.getRankFromXP(1500).number, equals(3));

      expect(RankSystem.getRankFromXP(3000).name, equals('Warrior'));
      expect(RankSystem.getRankFromXP(3000).number, equals(4));

      expect(RankSystem.getRankFromXP(7000).name, equals('Veteran'));
      expect(RankSystem.getRankFromXP(7000).number, equals(5));

      expect(RankSystem.getRankFromXP(9000).name, equals('Elite'));
      expect(RankSystem.getRankFromXP(9000).number, equals(6));

      expect(RankSystem.getRankFromXP(50000).name, equals('Legend'));
      expect(RankSystem.getRankFromXP(50000).number, equals(11));

      expect(RankSystem.getRankFromXP(110000).name, equals('Apex'));
      expect(RankSystem.getRankFromXP(110000).number, equals(14));

      expect(RankSystem.getRankFromXP(200000).name, equals('Apex'));
      expect(RankSystem.getRankFromXP(200000).number, equals(14));
    });

    test('Verify XP Remaining Calculations', () {
      // 7,000 XP is Veteran (5,500 min). Next rank is Elite (9,000 min). Remaining: 2,000 XP
      expect(RankSystem.getXPRemaining(7000), equals(2000));

      // 0 XP -> Recruit requires 500 XP
      expect(RankSystem.getXPRemaining(0), equals(500));

      // Apex (110,000+ XP) has no next rank -> 0 XP remaining
      expect(RankSystem.getXPRemaining(110000), equals(0));
      expect(RankSystem.getXPRemaining(150000), equals(0));
    });

    test('Verify Progress Percentage Calculations', () {
      // 7,000 XP: Veteran (5,500 to 9,000 -> span 3,500). Earned in tier = 1,500.
      // 1500 / 3500 = ~0.42857
      final progress7k = RankSystem.getXPProgress(7000);
      expect(progress7k, closeTo(0.42857, 0.001));

      // At exact rank threshold boundary (e.g. 500 XP Recruit min 500 to 1500) -> 0.0
      expect(RankSystem.getXPProgress(500), equals(0.0));

      // At Apex (110,000+ XP) -> 1.0 (100%)
      expect(RankSystem.getXPProgress(110000), equals(1.0));
      expect(RankSystem.getXPProgress(150000), equals(1.0));
    });

    test('Verify Max Rank Behavior (Rank 14 - Apex)', () {
      final apexRank = RankSystem.getRankFromXP(110000);
      expect(apexRank.isMaxRank, isTrue);

      final nextRank = RankSystem.getNextRank(110000);
      expect(nextRank, isNull);

      final progressInfo = RankSystem.getRankProgress(110000);
      expect(progressInfo.isMaxRank, isTrue);
      expect(progressInfo.nextRank, isNull);
      expect(progressInfo.xpRemaining, equals(0));
      expect(progressInfo.progress, equals(1.0));
    });

    test('Verify Invalid/Negative XP Clamping', () {
      expect(RankSystem.sanitizeXP(-500), equals(0));
      expect(RankSystem.getRankFromXP(-1000).name, equals('Rookie'));
      expect(RankSystem.getXPRemaining(-100), equals(500));
      expect(RankSystem.getXPProgress(-50), equals(0.0));
    });

    test('Verify Rank-Up Detection with calculateXPClaim', () {
      // 7,000 XP (Veteran) + 500 XP -> 7,500 XP (Veteran) -> No Rank Change
      final claim1 = RankSystem.calculateXPClaim(currentXP: 7000, claimedXP: 500);
      expect(claim1.rankChanged, isFalse);
      expect(claim1.currentRank.name, equals('Veteran'));
      expect(claim1.totalXP, equals(7500));

      // 7,000 XP (Veteran) + 2,000 XP -> 9,000 XP (Elite) -> RANK CHANGED!
      final claim2 = RankSystem.calculateXPClaim(currentXP: 7000, claimedXP: 2000);
      expect(claim2.rankChanged, isTrue);
      expect(claim2.previousRank.name, equals('Veteran'));
      expect(claim2.currentRank.name, equals('Elite'));
      expect(claim2.totalXP, equals(9000));
    });
  });
}
