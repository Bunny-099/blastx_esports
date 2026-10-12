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
  static const String logout = '/auth/logout';

  // User Profile & Game Profile Endpoints
  static const String userMe = '/users/me';
  static const String deviceToken = '/users/me/device-token';
  static const String fcmToken = '/user/fcm-token';
  static const String userGameProfile = '/users/me/game-profile';
  static const String userRank = '/users/me/rank';
  static String userRankByUserId(String userId) => '/users/$userId/rank';

  // Home Landing Hub & Banners Endpoints
  static const String homeBanners = '/home/banners';
  static const String homeLiveStreams = '/home/live-streams';
  static const String homePartners = '/home/partners';
  static const String partnerInquire = '/partners/inquire';

  // Admin Web Panel Integration Endpoints
  static const String adminBanners = '/admin/banners';
  static String adminBannerById(String id) => '/admin/banners/$id';
  static const String adminLiveStreams = '/admin/live-streams';
  static const String adminPartnerInquiries = '/admin/partners/inquiries';

  // Free Fire Live Dedicated Endpoints
  static const String freeFireLive = '/free-fire-live';
  static String freeFireLiveDetail(String tid) => '/free-fire-live/$tid';
  static String freeFireLiveRoom(String tid) => '/free-fire-live/$tid/room';
  static String freeFireLiveMatches(String tid) => '/free-fire-live/$tid/matches';
  static String freeFireLiveLeaderboard(String tid) => '/free-fire-live/$tid/leaderboard';

  // BlastX Esports Tournaments Endpoints
  static const String tournaments = '/tournaments';
  static const String myTournaments = '/tournaments/me';
  static String tournamentDetail(String tid) => '/tournaments/$tid';
  static String tournamentStages(String tid) => '/tournaments/$tid/stages';
  static String tournamentMyAssignment(String tid) => '/tournaments/$tid/my-assignment';
  static String tournamentBracket(String tid) => '/tournaments/$tid/bracket';
  static String tournamentRoom(String tid) => '/tournaments/$tid/room';
  static String tournamentRegisteredTeams(String tid) => '/tournaments/$tid/registered-teams';
  static String tournamentParticipants(String tid) => '/tournaments/$tid/registered-teams';
  static String tournamentMatches(String tid) => '/tournaments/$tid/matches';
  static String tournamentLeaderboard(String tid) => '/tournaments/$tid/leaderboard';
  static String registerTournament(String tid) => '/tournaments/$tid/register';

  // Section 5: Match Center, Match Detail & Room Credentials Endpoints
  static String matchCenter(String tid) => '/tournaments/$tid/match-center';
  static String matchDetail(String tid, String matchKey) => '/tournaments/$tid/matches/$matchKey';
  static String matchRoomCredentials(String tid, String matchKey) => '/tournaments/$tid/matches/$matchKey/room';

  // Teams & Tournament Roster Endpoints
  static const String myTeams = '/teams/me';
  static String teamDetail(String teamId) => '/teams/$teamId';
  static String myTeam(String tid) => '/tournaments/$tid/my-team';
  static String tournamentTeams(String tid) => '/tournaments/$tid/teams';
  static String teamByCode(String tid, String code) => '/tournaments/$tid/teams/code/$code';
  static String joinTeam(String teamId) => '/teams/$teamId/join';
  static String teamJoinRequests(String teamId) => '/teams/$teamId/join-requests';
  static String approveJoinRequest(String teamId, String requestId) => '/teams/$teamId/join-requests/$requestId/approve';
  static String rejectJoinRequest(String teamId, String requestId) => '/teams/$teamId/join-requests/$requestId/reject';
  static String cancelJoinRequest(String requestId) => '/teams/join-requests/$requestId/cancel';
  static String myJoinRequests([String status = 'PENDING']) => '/users/me/join-requests?status=$status';
  static String leaveTeam(String teamId) => '/teams/$teamId/leave';
  static String removeTeamMember(String teamId, String userId) => '/teams/$teamId/members/$userId';
  static String transferCaptain(String teamId) => '/teams/$teamId/transfer-captain';
  static String teamSubstitutes(String teamId) => '/teams/$teamId/substitutes';
  static String regenerateInvite(String teamId) => '/teams/$teamId/regenerate-invite';

  // Section 3: Playing Roster & Registration Approvals Endpoints
  static String updatePlayingRoster(String teamId) => '/teams/$teamId/playing-roster';
  static String cancelRegistrationRequest(String tid, String teamId) => '/tournaments/$tid/teams/$teamId/registration/cancel-request';
  static String myRegistrationApprovals([String status = 'PENDING']) => '/users/me/registration-approvals?status=$status';
  static String registrationApprovalDetail(String id) => '/registration-approvals/$id';
  static String approveRegistration(String id) => '/registration-approvals/$id/approve';
  static String declineRegistration(String id) => '/registration-approvals/$id/decline';

  // Challenges Endpoints
  static const String challenges = '/challenges';
  static String claimChallenge(String id) => '/challenges/$id/claim';
  static String submitChallengeProof(String id) => '/challenges/$id/submit-proof';

  // Persistent Squad & Invitations Endpoints
  static const String mySquad = '/squads/me';
  static const String createSquad = '/squads';
  static String squadDetail(String squadId) => '/squads/$squadId';
  static String leaveSquad(String squadId) => '/squads/$squadId/leave';
  static String removeSquadMember(String squadId, String userId) => '/squads/$squadId/members/$userId';
  static String transferSquadLeader(String squadId) => '/squads/$squadId/transfer-leader';
  static String updateSquadMemberRole(String squadId, String userId) => '/squads/$squadId/members/$userId/role';
  static String swapSquadMembers(String squadId) => '/squads/$squadId/swap';
  static String squadWaitlist(String squadId) => '/squads/$squadId/waitlist';

  // Tournament Invitations Endpoints
  static const String pendingInvitations = '/invitations/pending';
  static String sendSquadInvitations(String squadId, String tournamentId) => '/squads/$squadId/tournaments/$tournamentId/invite';
  static String respondInvitation(String invitationId) => '/invitations/$invitationId/respond';

  // Support & Issue Reports Endpoints
  static const String reportIssue = '/support/report-issue';
  static const String contactSupport = '/support/contact';
}
