import 'models/user_model.dart';
import 'services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;

  AuthRepository(this._apiService);

  Future<void> sendOtp(String email) async {
    await _apiService.sendOtp(email);
  }

  Future<UserModel> login(String email, String otp) async {
    return await _apiService.login(email, otp);
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String otp,
  }) async {
    return await _apiService.register(
      name: name,
      email: email,
      otp: otp,
    );
  }

  Future<UserModel> socialLogin(String idToken, String provider) async {
    return await _apiService.socialLogin(idToken, provider);
  }
}
