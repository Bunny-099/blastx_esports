import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/game_profile_model.dart';
import '../models/user_profile_model.dart';

class UserApiService {
  final ApiClient _apiClient;

  UserApiService(this._apiClient);

  Future<UserProfileModel> getUserProfile() async {
    final responseData = await _apiClient.get(ApiEndpoints.userMe);
    return UserProfileModel.fromJson(Map<String, dynamic>.from(responseData as Map));
  }

  Future<UserProfileModel> updateProfile({String? name, String? profilePic}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (profilePic != null) body['profile_pic'] = profilePic;

    final responseData = await _apiClient.patch(
      ApiEndpoints.userMe,
      data: body,
    );
    return UserProfileModel.fromJson(Map<String, dynamic>.from(responseData as Map));
  }

  Future<GameProfileModel?> getGameProfile({String gameSlug = 'free_fire'}) async {
    try {
      final responseData = await _apiClient.get(
        ApiEndpoints.userGameProfile,
        queryParameters: {'game_slug': gameSlug},
      );
      if (responseData == null) return null;
      return GameProfileModel.fromJson(Map<String, dynamic>.from(responseData as Map));
    } catch (e) {
      return null;
    }
  }

  Future<GameProfileModel> updateGameProfile({
    String gameSlug = 'free_fire',
    required String inGameUid,
    required String inGameName,
  }) async {
    final responseData = await _apiClient.post(
      ApiEndpoints.userGameProfile,
      data: {
        'game_slug': gameSlug,
        'in_game_uid': inGameUid,
        'in_game_name': inGameName,
      },
    );
    return GameProfileModel.fromJson(Map<String, dynamic>.from(responseData as Map));
  }
}
