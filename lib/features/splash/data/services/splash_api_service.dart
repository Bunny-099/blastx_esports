import 'package:flutter/foundation.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/app_config_model.dart';

class SplashApiService {
  final ApiClient _apiClient;

  SplashApiService(this._apiClient);

  Future<AppConfigModel> getAppConfig() async {
    try {
      final responseData = await _apiClient.get(ApiEndpoints.appInit);
      if (responseData != null && responseData is Map<String, dynamic>) {
        return AppConfigModel.fromJson(responseData);
      }
    } catch (e) {
      debugPrint('getAppConfig API error: $e');
    }
    // Safe default fallback config so app startup is never blocked by config failures
    return AppConfigModel(
      minVersion: '1.0.0',
      latestVersion: '1.0.0',
      isMaintenance: false,
    );
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
