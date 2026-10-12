import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/live/data/models/match_center_model.dart';
import 'package:blastix_esports/features/live/data/models/room_credentials_model.dart';

void main() {
  group('Section 5: Match Center & Room Credentials Logic Tests', () {
    test('MyAccess enum parses Playing, Non-Playing, and None correctly', () {
      expect(MyAccess.fromString('PLAYING'), equals(MyAccess.playing));
      expect(MyAccess.fromString('playing'), equals(MyAccess.playing));
      expect(MyAccess.fromString('NON_PLAYING'), equals(MyAccess.nonPlaying));
      expect(MyAccess.fromString('MANAGER'), equals(MyAccess.nonPlaying));
      expect(MyAccess.fromString('SUBSTITUTE'), equals(MyAccess.nonPlaying));
      expect(MyAccess.fromString('NONE'), equals(MyAccess.none));
      expect(MyAccess.fromString(null), equals(MyAccess.none));

      expect(MyAccess.playing.isPlaying, isTrue);
      expect(MyAccess.nonPlaying.isNonPlaying, isTrue);
      expect(MyAccess.none.isNone, isTrue);
    });

    test('RoomState enum parses HIDDEN, PUBLISHED, and NOT_ELIGIBLE correctly', () {
      expect(RoomState.fromString('HIDDEN'), equals(RoomState.hidden));
      expect(RoomState.fromString('LOCKED'), equals(RoomState.hidden));
      expect(RoomState.fromString('PUBLISHED'), equals(RoomState.published));
      expect(RoomState.fromString('READY'), equals(RoomState.published));
      expect(RoomState.fromString('NOT_ELIGIBLE'), equals(RoomState.notEligible));
      expect(RoomState.fromString(null), equals(RoomState.hidden));

      expect(RoomState.hidden.isHidden, isTrue);
      expect(RoomState.published.isPublished, isTrue);
      expect(RoomState.notEligible.isNotEligible, isTrue);
    });

    test('MatchUnitStatus enum parses SCHEDULED, LIVE, and COMPLETED correctly', () {
      expect(MatchUnitStatus.fromString('SCHEDULED'), equals(MatchUnitStatus.scheduled));
      expect(MatchUnitStatus.fromString('LIVE'), equals(MatchUnitStatus.live));
      expect(MatchUnitStatus.fromString('COMPLETED'), equals(MatchUnitStatus.completed));
      expect(MatchUnitStatus.fromString(null), equals(MatchUnitStatus.scheduled));
    });

    test('RoomCredentialsNotEligible maps all error codes to clear user messages', () {
      final notPlaying = RoomCredentialsNotEligible.fromCode('NOT_PLAYING_MEMBER');
      expect(notPlaying.userMessage, equals('Only the Playing 4 can see room details.'));

      final eliminated = RoomCredentialsNotEligible.fromCode('ELIMINATED');
      expect(eliminated.userMessage, equals('Your team is eliminated from this tournament.'));

      final notInMatch = RoomCredentialsNotEligible.fromCode('NOT_IN_THIS_MATCH');
      expect(notInMatch.userMessage, equals('Your team is not in this match group.'));

      final notRegistered = RoomCredentialsNotEligible.fromCode('NOT_REGISTERED');
      expect(notRegistered.userMessage, equals('You are not registered in this tournament.'));

      final custom = RoomCredentialsNotEligible.fromCode('OTHER', customMsg: 'Custom denial message');
      expect(custom.userMessage, equals('Custom denial message'));
    });

    test('MatchCenterMatchItemModel JSON parsing retains myResult when completed', () {
      final json = {
        'match_key': 'match_101',
        'match_number': 2,
        'group_name': 'Group B',
        'map': 'Purgatory',
        'status': 'COMPLETED',
        'scheduled_at': '2026-03-20T14:00:00Z',
        'room_state': 'PUBLISHED',
        'my_result': {
          'placement': 1,
          'kills': 12,
          'total_points': 24,
        },
      };

      final match = MatchCenterMatchItemModel.fromJson(json);

      expect(match.matchKey, equals('match_101'));
      expect(match.matchNumber, equals(2));
      expect(match.groupName, equals('Group B'));
      expect(match.map, equals('Purgatory'));
      expect(match.status, equals(MatchUnitStatus.completed));
      expect(match.roomState, equals(RoomState.published));
      expect(match.myResult, isNotNull);
      expect(match.myResult!.placement, equals(1));
      expect(match.myResult!.kills, equals(12));
      expect(match.myResult!.totalPoints, equals(24));
    });
  });
}
