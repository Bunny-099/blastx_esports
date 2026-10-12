import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/auth/data/models/user_model.dart';
import 'package:blastix_esports/features/profile/data/models/user_profile_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';

void main() {
  group('Section 7 Unit Tests', () {
    test('UserModel and UserProfileModel needsProfileSetup parsing', () {
      final jsonNeedsSetup = {
        'id': 'user_1',
        'name': 'Gamer',
        'email': 'gamer@test.com',
        'needs_profile_setup': true,
      };
      final userModel = UserModel.fromJson(jsonNeedsSetup);
      expect(userModel.needsProfileSetup, true);

      final userProfileWithNoPhone = UserProfileModel.fromJson({
        'id': 'u1',
        'name': 'Gamer',
        'email': 'g@test.com',
      });
      expect(userProfileWithNoPhone.needsProfileSetup, true);

      final userProfileWithPhone = UserProfileModel.fromJson({
        'id': 'u2',
        'name': 'Gamer Two',
        'email': 'g2@test.com',
        'phone': '9876543210',
      });
      expect(userProfileWithPhone.needsProfileSetup, false);
    });

    test('TournamentTeamModel mode parsing (SOLO, DUO, SQUAD)', () {
      final squadJson = {
        'id': 't1',
        'tournament_id': 'tour_1',
        'code': 'SQD1',
        'name': 'Squad Team',
        'captain_id': 'cap1',
        'team_mode': 'SQUAD',
        'maxMainPlayers': 4,
      };
      final squadTeam = TournamentTeamModel.fromJson(squadJson);
      expect(squadTeam.isDuoMode, false);
      expect(squadTeam.isSoloMode, false);

      final duoJson = {
        'id': 't2',
        'tournament_id': 'tour_2',
        'code': 'DUO1',
        'name': 'Duo Team',
        'captain_id': 'cap2',
        'team_mode': 'DUO',
        'maxMainPlayers': 2,
      };
      final duoTeam = TournamentTeamModel.fromJson(duoJson);
      expect(duoTeam.isDuoMode, true);
      expect(duoTeam.maxMainPlayers, 2);

      final soloJson = {
        'id': 't3',
        'tournament_id': 'tour_3',
        'code': 'SOLO1',
        'name': 'Solo Entry',
        'captain_id': 'cap3',
        'team_mode': 'SOLO',
        'maxMainPlayers': 1,
      };
      final soloTeam = TournamentTeamModel.fromJson(soloJson);
      expect(soloTeam.isSoloMode, true);
    });

    test('PendingRosterChange parsing and model fields', () {
      final rosterChangeJson = {
        'submission_id': 'sub_123',
        'new_roster_version': 2,
        'added_players': [
          {
            'user_id': 'u_new1',
            'name': 'New Player',
            'approval_status': 'PENDING',
          }
        ],
        'removed_user_ids': ['u_old1'],
        'expires_at': '2026-10-15T12:00:00.000Z',
      };

      final change = PendingRosterChange.fromJson(rosterChangeJson);
      expect(change.submissionId, 'sub_123');
      expect(change.newRosterVersion, 2);
      expect(change.addedPlayers.length, 1);
      expect(change.addedPlayers.first.name, 'New Player');
      expect(change.addedPlayers.first.isPending, true);
      expect(change.removedUserIds, ['u_old1']);
      expect(change.expiresAt, isNotNull);
    });
  });
}
