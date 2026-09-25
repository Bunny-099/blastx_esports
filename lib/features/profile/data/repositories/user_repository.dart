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
}
