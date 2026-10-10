import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/live/data/models/tournament_matches_model.dart';
import 'package:blastix_esports/features/live/data/models/leaderboard_model.dart';

void main() {
  group('BLASTiX Tournament Engine & Enums Test', () {
    test('TournamentEngineStatus serialization & rawValue check', () {
      expect(TournamentEngineStatus.registrationOpen.rawValue, 'REGISTRATION_OPEN');
      expect(TournamentEngineStatus.live.rawValue, 'LIVE');
      expect(TournamentEngineStatus.completed.rawValue, 'COMPLETED');
    });

    test('RoundType display names & rawValues', () {
      expect(RoundType.round1.rawValue, 'ROUND_1');
      expect(RoundType.round2.rawValue, 'ROUND_2');
      expect(RoundType.round3.rawValue, 'ROUND_3');
      expect(RoundType.grandFinal.rawValue, 'GRAND_FINAL');

      expect(RoundType.round1.displayName, 'Round 1 (Qualifiers)');
      expect(RoundType.grandFinal.displayName, 'Grand Final');
    });

    test('QualificationStatus badge labels', () {
      expect(QualificationStatus.qualifiedRound2.badgeLabel, '✅ QUALIFIED FOR ROUND 2');
      expect(QualificationStatus.qualifiedRound3.badgeLabel, '⚡ ADVANCED TO ROUND 3');
      expect(QualificationStatus.qualifiedGrandFinal.badgeLabel, '🏆 QUALIFIED FOR GRAND FINAL');
      expect(QualificationStatus.eliminated.badgeLabel, '❌ ELIMINATED');
    });

    test('WildCardWindowModel JSON parsing & slot tracker', () {
      final json = {
        'status': 'OPEN',
        'claimed_slots': 3,
        'max_slots': 8,
        'banner_text': '🔥 Wild Card Open: 8 Exclusive Slots for Direct Round 3 Entry!',
      };

      final model = WildCardWindowModel.fromJson(json);

      expect(model.status, WildCardStatus.open);
      expect(model.claimedSlots, 3);
      expect(model.maxSlots, 8);
      expect(model.isOpen, isTrue);
      expect(model.isFull, isFalse);
    });

    test('UserMatchContext Round 2 Dual Exit Direct Finalist JSON parsing', () {
      final json = {
        'team_id': 'team_blx_101',
        'team_name': 'TOTAL GAMING',
        'round_id': 'round_2',
        'round_name': 'Round 2 - Semi Finals',
        'round_type': 'ROUND_2',
        'group_id': 'group_1',
        'group_name': 'Group A',
        'status': 'qualified',
        'qualification_status': 'QUALIFIED_GRAND_FINAL',
        'is_direct_finalist': true,
        'message_banner': 'Congratulations! You secured a direct spot in the Grand Final.',
        'room_id': '8492041',
        'room_password': 'FF2026',
        'is_published': true,
      };

      final ctx = UserMatchContext.fromJson(json);

      expect(ctx.teamId, 'team_blx_101');
      expect(ctx.roundType, RoundType.round2);
      expect(ctx.groupName, 'Group A');
      expect(ctx.qualificationStatus, QualificationStatus.qualifiedGrandFinal);
      expect(ctx.isDirectFinalist, isTrue);
      expect(ctx.isQualified, isTrue);
      expect(ctx.isEliminated, isFalse);
      expect(ctx.hasCredentials, isTrue);
      expect(ctx.roomId, '8492041');
      expect(ctx.password, 'FF2026');
    });

    test('LeaderboardResponse tie breaker pending parsing', () {
      final json = {
        'tournament_id': 'tourn_ff_2049',
        'round': 'Round 1',
        'round_type': 'ROUND_1',
        'round_status': 'TIE_BREAKER_PENDING',
        'is_tie_breaker_pending': true,
        'entries': [
          {
            'rank': 1,
            'team_id': 't1',
            'participant_name': 'GODLIKE',
            'kills': 12,
            'total_points': 24,
            'qualification_status': 'QUALIFIED_ROUND_2',
          }
        ],
      };

      final res = LeaderboardResponse.fromJson(json);

      expect(res.isTieBreakerPending, isTrue);
      expect(res.entries.length, 1);
      expect(res.entries.first.qualificationStatus, QualificationStatus.qualifiedRound2);
    });
  });
}
