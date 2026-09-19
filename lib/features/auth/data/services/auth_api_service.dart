import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService(this._apiClient);

  Future<void> sendOtp(String email) async {
    await _apiClient.post(
      ApiEndpoints.sendOtp,
      data: {'email': email},
    );
  }

  Future<UserModel> login(String email, String otp) async {
    final responseData = await _apiClient.post(
      ApiEndpoints.login,
      data: {
        'email': email,
        'otp': otp,
      },
    );
    return UserModel.fromJson(responseData);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String otp,
  }) async {
    final responseData = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'name': name,
        'email': email,
        'otp': otp,
      },
    );
    return UserModel.fromJson(responseData);
  }

  Future<UserModel> socialLogin(String idToken, String provider) async {
    final responseData = await _apiClient.post(
      ApiEndpoints.socialLogin,
      data: {
        'token': idToken,
        'provider': provider,
      },
    );
    return UserModel.fromJson(responseData);
  }
}
