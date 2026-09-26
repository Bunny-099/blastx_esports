import 'package:blastix_esports/features/profile/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfileModel Tests', () {
    test('should parse profile stats correctly from JSON', () {
      final json = {
        'id': 'u123',
        'name': 'Pro Gamer',
        'email': 'progamer@example.com',
        'tournaments_played': 35,
        'tournaments_won': 12,
        'total_kills': 210,
        'win_rate': '34.3%',
        'xp': 4500,
        'rank': 5,
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.id, 'u123');
      expect(profile.name, 'Pro Gamer');
      expect(profile.tournamentsPlayed, 35);
      expect(profile.tournamentsWon, 12);
      expect(profile.totalKills, 210);
      expect(profile.winRate, '34.3%');
      expect(profile.xp, 4500);
      expect(profile.rank, 5);
    });

    test('should use default stats when JSON does not contain stats fields', () {
      final json = {
        'id': 'u456',
        'name': 'Casual Player',
        'email': 'casual@example.com',
      };

      final profile = UserProfileModel.fromJson(json);

      expect(profile.tournamentsPlayed, 24);
      expect(profile.tournamentsWon, 8);
      expect(profile.totalKills, 142);
      expect(profile.winRate, '33.3%');
    });

    test('toJson should include stats fields', () {
      const profile = UserProfileModel(
        id: 'u789',
        name: 'GamerX',
        email: 'gamerx@example.com',
        tournamentsPlayed: 50,
        tournamentsWon: 20,
        totalKills: 300,
      );

      final json = profile.toJson();

      expect(json['tournaments_played'], 50);
      expect(json['tournaments_won'], 20);
      expect(json['total_kills'], 300);
    });
  });
}
