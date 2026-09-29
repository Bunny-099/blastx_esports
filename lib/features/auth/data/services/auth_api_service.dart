import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/device_info_service.dart';
import '../models/user_model.dart';

class AuthApiService {
  final ApiClient _apiClient;
  final DeviceInfoService _deviceInfoService;

  AuthApiService(this._apiClient, this._deviceInfoService);

  Future<void> sendOtp(String email) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    await _apiClient.post(
      ApiEndpoints.sendOtp,
      data: {
        'email': email,
        ...deviceInfo.toJson(),
      },
    );
  }

  Future<UserModel> login(String email, String otp) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final responseData = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'otp': otp,
        ...deviceInfo.toJson(),
      },
    );
    return UserModel.fromJson(responseData);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String otp,
  }) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final responseData = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'otp': otp,
        ...deviceInfo.toJson(),
      },
    );
    return UserModel.fromJson(responseData);
  }

  Future<UserModel> socialLogin(String idToken, String provider) async {
    final deviceInfo = await _deviceInfoService.getDeviceInfo();
    final responseData = await _apiClient.post(
      ApiEndpoints.socialLogin,
      data: {
        'token': idToken,
        'provider': provider,
        ...deviceInfo.toJson(),
      },
    );
    return UserModel.fromJson(responseData);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Backend logout endpoint call failed or not yet deployed; catch safely so local logout completes.
    }
  }
}
