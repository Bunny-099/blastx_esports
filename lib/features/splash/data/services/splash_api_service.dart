import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/app_config_model.dart';

class SplashApiService {
  final ApiClient _apiClient;

  SplashApiService(this._apiClient);

  Future<AppConfigModel> getAppConfig() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.appInit);
      return AppConfigModel.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifySession(String token) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyToken,
        data: {'token': token},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
