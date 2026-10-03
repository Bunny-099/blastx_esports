import 'package:flutter_test/flutter_test.dart';
import 'package:blastix_esports/features/challenges/data/models/challenge_model.dart';

void main() {
  group('ChallengeModel Status Lifecycle Tests', () {
    test('parses ACTIVE status correctly', () {
      final json = {
        'id': 'c1',
        'title': 'Get 5 Kills',
        'description': 'Eliminate 5 enemies',
        'reward_xp': 50,
        'current_progress': 0,
        'target_progress': 5,
        'status': 'ACTIVE',
        'is_completed': false,
        'is_claimed': false,
      };

      final challenge = ChallengeModel.fromJson(json);

      expect(challenge.status, equals('ACTIVE'));
      expect(challenge.isProofSubmitted, isFalse);
      expect(challenge.isProofRejected, isFalse);
      expect(challenge.isReadyToClaim, isFalse);
      expect(challenge.isClaimed, isFalse);
    });

    test('parses PROOF_SUBMITTED status correctly and prevents claiming', () {
      final json = {
        'id': 'c2',
        'title': 'Booyah 1 Match',
        'description': 'Win a match',
        'reward_xp': 100,
        'current_progress': 1,
        'target_progress': 1,
        'status': 'PROOF_SUBMITTED',
        'is_completed': true,
        'is_claimed': false,
      };

      final challenge = ChallengeModel.fromJson(json);

      expect(challenge.status, equals('PROOF_SUBMITTED'));
      expect(challenge.isProofSubmitted, isTrue);
      expect(challenge.isProofRejected, isFalse);
      expect(challenge.isReadyToClaim, isFalse); // Cannot claim while under review
      expect(challenge.isClaimed, isFalse);
    });

    test('parses PROOF_REJECTED status correctly and enables retry', () {
      final json = {
        'id': 'c3',
        'title': 'Land 3 Headshots',
        'description': 'Get 3 headshots',
        'reward_xp': 75,
        'current_progress': 0,
        'target_progress': 3,
        'status': 'PROOF_REJECTED',
        'is_completed': false,
        'is_claimed': false,
      };

      final challenge = ChallengeModel.fromJson(json);

      expect(challenge.status, equals('PROOF_REJECTED'));
      expect(challenge.isProofSubmitted, isFalse);
      expect(challenge.isProofRejected, isTrue);
      expect(challenge.isReadyToClaim, isFalse);
      expect(challenge.isClaimed, isFalse);
    });

    test('parses COMPLETED (approved) status correctly and enables claiming', () {
      final json = {
        'id': 'c4',
        'title': 'Survive 15 Mins',
        'description': 'Survive in BR mode',
        'reward_xp': 60,
        'current_progress': 15,
        'target_progress': 15,
        'status': 'COMPLETED',
        'is_completed': true,
        'is_claimed': false,
      };

      final challenge = ChallengeModel.fromJson(json);

      expect(challenge.status, equals('COMPLETED'));
      expect(challenge.isProofSubmitted, isFalse);
      expect(challenge.isProofRejected, isFalse);
      expect(challenge.isReadyToClaim, isTrue); // Admin approved, ready to claim!
      expect(challenge.isClaimed, isFalse);
    });

    test('parses CLAIMED status correctly', () {
      final json = {
        'id': 'c5',
        'title': 'Daily Login',
        'description': 'Log in today',
        'reward_xp': 20,
        'current_progress': 1,
        'target_progress': 1,
        'status': 'CLAIMED',
        'is_completed': true,
        'is_claimed': true,
      };

      final challenge = ChallengeModel.fromJson(json);

      expect(challenge.status, equals('CLAIMED'));
      expect(challenge.isClaimed, isTrue);
      expect(challenge.isReadyToClaim, isFalse); // Already claimed
    });
  });
}
