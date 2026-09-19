import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/app_config_model.dart';

class SplashApiService {
  final ApiClient _apiClient;

  SplashApiService(this._apiClient);

  Future<AppConfigModel> getAppConfig() async {
    final responseData = await _apiClient.get(ApiEndpoints.appInit);
    return AppConfigModel.fromJson(responseData);
  }

  Future<bool> verifySession(String token) async {
    try {
      await _apiClient.post(
        ApiEndpoints.verifyToken,
        data: {'token': token},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
