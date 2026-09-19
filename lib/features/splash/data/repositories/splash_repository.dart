import '../../../../core/services/storage_service.dart';
import '../models/app_config_model.dart';
import '../services/splash_api_service.dart';

class SplashRepository {
  final SplashApiService _apiService;
  final StorageService _storageService;

  SplashRepository(this._apiService, this._storageService);

  Future<AppConfigModel> getAppConfig() async {
    return await _apiService.getAppConfig();
  }

  Future<bool> checkUserAuth() async {
    final String? token = await _storageService.getToken();
    if (token == null) return false;

    return await _apiService.verifySession(token);
  }
}
