import '../models/app_config_model.dart';
import '../services/splash_api_service.dart';

class SplashRepository {
  final SplashApiService _apiService;

  SplashRepository(this._apiService);

  Future<AppConfigModel> getAppConfig() async {
    return await _apiService.getAppConfig();
  }

  Future<bool> checkUserAuth() async {
    // Logic to get token from local storage (like shared_preferences)
    // For now, returning false as placeholder
    const String? token = null; 
    if (token == null) return false;
    
    return await _apiService.verifySession(token);
  }
}
