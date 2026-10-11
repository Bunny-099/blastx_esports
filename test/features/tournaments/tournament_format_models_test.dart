import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/tournaments/data/models/tournament_format_models.dart';

void main() {
  group('Tournament Format Engine Data Models Test', () {
    test('TournamentFormat and TeamMode parsing', () {
      expect(TournamentFormat.fromJson('CLASH_SQUAD'), TournamentFormat.CLASH_SQUAD);
      expect(TournamentFormat.fromJson('BATTLE_ROYALE'), TournamentFormat.BATTLE_ROYALE);

      expect(TeamMode.fromJson('SOLO'), TeamMode.SOLO);
      expect(TeamMode.fromJson('DUO'), TeamMode.DUO);
      expect(TeamMode.fromJson('SQUAD'), TeamMode.SQUAD);

      expect(TeamMode.SOLO.requiredPlayersCount, 1);
      expect(TeamMode.DUO.requiredPlayersCount, 2);
      expect(TeamMode.SQUAD.requiredPlayersCount, 4);
    });

    test('TournamentStageModel JSON parsing', () {
      final json = {
        'stage_number': 1,
        'stage_name': 'Round 1 (Qualifiers)',
        'status': 'LIVE',
        'lobby_count': 8,
        'units_per_lobby': 12,
        'qualifiers_per_lobby': 3,
        'is_grand_final': false,
        'groups': [
          {
            'id': 'grp_stage1_a',
            'group_number': 1,
            'group_name': 'Group A',
            'standings': [
              {
                'rank': 1,
                'unit_id': 'team_alpha',
                'unit_name': 'Alpha Esports',
                'slot_number': 1,
                'matches_played': 2,
                'kills': 18,
                'placement_points': 24,
                'total_points': 42,
                'status': 'QUALIFIED'
              }
            ]
          }
        ]
      };

      final stage = TournamentStageModel.fromJson(json);

      expect(stage.stageNumber, 1);
      expect(stage.stageName, 'Round 1 (Qualifiers)');
      expect(stage.status, StageStatus.LIVE);
      expect(stage.lobbyCount, 8);
      expect(stage.unitsPerLobby, 12);
      expect(stage.qualifiersPerLobby, 3);
      expect(stage.isGrandFinal, isFalse);
      expect(stage.groups.length, 1);

      final grp = stage.groups.first;
      expect(grp.groupName, 'Group A');
      expect(grp.standings.length, 1);

      final std = grp.standings.first;
      expect(std.unitName, 'Alpha Esports');
      expect(std.kills, 18);
      expect(std.totalPoints, 42);
      expect(std.status, QualificationStatus.QUALIFIED);
    });

    test('MyActiveAssignmentModel JSON parsing', () {
      final json = {
        'current_stage_number': 1,
        'stage_name': 'Round 1 (Qualifiers)',
        'group_id': 'grp_stage1_b',
        'group_name': 'Group B',
        'assigned_slot': 7,
        'room_credentials_released': true,
        'room_id': '8934102',
        'room_password': 'BLAST7X',
        'room_released_at': '2026-10-11T12:00:00.000Z',
        'my_status': 'QUALIFIED'
      };

      final assignment = MyActiveAssignmentModel.fromJson(json);

      expect(assignment.currentStageNumber, 1);
      expect(assignment.stageName, 'Round 1 (Qualifiers)');
      expect(assignment.groupId, 'grp_stage1_b');
      expect(assignment.groupName, 'Group B');
      expect(assignment.assignedSlot, 7);
      expect(assignment.roomCredentialsReleased, isTrue);
      expect(assignment.roomId, '8934102');
      expect(assignment.roomPassword, 'BLAST7X');
      expect(assignment.myStatus, QualificationStatus.QUALIFIED);
    });

    test('ClashSquadBracketModel JSON parsing', () {
      final json = {
        'tournament_id': 'cs_tourney_101',
        'rounds': [
          {
            'round_index': 0,
            'round_name': 'Semifinals',
            'matches': [
              {
                'match_id': 'm1',
                'round_name': 'Semifinals',
                'match_number': 1,
                'team_a_name': 'Team Alpha',
                'score_a': 4,
                'team_b_name': 'Team Beta',
                'score_b': 2,
                'winner_id': 'team_alpha_id',
                'is_completed': true
              }
            ]
          }
        ]
      };

      final bracket = ClashSquadBracketModel.fromJson(json);

      expect(bracket.tournamentId, 'cs_tourney_101');
      expect(bracket.rounds.length, 1);

      final round = bracket.rounds.first;
      expect(round.roundName, 'Semifinals');
      expect(round.matches.length, 1);

      final match = round.matches.first;
      expect(match.teamAName, 'Team Alpha');
      expect(match.scoreA, 4);
      expect(match.scoreB, 2);
      expect(match.isCompleted, isTrue);
    });
  });
}
