import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Join Request & Privacy-Safe TeamPreview Models Test', () {
    test('TeamPreview.fromJson parses privacy-safe fields correctly', () {
      final json = {
        'id': 'team_123',
        'name': 'Phoenix Esports',
        'tag': 'PHX',
        'logo_url': 'https://example.com/logo.png',
        'tournament_id': 'tourn_001',
        'tournament_name': 'BlastX Cup',
        'invite_code': 'PHX99',
        'responsible_person': {
          'name': 'Phoenix Captain',
          'role': 'LEADER',
        },
        'main_count': 3,
        'max_main': 4,
        'substitute_count': 1,
        'max_substitutes': 2,
        'accepting_substitutes': true,
        'slots_available': true,
        'registration_state': 'FORMING',
        'roster_locked': false,
        'require_join_approval': true,
        'is_member': false,
        'my_request_status': 'PENDING',
        'members': [
          {
            'name': 'Phoenix Captain',
            'avatar': 'https://example.com/c.png',
            'role': 'LEADER',
            'is_substitute': false,
          },
          {
            'name': 'Player Two',
            'avatar': '',
            'role': 'MEMBER',
            'is_substitute': false,
          },
          {
            'name': 'Sub Player',
            'avatar': '',
            'role': 'SUBSTITUTE',
            'is_substitute': true,
          },
        ],
      };

      final preview = TeamPreview.fromJson(json);

      expect(preview.id, 'team_123');
      expect(preview.name, 'Phoenix Esports');
      expect(preview.tag, 'PHX');
      expect(preview.responsiblePerson?.name, 'Phoenix Captain');
      expect(preview.responsiblePerson?.role, 'LEADER');
      expect(preview.mainCount, 3);
      expect(preview.maxMain, 4);
      expect(preview.substituteCount, 1);
      expect(preview.maxSubstitutes, 2);
      expect(preview.requireJoinApproval, isTrue);
      expect(preview.myRequestStatus, JoinRequestStatus.pending);
      expect(preview.members.length, 3);
      expect(preview.members.first.name, 'Phoenix Captain');
      expect(preview.members.last.isSubstitute, isTrue);
    });

    test('TeamPreview.fromJson parses integer slots_available response without TypeError', () {
      final json = {
        'id': 'cmv6oiglh000alo014o06iblz',
        'name': 'vvv',
        'tag': '',
        'logo_url': null,
        'tournament_id': 'cmv63koj9004bps01k5ejo9in',
        'responsible_person': {
          'name': 'Cyber Security New Delhi',
          'role': 'LEADER',
        },
        'main_count': 1,
        'max_main': 4,
        'substitute_count': 0,
        'max_substitutes': 1,
        'accepting_substitutes': true,
        'slots_available': 4,
        'registration_state': 'FORMING',
        'roster_locked': false,
        'require_join_approval': true,
        'is_member': false,
        'my_request_status': 'NONE',
        'members': [
          {
            'name': 'Cyber Security New Delhi',
            'avatar': 'https://example.com/a.png',
            'role': 'CAPTAIN',
            'roster_type': 'MAIN',
          },
        ],
      };

      final preview = TeamPreview.fromJson(json);

      expect(preview.id, 'cmv6oiglh000alo014o06iblz');
      expect(preview.name, 'vvv');
      expect(preview.slotsAvailable, isTrue);
      expect(preview.mainCount, 1);
      expect(preview.maxMain, 4);
      expect(preview.responsiblePerson?.name, 'Cyber Security New Delhi');
      expect(preview.members.length, 1);
    });

    test('JoinRequestStatus.fromString falls back safely on unknown values', () {
      expect(JoinRequestStatus.fromString('PENDING'), JoinRequestStatus.pending);
      expect(JoinRequestStatus.fromString('APPROVED'), JoinRequestStatus.approved);
      expect(JoinRequestStatus.fromString('REJECTED'), JoinRequestStatus.rejected);
      expect(JoinRequestStatus.fromString('CANCELLED'), JoinRequestStatus.cancelled);
      expect(JoinRequestStatus.fromString('UNKNOWN_XYZ'), JoinRequestStatus.none);
      expect(JoinRequestStatus.fromString(null), JoinRequestStatus.none);
    });

    test('JoinRequest.fromJson parses nested user and team objects', () {
      final json = {
        'id': 'req_99',
        'status': 'PENDING',
        'team_id': 'team_123',
        'team_name': 'Phoenix Esports',
        'tournament_id': 'tourn_001',
        'user': {
          'id': 'user_456',
          'name': 'John Doe',
          'profile_pic': 'https://example.com/p.png',
        },
        'in_game_name': 'JohnFF',
        'in_game_uid': '987654321',
        'requested_as_substitute': false,
        'created_at': '2026-03-30T10:00:00.000Z',
      };

      final req = JoinRequest.fromJson(json);

      expect(req.id, 'req_99');
      expect(req.status, JoinRequestStatus.pending);
      expect(req.teamId, 'team_123');
      expect(req.userId, 'user_456');
      expect(req.userName, 'John Doe');
      expect(req.inGameName, 'JohnFF');
      expect(req.inGameUid, '987654321');
      expect(req.requestedAsSubstitute, isFalse);
    });

    test('JoinResult.fromJson parses join_status PENDING vs JOINED vs missing', () {
      final pendingJson = {
        'join_status': 'PENDING',
        'request': {
          'id': 'req_1',
          'status': 'PENDING',
          'team_id': 'team_123',
        },
      };

      final pendingResult = JoinResult.fromJson(pendingJson);
      expect(pendingResult.status, JoinResultStatus.pending);
      expect(pendingResult.request?.id, 'req_1');

      final joinedJson = {
        'join_status': 'JOINED',
        'team': {
          'id': 'team_123',
          'tournament_id': 'tourn_001',
          'name': 'Phoenix Esports',
          'captain_id': 'cap_1',
        },
      };

      final joinedResult = JoinResult.fromJson(joinedJson);
      expect(joinedResult.status, JoinResultStatus.joined);
      expect(joinedResult.team?.id, 'team_123');

      // Backward compatibility check (missing join_status)
      final missingStatusJson = {
        'team': {
          'id': 'team_123',
          'tournament_id': 'tourn_001',
          'name': 'Phoenix Esports',
          'captain_id': 'cap_1',
        },
      };

      final compatResult = JoinResult.fromJson(missingStatusJson);
      expect(compatResult.status, JoinResultStatus.joined);
      expect(compatResult.team?.id, 'team_123');
    });
  });
}
