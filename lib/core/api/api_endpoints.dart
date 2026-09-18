class ApiEndpoints {
  // Base URLs
  static const String baseUrl = 'https://api.blastxesports.com'; // Backend developer can change this

  // Config Endpoints
  static const String appInit = '/v1/config/init';
  
  // Auth Endpoints
  static const String verifyToken = '/v1/auth/verify-token';
  static const String login = '/v1/auth/login';
  static const String register = '/v1/auth/register';
}
