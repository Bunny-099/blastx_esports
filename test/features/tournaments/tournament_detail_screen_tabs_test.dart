import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/tournaments/data/models/tournament_format_models.dart';

void main() {
  group('Tournament Detail 4-Tab & Registration Validation Tests', () {
    test('TeamMode required player counts validation', () {
      expect(TeamMode.SQUAD.requiredPlayersCount, 4);
      expect(TeamMode.DUO.requiredPlayersCount, 2);
      expect(TeamMode.SOLO.requiredPlayersCount, 1);
    });

    test('StageStatus and QualificationStatus enum mappings', () {
      expect(StageStatus.fromJson('SCHEDULED'), StageStatus.SCHEDULED);
      expect(StageStatus.fromJson('LIVE'), StageStatus.LIVE);
      expect(StageStatus.fromJson('COMPLETED'), StageStatus.COMPLETED);

      expect(QualificationStatus.fromJson('QUALIFIED'), QualificationStatus.QUALIFIED);
      expect(QualificationStatus.fromJson('ELIMINATED'), QualificationStatus.ELIMINATED);
      expect(QualificationStatus.fromJson('WILD_CARD'), QualificationStatus.WILD_CARD);
      expect(QualificationStatus.fromJson('PENDING'), QualificationStatus.PENDING);
    });

    test('MyActiveAssignmentModel credential status check', () {
      final releasedAssignment = MyActiveAssignmentModel.fromJson({
        'current_stage_number': 1,
        'stage_name': 'Round 1 (Qualifiers)',
        'group_id': 'grp_b',
        'group_name': 'Group B',
        'assigned_slot': 7,
        'room_credentials_released': true,
        'room_id': '8934102',
        'room_password': 'BLAST7X',
        'my_status': 'QUALIFIED',
      });

      expect(releasedAssignment.roomCredentialsReleased, isTrue);
      expect(releasedAssignment.roomId, '8934102');
      expect(releasedAssignment.roomPassword, 'BLAST7X');
      expect(releasedAssignment.myStatus, QualificationStatus.QUALIFIED);

      final lockedAssignment = MyActiveAssignmentModel.fromJson({
        'current_stage_number': 1,
        'stage_name': 'Round 1 (Qualifiers)',
        'group_id': 'grp_b',
        'group_name': 'Group B',
        'assigned_slot': 7,
        'room_credentials_released': false,
        'room_id': null,
        'room_password': null,
        'my_status': 'PENDING',
      });

      expect(lockedAssignment.roomCredentialsReleased, isFalse);
      expect(lockedAssignment.roomId, null);
      expect(lockedAssignment.roomPassword, null);
    });
  });
}
