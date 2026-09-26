class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://blastx-esports-backend-production-4b5f.up.railway.app/v1';

  // Config Endpoints
  static const String appInit = '/config/init';

  // Auth Endpoints
  static const String verifyToken = '/auth/verify-token';
  static const String sendOtp = '/auth/send-otp';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String socialLogin = '/auth/social-login';

  // User Profile & Game Profile Endpoints
  static const String userMe = '/users/me';
  static const String userGameProfile = '/users/me/game-profile';

  // Tournaments Endpoints
  static const String tournaments = '/tournaments';
  static const String myTournaments = '/tournaments/me';
  static String tournamentDetail(String tid) => '/tournaments/$tid';
  static String tournamentRoom(String tid) => '/tournaments/$tid/room';
  static String tournamentParticipants(String tid) => '/tournaments/$tid/participants';
  static String tournamentMatches(String tid) => '/tournaments/$tid/matches';
  static String tournamentLeaderboard(String tid) => '/tournaments/$tid/leaderboard';
  static String registerTournament(String tid) => '/tournaments/$tid/register';

  // Teams & Tournament Roster Endpoints
  static const String myTeams = '/teams/me';
  static String teamDetail(String teamId) => '/teams/$teamId';
  static String myTeam(String tid) => '/tournaments/$tid/my-team';
  static String tournamentTeams(String tid) => '/tournaments/$tid/teams';
  static String teamByCode(String tid, String code) => '/tournaments/$tid/teams/code/$code';
  static String joinTeam(String teamId) => '/teams/$teamId/join';
  static String leaveTeam(String teamId) => '/teams/$teamId/leave';
  static String removeTeamMember(String teamId, String userId) => '/teams/$teamId/members/$userId';
  static String transferCaptain(String teamId) => '/teams/$teamId/transfer-captain';
  static String teamSubstitutes(String teamId) => '/teams/$teamId/substitutes';
  static String regenerateInvite(String teamId) => '/teams/$teamId/regenerate-invite';

  // Challenges Endpoints
  static const String challenges = '/challenges';
  static String claimChallenge(String id) => '/challenges/$id/claim';
  static String submitChallengeProof(String id) => '/challenges/$id/submit-proof';
}
