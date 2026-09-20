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
  static String myTeam(String tid) => '/v1/tournaments/$tid/my-team';
  static String tournamentTeams(String tid) => '/v1/tournaments/$tid/teams';
  static String teamByCode(String tid, String code) => '/v1/tournaments/$tid/teams/code/$code';
  static String joinTeam(String teamId) => '/v1/teams/$teamId/join';
  static String leaveTeam(String teamId) => '/v1/teams/$teamId/leave';
  static String removeTeamMember(String teamId, String userId) => '/v1/teams/$teamId/members/$userId';
  static String transferCaptain(String teamId) => '/v1/teams/$teamId/transfer-captain';
  static String teamSubstitutes(String teamId) => '/v1/teams/$teamId/substitutes';
}
