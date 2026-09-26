import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/tournaments/data/repositories/tournament_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// LIVE PROVIDER — Free Fire Exclusive Edition
/// ============================================================
/// Riverpod providers that supply Free Fire tournament data to UI.
/// Fetches real tournaments from backend API with game='Free Fire'.
/// ============================================================

/// Async provider for backend tournaments API
final apiTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  try {
    final repo = ref.watch(tournamentRepositoryProvider);
    final list = await repo.getTournaments(limit: 50, game: 'Free Fire');
    // Ensure only Free Fire tournaments are returned
    final ffTournaments = list
        .where((t) => t.game.trim().toLowerCase().contains('free fire'))
        .toList();
    return ffTournaments;
  } catch (e) {
    // Return empty list on network error
    return const [];
  }
});

/// Main provider - list of all live/upcoming Free Fire tournaments.
final liveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final apiResult = ref.watch(apiTournamentsProvider);
  return apiResult.when(
    data: (list) => list.isNotEmpty ? list : _freeFireMockTournaments,
    loading: () => _freeFireMockTournaments,
    error: (err, stack) => _freeFireMockTournaments,
  );
});

/// Official tournaments (Garena / Free Fire)
final officialTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final all = ref.watch(liveTournamentsProvider);
  final official = all.where((t) =>
    t.organizer.toLowerCase().contains('garena') ||
    t.game.toLowerCase().contains('free fire')
  ).toList();
  return official.isNotEmpty ? official : all;
});

/// BlastIX (App) tournaments
final appTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final all = ref.watch(liveTournamentsProvider);
  final appTourneys = all.where((t) =>
    t.organizer.toLowerCase().contains('blastix') ||
    t.organizer.toLowerCase().contains('blastx')
  ).toList();
  return appTourneys.isNotEmpty ? appTourneys : all;
});

/// BlastIX Live tournaments
final appLiveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final appTournaments = ref.watch(appTournamentsProvider);
  final live = appTournaments.where((t) => t.isLive).toList();
  return live.isNotEmpty ? live : appTournaments;
});

/// BlastIX Upcoming tournaments
final appUpcomingTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final appTournaments = ref.watch(appTournamentsProvider);
  return appTournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
});

/// Family provider - fetch a single tournament by its ID.
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
final tournamentSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered list based on search query - what the UI actually renders.
final filteredTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(tournamentSearchQueryProvider).trim().toLowerCase();
  final all = ref.watch(liveTournamentsProvider);

  if (query.isEmpty) return all;

  return all.where((t) {
    return t.name.toLowerCase().contains(query) ||
        t.game.toLowerCase().contains(query) ||
        t.organizer.toLowerCase().contains(query) ||
        t.mapName.toLowerCase().contains(query);
  }).toList();
});

/// Simple search query provider for upcoming tournaments.
final upcomingSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered list of upcoming tournaments based on search query.
final filteredUpcomingTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(upcomingSearchQueryProvider).trim().toLowerCase();
  final all = ref.watch(appUpcomingTournamentsProvider);

  if (query.isEmpty) return all;

  return all.where((t) {
    return t.name.toLowerCase().contains(query) ||
        t.game.toLowerCase().contains(query) ||
        t.organizer.toLowerCase().contains(query) ||
        t.mapName.toLowerCase().contains(query);
  }).toList();
});

/// Filtered list of app live tournaments based on search query.
final filteredAppLiveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(upcomingSearchQueryProvider).trim().toLowerCase();
  final all = ref.watch(appLiveTournamentsProvider);

  if (query.isEmpty) return all;

  return all.where((t) {
    return t.name.toLowerCase().contains(query) ||
        t.game.toLowerCase().contains(query) ||
        t.organizer.toLowerCase().contains(query) ||
        t.mapName.toLowerCase().contains(query);
  }).toList();
});

/// Filtered list of official tournaments based on search query.
final filteredOfficialTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(tournamentSearchQueryProvider).trim().toLowerCase();
  final all = ref.watch(officialTournamentsProvider);

  if (query.isEmpty) return all;

  return all.where((t) {
    return t.name.toLowerCase().contains(query) ||
        t.game.toLowerCase().contains(query) ||
        t.organizer.toLowerCase().contains(query) ||
        t.mapName.toLowerCase().contains(query);
  }).toList();
});

/// ------------------------------------------------------------
/// FREE FIRE ONLY MOCK DATA (Fallback for offline preview)
/// ------------------------------------------------------------
final List<TournamentModel> _freeFireMockTournaments = [
  TournamentModel(
    id: 'ff_live_1',
    name: 'Free Fire Max India Cup',
    game: 'Free Fire',
    bannerImageUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?auto=format&fit=crop&w=1200&q=80',
    gameLogoUrl: 'https://picsum.photos/seed/fflogo/100/100',
    prizePool: 300000,
    viewersCount: 210000,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(hours: 2)),
    organizer: 'Garena',
    accentColorHex: '#FF6B00',
    mode: 'SQUAD',
    mapName: 'Bermuda',
    matchType: 'BATTLE_ROYALE',
    teams: [
      const TeamModel(
          id: 'ff_team_1',
          name: 'Total Gaming Esports',
          logoUrl: 'https://picsum.photos/seed/tg/100/100',
          score: 54,
          status: TeamStatus.winning),
      const TeamModel(
          id: 'ff_team_2',
          name: 'Orangutan Elite',
          logoUrl: 'https://picsum.photos/seed/og/100/100',
          score: 48,
          status: TeamStatus.playing),
    ],
    matches: [
      MatchModel(
        id: 'ff_match_1',
        tournamentId: 'ff_live_1',
        round: 'Grand Finals - Match 3',
        teamA: const TeamModel(
            id: 'ff_team_1', name: 'Total Gaming', logoUrl: '', score: 18),
        teamB: const TeamModel(
            id: 'ff_team_2', name: 'Orangutan', logoUrl: '', score: 14),
        matchTime: DateTime.now(),
        status: MatchStatus.live,
        mapOrMode: 'Bermuda (Squad)',
      ),
    ],
  ),
  TournamentModel(
    id: 'ff_live_2',
    name: 'FF Pro League: Winter Championship',
    game: 'Free Fire',
    bannerImageUrl: 'https://images.unsplash.com/photo-1511512578047-dfb367046420?auto=format&fit=crop&w=1200&q=80',
    gameLogoUrl: 'https://picsum.photos/seed/fflogo/100/100',
    prizePool: 500000,
    viewersCount: 150000,
    status: TournamentStatus.live,
    startTime: DateTime.now().subtract(const Duration(minutes: 30)),
    organizer: 'Garena',
    accentColorHex: '#FF2E2E',
    mode: 'SQUAD',
    mapName: 'Purgatory',
    matchType: 'BATTLE_ROYALE',
  ),
  TournamentModel(
    id: 'ff_upcoming_1',
    name: 'Free Fire Survivor Cup Season 4',
    game: 'Free Fire',
    bannerImageUrl: 'https://images.unsplash.com/photo-1538481199705-c710c4e965fc?auto=format&fit=crop&w=1200&q=80',
    gameLogoUrl: 'https://picsum.photos/seed/fflogo/100/100',
    prizePool: 100000,
    viewersCount: 45000,
    status: TournamentStatus.upcoming,
    startTime: DateTime.now().add(const Duration(hours: 24)),
    organizer: 'BlastIX',
    accentColorHex: '#FFC93C',
    mode: 'DUO',
    mapName: 'Kalahari',
    matchType: 'BATTLE_ROYALE',
  ),
];
