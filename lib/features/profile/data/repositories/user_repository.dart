import 'package:blastix_esports/features/splash/providers/splash_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_profile_model.dart';
import '../models/user_profile_model.dart';
import '../services/user_api_service.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserApiService(apiClient);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(userApiServiceProvider);
  return UserRepository(apiService);
});

class UserRepository {
  final UserApiService _apiService;

  UserRepository(this._apiService);

  Future<UserProfileModel> getUserProfile() async {
    var user = await _apiService.getUserProfile();
    if (user.gameProfile == null) {
      final gameProfile = await _apiService.getGameProfile();
      if (gameProfile != null) {
        user = user.copyWith(gameProfile: gameProfile);
      }
    }
    return user;
  }

  Future<UserProfileModel> updateProfile({String? name, String? profilePic}) =>
      _apiService.updateProfile(name: name, profilePic: profilePic);

  Future<GameProfileModel?> getGameProfile({String gameSlug = 'free_fire'}) =>
      _apiService.getGameProfile(gameSlug: gameSlug);

  Future<GameProfileModel> updateGameProfile({
    String gameSlug = 'free_fire',
    required String inGameUid,
    required String inGameName,
  }) =>
      _apiService.updateGameProfile(
        gameSlug: gameSlug,
        inGameUid: inGameUid,
        inGameName: inGameName,
      );

  Future<UserProfileModel> updateFullUserProfile({
    String? name,
    String? profilePic,
    String? freeFireUid,
    String? inGameName,
  }) async {
    UserProfileModel updatedUser;
    final cleanName = (name != null && name.trim().isNotEmpty) ? name.trim() : null;
    try {
      updatedUser = await _apiService.updateProfile(
        name: cleanName,
        profilePic: profilePic,
      );
    } catch (_) {
      // If server profile update fails, fallback to current user copy with local field updates
      try {
        var user = await getUserProfile();
        updatedUser = user.copyWith(
          name: cleanName ?? user.name,
          profilePic: profilePic ?? user.profilePic,
        );
      } catch (_) {
        updatedUser = UserProfileModel(
          id: '',
          name: cleanName ?? 'Gamer',
          email: '',
          profilePic: profilePic,
        );
      }
    }

    if (freeFireUid != null && freeFireUid.trim().isNotEmpty) {
      final cleanUid = freeFireUid.trim();
      final cleanIgn = (inGameName != null && inGameName.trim().isNotEmpty)
          ? inGameName.trim()
          : (cleanName ?? updatedUser.name);

      try {
        final gameProfile = await _apiService.updateGameProfile(
          gameSlug: 'free_fire',
          inGameUid: cleanUid,
          inGameName: cleanIgn,
        );
        updatedUser = updatedUser.copyWith(gameProfile: gameProfile);
      } catch (_) {
        // If server game profile update fails, create a local GameProfileModel
        final localGameProfile = GameProfileModel(
          gameSlug: 'free_fire',
          gameName: 'Free Fire',
          inGameUid: cleanUid,
          inGameName: cleanIgn,
        );
        updatedUser = updatedUser.copyWith(gameProfile: localGameProfile);
      }
    }

    return updatedUser;
  }

  Future<Map<String, dynamic>?> getUserRank({String? userId}) =>
      _apiService.getUserRank(userId: userId);
}
