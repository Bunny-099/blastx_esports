import 'package:blastx_esports/features/live/data/models/tournament_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// LIVE PROVIDER
/// ============================================================
/// Riverpod providers that supply tournament data to the UI.
///
///  - liveTournamentsProvider : list of all tournaments (dummy data
///                              for now, replace with repository /
///                              API call later)
///  - tournamentByIdProvider  : fetch a single tournament by its id,
///                              used by tournament_detail_screen.dart
/// ============================================================

/// NOTE: Replace the fixed import path above ("package:live_tournaments/...")
/// with your actual app package name from pubspec.yaml if different.

/// Main provider - list of all live/upcoming tournaments.
final liveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return _dummyTournaments;
});

/// Derived provider - only tournaments that are currently LIVE.
/// Useful if you want a separate "Live Now" horizontal strip later.
final onlyLiveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final all = ref.watch(liveTournamentsProvider);
  return all.where((t) => t.isLive).toList();
});

/// Derived provider - only tournaments that are UPCOMING.
final upcomingTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final all = ref.watch(liveTournamentsProvider);
  return all.where((t) => t.status == TournamentStatus.upcoming).toList();
});

/// Family provider - fetch a single tournament by its ID.
/// Used inside tournament_detail_screen.dart via:
///   ref.watch(tournamentByIdProvider(tournamentId))
final tournamentByIdProvider =
Provider.family<TournamentModel?, String>((ref, id) {
  final all = ref.watch(liveTournamentsProvider);
  try {
    return all.firstWhere((t) => t.id == id);
  } catch (_) {
    return null;
  }
});

/// Simple search query provider - bound to the 3D capsule search bar.
/// live_screen.dart will update this on every keystroke.
final tournamentSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered list based on search query - what the UI actually renders.
final filteredTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(tournamentSearchQueryProvider).trim().toLowerCase();
  final all = ref.watch(liveTournamentsProvider);

  if (query.isEmpty) return all;

  return all.where((t) {
    return t.name.toLowerCase().contains(query) ||
        t.game.toLowerCase().contains(query) ||
        t.organizer.toLowerCase().contains(query);
  }).toList();
});

/// Simple search query provider for upcoming tournaments.
final upcomingSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered list of upcoming tournaments based on search query.
final filteredUpcomingTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(upcomingSearchQueryProvider).trim().toLowerCase();
  final all = ref.watch(upcomingTournamentsProvider);

  if (query.isEmpty) return all;

  return all.where((t) {
    return t.name.toLowerCase().contains(query) ||
        t.game.toLowerCase().contains(query) ||
        t.organizer.toLowerCase().contains(query);
  }).toList();
});

/// ------------------------------------------------------------
/// DUMMY DATA
/// ------------------------------------------------------------
/// Replace this with a real repository call (API / Firestore) later.
/// Kept varied on purpose - different games & accent colors so the
/// unique angular card design can be tested with real visual variety.
final List<TournamentModel> _dummyTournaments = [
  TournamentModel(
    id: 't1',
    name: 'BGMI Conqueror Series',
    game: 'BGMI',
    bannerImageUrl: 'https://picsum.photos/seed/bgmi1/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/bgmilogo/100/100',
    prizePool: 500000,
    viewersCount: 128000,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(hours: 1)),
    organizer: 'Krafton India',
    accentColorHex: '#FF7A00',
    teams: [
      const TeamModel(
          id: 'te1',
          name: 'Team Soul',
          logoUrl: 'https://picsum.photos/seed/soul/100/100',
          score: 42,
          status: TeamStatus.winning),
      const TeamModel(
          id: 'te2',
          name: 'GodLike Esports',
          logoUrl: 'https://picsum.photos/seed/godlike/100/100',
          score: 38,
          status: TeamStatus.playing),
    ],
    matches: [
      MatchModel(
        id: 'm1',
        tournamentId: 't1',
        round: 'Grand Finals - Match 3',
        teamA: const TeamModel(
            id: 'te1', name: 'Team Soul', logoUrl: '', score: 14),
        teamB: const TeamModel(
            id: 'te2', name: 'GodLike Esports', logoUrl: '', score: 11),
        matchTime: DateTime.now(),
        status: MatchStatus.live,
        mapOrMode: 'Erangel',
      ),
    ],
  ),
  TournamentModel(
    id: 't2',
    name: 'Valorant Champions Qualifier',
    game: 'Valorant',
    bannerImageUrl: 'https://picsum.photos/seed/valorant1/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/vallogo/100/100',
    prizePool: 750000,
    viewersCount: 96500,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 40)),
    organizer: 'Riot Games',
    accentColorHex: '#FF3DAE',
  ),
  TournamentModel(
    id: 't3',
    name: 'Free Fire Max India Cup',
    game: 'Free Fire',
    bannerImageUrl: 'https://picsum.photos/seed/freefire1/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/fflogo/100/100',
    prizePool: 300000,
    viewersCount: 210000,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(hours: 2)),
    organizer: 'Garena',
    accentColorHex: '#FF6B00',
  ),
  TournamentModel(
    id: 't7',
    name: 'FF Pro League: Winter',
    game: 'Free Fire',
    bannerImageUrl: 'https://picsum.photos/seed/ffwinter/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/fflogo/100/100',
    prizePool: 500000,
    viewersCount: 150000,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 30)),
    organizer: 'Garena',
    accentColorHex: '#FF2E2E',
  ),
  TournamentModel(
    id: 't8',
    name: 'Survivor Cup Season 4',
    game: 'Free Fire',
    bannerImageUrl: 'https://picsum.photos/seed/ffsurvivor/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/fflogo/100/100',
    prizePool: 100000,
    viewersCount: 45000,
    status: TournamentStatus.upcoming,
    startTime: DateTime.now().add(const Duration(hours: 24)),
    organizer: 'BlastX',
    accentColorHex: '#FFC93C',
  ),
  TournamentModel(
    id: 't4',
    name: 'CODM World Series',
    game: 'Call of Duty Mobile',
    bannerImageUrl: 'https://picsum.photos/seed/codm1/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/codmlogo/100/100',
    prizePool: 1000000,
    viewersCount: 54000,
    status: TournamentStatus.upcoming,
    startTime: DateTime.now().add(const Duration(hours: 5)),
    organizer: 'Activision',
    accentColorHex: '#9B5CFF',
  ),
  TournamentModel(
    id: 't5',
    name: 'Chess.com Titled Tuesday',
    game: 'Chess',
    bannerImageUrl: 'https://picsum.photos/seed/chess1/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/chesslogo/100/100',
    prizePool: 50000,
    viewersCount: 8200,
    status: TournamentStatus.upcoming,
    startTime: DateTime.now().add(const Duration(days: 1)),
    organizer: 'Chess.com',
    accentColorHex: '#3DDC84',
  ),
  TournamentModel(
    id: 't6',
    name: 'Clash of Clans Legends Cup',
    game: 'Clash of Clans',
    bannerImageUrl: 'https://picsum.photos/seed/coc1/800/450',
    gameLogoUrl: 'https://picsum.photos/seed/coclogo/100/100',
    prizePool: 150000,
    viewersCount: 31000,
    status: TournamentStatus.completed,
    startTime: DateTime.now().subtract(const Duration(days: 2)),
    organizer: 'Supercell',
    accentColorHex: '#FFC53D',
  ),
];