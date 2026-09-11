enum TeamStatus { playing, qualified, eliminated, upcoming }
enum MatchStatus { live, upcoming, completed }

class TeamModel {
  final String id;
  final String name;
  final String logoUrl;
  final TeamStatus status;
  final int score;

  const TeamModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.status,
    this.score = 0,
  });
}

class MatchModel {
  final String id;
  final TeamModel teamA;
  final TeamModel teamB;
  final MatchStatus status;
  final String round; // e.g. "Semi Final", "Group A"
  final String time;

  const MatchModel({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.status,
    required this.round,
    required this.time,
  });
}

class TournamentModel {
  final String id;
  final String name;
  final String gameName;
  final String bannerUrl;
  final String prizePool;
  final int viewersCount;
  final bool isLive;
  final List<MatchModel> matches;
  final List<TeamModel> teams;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.gameName,
    required this.bannerUrl,
    required this.prizePool,
    required this.viewersCount,
    required this.isLive,
    required this.matches,
    required this.teams,
  });
}