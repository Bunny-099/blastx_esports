class ApiEndpoints {
  // Base URLs
  static const String baseUrl = 'https://blastx-esports-backend-production.up.railway.app';

  // Config Endpoints
  static const String appInit = '/v1/config/init';
  
  // Auth Endpoints
  static const String verifyToken = '/v1/auth/verify-token';
  static const String sendOtp = '/v1/auth/send-otp';
  static const String login = '/v1/auth/login';
  static const String register = '/v1/auth/register';
  static const String socialLogin = '/v1/auth/social-login';
}
