import 'package:blastix_esports/features/profile/data/models/game_profile_model.dart';
import 'package:blastix_esports/features/profile/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Free Fire UID & Profile Sync Tests', () {
    test('GameProfileModel correctly stores and parses Free Fire UID and IGN', () {
      const gameProfile = GameProfileModel(
        inGameUid: '123456789',
        inGameName: 'ProGamer99',
      );

      expect(gameProfile.inGameUid, equals('123456789'));
      expect(gameProfile.inGameName, equals('ProGamer99'));
      expect(gameProfile.gameSlug, equals('free_fire'));

      final json = gameProfile.toJson();
      expect(json['in_game_uid'], equals('123456789'));
      expect(json['in_game_name'], equals('ProGamer99'));

      final parsed = GameProfileModel.fromJson(json);
      expect(parsed.inGameUid, equals('123456789'));
      expect(parsed.inGameName, equals('ProGamer99'));
    });

    test('UserProfileModel.copyWith correctly updates GameProfileModel with new Free Fire UID', () {
      const initialUser = UserProfileModel(
        id: 'user_1',
        name: 'Rahul Sharma',
        email: 'rahul@example.com',
        gameProfile: GameProfileModel(
          inGameUid: '1111222233',
          inGameName: 'Rahul_FF',
        ),
      );

      expect(initialUser.gameProfile?.inGameUid, equals('1111222233'));

      const updatedGameProfile = GameProfileModel(
        inGameUid: '9999888877',
        inGameName: 'Rahul_Pro_FF',
      );

      final updatedUser = initialUser.copyWith(gameProfile: updatedGameProfile);

      expect(updatedUser.gameProfile?.inGameUid, equals('9999888877'));
      expect(updatedUser.gameProfile?.inGameName, equals('Rahul_Pro_FF'));
      expect(updatedUser.name, equals('Rahul Sharma'));
    });

    test('UserProfileModel parses game_profile field from JSON correctly', () {
      final json = {
        'id': 'u_123',
        'name': 'Aman Kumar',
        'email': 'aman@example.com',
        'game_profile': {
          'game_slug': 'free_fire',
          'game_name': 'Free Fire',
          'in_game_uid': '555666777',
          'in_game_name': 'Aman_FF',
        },
      };

      final user = UserProfileModel.fromJson(json);

      expect(user.id, equals('u_123'));
      expect(user.gameProfile, isNotNull);
      expect(user.gameProfile!.inGameUid, equals('555666777'));
      expect(user.gameProfile!.inGameName, equals('Aman_FF'));
    });
  });
}
