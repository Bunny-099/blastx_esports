import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/tournament_model.dart';

// TODO: Jab backend ready ho, is provider ko FutureProvider bana dena
// aur ApiService.getLiveTournaments() call karna, structure same rahega
final liveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return _dummyTournaments;
});

// Ek specific tournament id se detail nikalne ke liye
final tournamentByIdProvider = Provider.family<TournamentModel?, String>((ref, id) {
  final tournaments = ref.watch(liveTournamentsProvider);
  try {
    return tournaments.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});

// ── Dummy Data ──
final List<TournamentModel> _dummyTournaments = [
  TournamentModel(
    id: 't1',
    name: 'BlastX Winter Championship',
    gameName: 'BGMI',
    bannerUrl: 'https://picsum.photos/seed/bgmi/600/300',
    prizePool: '₹1,00,000',
    viewersCount: 12400,
    isLive: true,
    teams: [
      const TeamModel(id: 'a1', name: 'Team Velocity', logoUrl: '', status: TeamStatus.playing, score: 42),
      const TeamModel(id: 'a2', name: 'Soul Reapers', logoUrl: '', status: TeamStatus.playing, score: 38),
      const TeamModel(id: 'a3', name: 'Ghost Squad', logoUrl: '', status: TeamStatus.eliminated, score: 15),
      const TeamModel(id: 'a4', name: 'Team Nova', logoUrl: '', status: TeamStatus.eliminated, score: 12),
      const TeamModel(id: 'a5', name: 'Fury Esports', logoUrl: '', status: TeamStatus.qualified, score: 55),
      const TeamModel(id: 'a6', name: 'Blaze Gaming', logoUrl: '', status: TeamStatus.playing, score: 30),
    ],
    matches: [
      MatchModel(
        id: 'm1',
        teamA: const TeamModel(id: 'a1', name: 'Team Velocity', logoUrl: '', status: TeamStatus.playing, score: 42),
        teamB: const TeamModel(id: 'a2', name: 'Soul Reapers', logoUrl: '', status: TeamStatus.playing, score: 38),
        status: MatchStatus.live,
        round: 'Grand Finals - Map 3',
        time: 'LIVE NOW',
      ),
      MatchModel(
        id: 'm2',
        teamA: const TeamModel(id: 'a5', name: 'Fury Esports', logoUrl: '', status: TeamStatus.qualified, score: 55),
        teamB: const TeamModel(id: 'a6', name: 'Blaze Gaming', logoUrl: '', status: TeamStatus.playing, score: 30),
        status: MatchStatus.upcoming,
        round: 'Grand Finals - Map 4',
        time: '6:30 PM',
      ),
    ],
  ),
  TournamentModel(
    id: 't2',
    name: 'Free Fire Clash Cup',
    gameName: 'Free Fire',
    bannerUrl: 'https://picsum.photos/seed/freefire/600/300',
    prizePool: '₹50,000',
    viewersCount: 8100,
    isLive: true,
    teams: [
      const TeamModel(id: 'b1', name: 'Team Elite', logoUrl: '', status: TeamStatus.playing, score: 20),
      const TeamModel(id: 'b2', name: 'Raptors', logoUrl: '', status: TeamStatus.playing, score: 18),
    ],
    matches: [
      MatchModel(
        id: 'm3',
        teamA: const TeamModel(id: 'b1', name: 'Team Elite', logoUrl: '', status: TeamStatus.playing, score: 20),
        teamB: const TeamModel(id: 'b2', name: 'Raptors', logoUrl: '', status: TeamStatus.playing, score: 18),
        status: MatchStatus.live,
        round: 'Group B - Match 5',
        time: 'LIVE NOW',
      ),
    ],
  ),
];
