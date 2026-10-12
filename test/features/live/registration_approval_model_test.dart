import 'package:blastix_esports/features/live/data/models/registration_approval_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Section 3 Models Test', () {
    test('ApprovalStatus.fromString handles status string correctly', () {
      expect(ApprovalStatus.fromString('PENDING'), ApprovalStatus.pending);
      expect(ApprovalStatus.fromString('APPROVED'), ApprovalStatus.approved);
      expect(ApprovalStatus.fromString('DECLINED'), ApprovalStatus.declined);
      expect(ApprovalStatus.fromString('NOT_REQUIRED'), ApprovalStatus.notRequired);
      expect(ApprovalStatus.fromString(null), ApprovalStatus.pending);
      expect(ApprovalStatus.fromString('UNKNOWN'), ApprovalStatus.pending);
    });

    test('RegistrationPlayer.fromJson parses player fields correctly', () {
      final json = {
        'user_id': 'u1',
        'name': 'Player One',
        'avatar': 'https://example.com/a.png',
        'role': 'CAPTAIN',
        'is_playing': true,
        'approval_status': 'APPROVED',
      };

      final player = RegistrationPlayer.fromJson(json);
      expect(player.userId, 'u1');
      expect(player.name, 'Player One');
      expect(player.role, 'CAPTAIN');
      expect(player.isPlaying, isTrue);
      expect(player.approvalStatus, ApprovalStatus.approved);
      expect(player.isApproved, isTrue);
    });

    test('RegistrationInfo.fromJson parses registration payload correctly', () {
      final json = {
        'submission_id': 'sub_123',
        'state': 'PENDING_PLAYER_APPROVAL',
        'roster_version': 2,
        'require_player_approval': true,
        'required_count': 3,
        'approved_count': 1,
        'submitted_at': '2026-03-31T12:00:00.000Z',
        'players': [
          {
            'user_id': 'u1',
            'name': 'Captain',
            'role': 'LEADER',
            'approval_status': 'APPROVED',
          },
          {
            'user_id': 'u2',
            'name': 'Player Two',
            'role': 'PLAYER',
            'approval_status': 'PENDING',
          },
        ],
      };

      final reg = RegistrationInfo.fromJson(json);
      expect(reg.submissionId, 'sub_123');
      expect(reg.state, TeamRegistrationState.pendingPlayerApproval);
      expect(reg.rosterVersion, 2);
      expect(reg.requirePlayerApproval, isTrue);
      expect(reg.requiredCount, 3);
      expect(reg.approvedCount, 1);
      expect(reg.players.length, 2);
    });

    test('TournamentTeamModel.fromJson parses Section 3 fields safely', () {
      final json = {
        'id': 'team_1',
        'tournament_id': 't_1',
        'code': 'CODE123',
        'name': 'Alpha Esports',
        'captain_id': 'c_1',
        'registration_state': 'ROSTER_CHANGE_REQUIRED',
        'roster_version': 3,
        'can_register': false,
        'my_pending_approval_id': 'app_99',
        'can_cancel_registration_request': true,
        'registration': {
          'submission_id': 'sub_99',
          'state': 'ROSTER_CHANGE_REQUIRED',
          'roster_version': 3,
          'required_count': 3,
          'approved_count': 1,
        },
      };

      final team = TournamentTeamModel.fromJson(json);
      expect(team.id, 'team_1');
      expect(team.registrationState, TeamRegistrationState.rosterChangeRequired);
      expect(team.rosterVersion, 3);
      expect(team.canRegister, isFalse);
      expect(team.myPendingApprovalId, 'app_99');
      expect(team.canCancelRegistrationRequest, isTrue);
      expect(team.registration?.submissionId, 'sub_99');
    });

    test('RegistrationApproval.fromJson parses full approval detail payload', () {
      final json = {
        'id': 'app_001',
        'status': 'PENDING',
        'roster_version': 1,
        'created_at': '2026-03-31T10:00:00.000Z',
        'tournament': {
          'id': 'tourn_01',
          'title': 'BlastX Championship',
          'banner_url': 'https://example.com/banner.jpg',
          'starts_at': '2026-04-01T15:00:00.000Z',
        },
        'team': {
          'id': 'team_01',
          'name': 'Omega Gaming',
          'tag': 'OMG',
          'logo_url': 'https://example.com/logo.png',
        },
        'responsible_person': {
          'name': 'Omega Leader',
          'role': 'LEADER',
        },
        'playing_players': [
          {
            'user_id': 'p1',
            'name': 'Omega Leader',
            'role': 'LEADER',
            'approval_status': 'APPROVED',
          },
          {
            'user_id': 'p2',
            'name': 'Player Two',
            'role': 'PLAYER',
            'approval_status': 'PENDING',
          },
        ],
      };

      final approval = RegistrationApproval.fromJson(json);
      expect(approval.id, 'app_001');
      expect(approval.status, ApprovalStatus.pending);
      expect(approval.isPending, isTrue);
      expect(approval.tournamentTitle, 'BlastX Championship');
      expect(approval.teamName, 'Omega Gaming');
      expect(approval.responsiblePerson?.name, 'Omega Leader');
      expect(approval.playingPlayers.length, 2);
    });
  });
}
