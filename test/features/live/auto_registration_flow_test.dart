import 'package:blastix_esports/features/live/data/models/team_member_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auto Registration Flow Tests', () {
    test('Team with 3 confirmed main players is NOT ready and NOT registered', () {
      final members = [
        const TeamMemberModel(
          userId: 'u_1',
          name: 'Leader',
          ign: 'IGN1',
          uid: '101',
          role: TeamRole.captain,
          rosterType: RosterType.main,
          status: TeamMemberStatus.confirmed,
        ),
        const TeamMemberModel(
          userId: 'u_2',
          name: 'Member 1',
          ign: 'IGN2',
          uid: '102',
          role: TeamRole.member,
          rosterType: RosterType.main,
          status: TeamMemberStatus.confirmed,
        ),
        const TeamMemberModel(
          userId: 'u_3',
          name: 'Member 2',
          ign: 'IGN3',
          uid: '103',
          role: TeamRole.member,
          rosterType: RosterType.main,
          status: TeamMemberStatus.confirmed,
        ),
        const TeamMemberModel(
          userId: 'u_4',
          name: 'Member 3',
          ign: 'IGN4',
          uid: '104',
          role: TeamRole.member,
          rosterType: RosterType.main,
          status: TeamMemberStatus.pending,
        ),
      ];

      final team = TournamentTeamModel(
        id: 'team_001',
        tournamentId: 'tourney_001',
        code: 'TEST01',
        name: 'Test Squad',
        captainId: 'u_1',
        members: members,
        status: TeamRegistrationStatus.forming,
      );

      expect(team.confirmedMainCount, equals(3));
      expect(team.isRegistered, isFalse);
      expect(team.mainSlotsLeft, equals(1));
    });

    test('Team with 4 confirmed main players meets auto-registration criteria', () {
      final members = List.generate(
        4,
        (i) => TeamMemberModel(
          userId: 'u_${i + 1}',
          name: 'Player ${i + 1}',
          ign: 'IGN${i + 1}',
          uid: '10${i + 1}',
          role: i == 0 ? TeamRole.captain : TeamRole.member,
          rosterType: RosterType.main,
          status: TeamMemberStatus.confirmed,
        ),
      );

      final teamForming = TournamentTeamModel(
        id: 'team_002',
        tournamentId: 'tourney_001',
        code: 'TEST02',
        name: 'Test Squad 2',
        captainId: 'u_1',
        members: members,
        status: TeamRegistrationStatus.forming,
      );

      expect(teamForming.confirmedMainCount, equals(4));
      expect(teamForming.isReady, isTrue);

      // Auto-registration state transition
      final teamRegistered = teamForming.copyWith(
        status: TeamRegistrationStatus.registered,
      );

      expect(teamRegistered.isRegistered, isTrue);
      expect(teamRegistered.status, equals(TeamRegistrationStatus.registered));
    });
  });
}
