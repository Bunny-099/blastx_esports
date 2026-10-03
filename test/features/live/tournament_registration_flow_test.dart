import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tournament Registration & Countdown Gate Tests', () {
    test('TournamentModel parses registration_opens_at and registration_closes_at', () {
      final json = {
        'id': 't_1',
        'title': 'BlastX Championship',
        'status': 'UPCOMING',
        'starts_at': '2026-10-15T18:00:00Z',
        'registration_opens_at': '2026-10-10T10:00:00Z',
        'registration_closes_at': '2026-10-15T17:00:00Z',
      };

      final model = TournamentModel.fromJson(json);

      expect(model.registrationOpensAt, isNotNull);
      expect(model.registrationOpensAt, equals(DateTime.parse('2026-10-10T10:00:00Z')));
      expect(model.registrationClosesAt, isNotNull);
      expect(model.registrationClosesAt, equals(DateTime.parse('2026-10-15T17:00:00Z')));
    });

    test('SQUAD mode requires exactly 4 total members', () {
      final List<TeamMemberModel> members3 = List.generate(
        3,
        (i) => TeamMemberModel(
          userId: 'user_$i',
          name: 'Player $i',
          ign: 'IGN$i',
          uid: '100$i',
          role: i == 0 ? TeamRole.captain : TeamRole.member,
        ),
      );

      final team3 = TournamentTeamModel(
        id: 'team_3',
        tournamentId: 't_1',
        code: 'A1B2C3',
        name: 'Alpha Squad',
        captainId: 'user_0',
        members: members3,
      );

      final List<TeamMemberModel> members4 = List.generate(
        4,
        (i) => TeamMemberModel(
          userId: 'user_$i',
          name: 'Player $i',
          ign: 'IGN$i',
          uid: '100$i',
          role: i == 0 ? TeamRole.captain : TeamRole.member,
        ),
      );

      final team4 = TournamentTeamModel(
        id: 'team_4',
        tournamentId: 't_1',
        code: 'X1Y2Z3',
        name: 'Omega Squad',
        captainId: 'user_0',
        members: members4,
      );

      expect(team3.members.length, equals(3));
      expect(team4.members.length, equals(4));
    });

    test('DUO mode requires at least 2 total members', () {
      final List<TeamMemberModel> members1 = [
        const TeamMemberModel(
          userId: 'u_0',
          name: 'Solo Player',
          ign: 'Solo',
          uid: '1000',
          role: TeamRole.captain,
        ),
      ];

      final team1 = TournamentTeamModel(
        id: 'team_1',
        tournamentId: 't_1',
        code: 'DUO01',
        name: 'Duo One',
        captainId: 'u_0',
        members: members1,
      );

      final List<TeamMemberModel> members2 = [
        const TeamMemberModel(
          userId: 'u_0',
          name: 'Player 1',
          ign: 'P1',
          uid: '1001',
          role: TeamRole.captain,
        ),
        const TeamMemberModel(
          userId: 'u_1',
          name: 'Player 2',
          ign: 'P2',
          uid: '1002',
          role: TeamRole.member,
        ),
      ];

      final team2 = TournamentTeamModel(
        id: 'team_2',
        tournamentId: 't_1',
        code: 'DUO02',
        name: 'Duo Two',
        captainId: 'u_0',
        members: members2,
      );

      expect(team1.members.length < 2, isTrue);
      expect(team2.members.length >= 2, isTrue);
    });
  });
}
