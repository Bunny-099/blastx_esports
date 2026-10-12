import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/live/data/models/match_center_model.dart';
import 'package:blastix_esports/features/live/data/models/room_credentials_model.dart';

void main() {
  group('MatchCenterModel JSON Parsing & Safe Fallbacks', () {
    test('Parses full MatchCenterModel response accurately', () {
      final json = {
        'my_access': 'PLAYING',
        'my_role': 'CAPTAIN',
        'my_status': {
          'state': 'ACTIVE',
          'current_round': 'Round 1 (Qualifiers)',
          'eliminated_in_round': null,
          'final_rank': null,
          'rank': 3,
          'total_points': 45,
          'total_kills': 22,
        },
        'rounds': [
          {
            'key': 'r1',
            'name': 'Round 1 (Qualifiers)',
            'round_type': 'GROUPS',
            'status': 'LIVE',
            'matches': [
              {
                'match_key': 'm1_grp_a',
                'match_number': 1,
                'group_name': 'Group A',
                'map': 'Bermuda',
                'status': 'COMPLETED',
                'scheduled_at': '2026-03-15T10:00:00Z',
                'room_state': 'PUBLISHED',
                'room_reveal_at': '2026-03-15T09:45:00Z',
                'my_result': {
                  'placement': 2,
                  'kills': 8,
                  'total_points': 18,
                },
                'recording_status': 'RECORDED',
                'stream_url': 'https://youtube.com/live/12345',
              }
            ],
          }
        ],
      };

      final model = MatchCenterModel.fromJson(json);

      expect(model.myAccess, equals(MyAccess.playing));
      expect(model.myRole, equals('CAPTAIN'));
      expect(model.myStatus, isNotNull);
      expect(model.myStatus!.state, equals(MatchCenterState.active));
      expect(model.myStatus!.rank, equals(3));
      expect(model.myStatus!.totalPoints, equals(45));
      expect(model.myStatus!.totalKills, equals(22));

      expect(model.rounds.length, equals(1));
      final round = model.rounds.first;
      expect(round.key, equals('r1'));
      expect(round.name, equals('Round 1 (Qualifiers)'));

      expect(round.matches.length, equals(1));
      final match = round.matches.first;
      expect(match.matchKey, equals('m1_grp_a'));
      expect(match.groupName, equals('Group A'));
      expect(match.status, equals(MatchUnitStatus.completed));
      expect(match.roomState, equals(RoomState.published));
      expect(match.myResult, isNotNull);
      expect(match.myResult!.placement, equals(2));
      expect(match.myResult!.kills, equals(8));
      expect(match.myResult!.totalPoints, equals(18));
    });

    test('Handles missing fields and unknown values with safe fallbacks', () {
      final json = {
        'my_access': 'UNKNOWN_ACCESS',
        'my_status': {
          'state': 'INVALID_STATE',
        },
        'rounds': [
          {
            'name': 'Round 2',
            'matches': [
              {
                'match_key': 'm2_grp_b',
                'status': 'UNKNOWN_STATUS',
                'room_state': 'UNKNOWN_ROOM_STATE',
              }
            ]
          }
        ]
      };

      final model = MatchCenterModel.fromJson(json);

      expect(model.myAccess, equals(MyAccess.none));
      expect(model.myStatus!.state, equals(MatchCenterState.active));
      expect(model.rounds.first.matches.first.status, equals(MatchUnitStatus.scheduled));
      expect(model.rounds.first.matches.first.roomState, equals(RoomState.hidden));
    });
  });

  group('RoomCredentialsState Error Mapping', () {
    test('Maps NOT_PLAYING_MEMBER to clear user message', () {
      final err = RoomCredentialsNotEligible.fromCode('NOT_PLAYING_MEMBER');
      expect(err.userMessage, contains('Only the Playing 4 can see room details'));
    });

    test('Maps ELIMINATED to clear user message', () {
      final err = RoomCredentialsNotEligible.fromCode('ELIMINATED');
      expect(err.userMessage, contains('eliminated from this tournament'));
    });

    test('Maps NOT_IN_THIS_MATCH to clear user message', () {
      final err = RoomCredentialsNotEligible.fromCode('NOT_IN_THIS_MATCH');
      expect(err.userMessage, contains('not in this match group'));
    });

    test('Maps NOT_REGISTERED to clear user message', () {
      final err = RoomCredentialsNotEligible.fromCode('NOT_REGISTERED');
      expect(err.userMessage, contains('not registered in this tournament'));
    });

    test('Parses RoomCredentialsModel successfully from JSON', () {
      final json = {
        'room_id': '8901234',
        'room_password': 'PASS99',
        'visible_from': '2026-03-15T09:45:00Z',
        'scheduled_at': '2026-03-15T10:00:00Z',
      };

      final credentials = RoomCredentialsModel.fromJson(json);
      expect(credentials.roomId, equals('8901234'));
      expect(credentials.roomPassword, equals('PASS99'));
      expect(credentials.visibleFrom, isNotNull);
    });
  });
}
