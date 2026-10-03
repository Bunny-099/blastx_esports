import 'package:blastix_esports/features/live/data/models/leaderboard_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tournament Segregation & Title Stripping Tests', () {
    test('Free Fire Live tournament identified correctly by [FF Live] prefix', () {
      final json = {
        'id': 'ff_001',
        'title': '[FF Live] FFWS City Knockout',
        'game_slug': 'free_fire',
        'status': 'UPCOMING',
        'description': 'Official Free Fire live qualifiers.\n\n[SECTION:FREEFIRE_LIVE]',
      };

      final tournament = TournamentModel.fromJson(json);

      expect(tournament.isFreeFireLiveSection, isTrue);
      expect(tournament.isBlastXSection, isFalse);
      expect(tournament.displayTitle, equals('FFWS City Knockout'));
    });

    test('BlastX E-Sports tournament identified correctly by [BlastX] prefix', () {
      final json = {
        'id': 'bx_001',
        'title': '[BlastX] Clan Championship Series',
        'game_slug': 'free_fire',
        'status': 'UPCOMING',
        'description': 'BlastX internal clan battles.\n\n[SECTION:BLASTX]',
      };

      final tournament = TournamentModel.fromJson(json);

      expect(tournament.isBlastXSection, isTrue);
      expect(tournament.isFreeFireLiveSection, isFalse);
      expect(tournament.displayTitle, equals('Clan Championship Series'));
    });

    test('Free Fire tournament without prefix identified as Free Fire Live section', () {
      final json = {
        'id': 'ff_002',
        'title': 'Bermuda Open Championship',
        'game': 'Free Fire',
        'status': 'LIVE',
      };

      final tournament = TournamentModel.fromJson(json);

      expect(tournament.isFreeFireLiveSection, isTrue);
      expect(tournament.isBlastXSection, isFalse);
      expect(tournament.displayTitle, equals('Bermuda Open Championship'));
    });

    test('Tournament displayTitle strips prefixes properly', () {
      final t1 = TournamentModel.fromJson({
        'id': '1',
        'title': '[FF Live] Season 5 Finals',
      });
      final t2 = TournamentModel.fromJson({
        'id': '2',
        'title': '[BlastX] Masters Pro League',
      });
      final t3 = TournamentModel.fromJson({
        'id': '3',
        'title': 'Regular Tournament Title',
      });

      expect(t1.displayTitle, equals('Season 5 Finals'));
      expect(t2.displayTitle, equals('Masters Pro League'));
      expect(t3.displayTitle, equals('Regular Tournament Title'));
    });
  });

  group('Backend Leaderboard Response Parsing Tests', () {
    test('LeaderboardEntry parses sample backend response with participant_name and total_kills', () {
      final json = {
        'rank': 1,
        'registration_id': 'reg_team_1',
        'participant_name': 'Team Phoenix',
        'team_name': 'Phoenix',
        'team_tag': 'PHX',
        'total_points': 26,
        'placement_points': 12,
        'kill_points': 14,
        'total_kills': 14,
        'booyahs': 1,
      };

      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.rank, equals(1));
      expect(entry.teamId, equals('reg_team_1'));
      expect(entry.teamName, equals('Team Phoenix'));
      expect(entry.kills, equals(14));
      expect(entry.placementPoints, equals(12));
      expect(entry.totalPoints, equals(26));
    });
  });
}
