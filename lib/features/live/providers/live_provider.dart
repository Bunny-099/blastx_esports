import 'package:blastix_esports/features/live/data/models/room_details_model.dart';
import 'package:blastix_esports/features/live/data/models/team_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/tournaments/data/repositories/tournament_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// LIVE PROVIDER — Dedicated Free Fire Live & BlastX Esports Edition
/// ============================================================
/// Riverpod providers that supply Free Fire Live and BlastX Esports
/// tournament data directly from dedicated API endpoints.
/// ============================================================

/// Status filter enum for live screen filter chips
enum TournamentStatusFilter { all, live, upcoming, completed }

/// Selected status filter provider (defaults to `live`)
final statusFilterProvider = StateProvider<TournamentStatusFilter>(
  (ref) => TournamentStatusFilter.live,
);

/// Search query provider for live screen tournaments
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Alias for backward compatibility with capsule search bar
final tournamentSearchQueryProvider = searchQueryProvider;

// ── 1. FREE FIRE LIVE SECTION PROVIDERS ──

/// Async provider for dedicated Free Fire Live API (`/free-fire-live`)
final apiTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final filter = ref.watch(statusFilterProvider);
  final statusParam = filter == TournamentStatusFilter.all ? null : filter.name.toUpperCase();
  final list = await repo.getFreeFireLiveTournaments(
    limit: 50,
    status: statusParam,
  );
  return list;
});

/// Main provider - list of all Free Fire Live tournaments returned from Free Fire Live API endpoint
final liveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final apiResult = ref.watch(apiTournamentsProvider);
  return apiResult.valueOrNull ?? const [];
});

/// Official tournaments (Free Fire Live section)
final officialTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return ref.watch(liveTournamentsProvider);
});

/// Counts of Free Fire Live tournaments per status category for filter chips
final tournamentCountsProvider = Provider<Map<TournamentStatusFilter, int>>((ref) {
  final all = ref.watch(officialTournamentsProvider);
  return {
    TournamentStatusFilter.all: all.length,
    TournamentStatusFilter.live: all.where((t) => t.status == TournamentStatus.live).length,
    TournamentStatusFilter.upcoming: all.where((t) => t.status == TournamentStatus.upcoming).length,
    TournamentStatusFilter.completed: all.where((t) => t.status == TournamentStatus.completed).length,
  };
});

/// Filtered list applying status filter and search query on Free Fire Live tournaments
final visibleTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(statusFilterProvider);
  final all = ref.watch(officialTournamentsProvider);

  return all.where((t) {
    // Apply status filter
    final matchesStatus = switch (statusFilter) {
      TournamentStatusFilter.all => true,
      TournamentStatusFilter.live => t.status == TournamentStatus.live,
      TournamentStatusFilter.upcoming => t.status == TournamentStatus.upcoming,
      TournamentStatusFilter.completed => t.status == TournamentStatus.completed,
    };
    if (!matchesStatus) return false;

    // Apply search query filter (matches title/name, organizer, or map)
    if (query.isEmpty) return true;
    final nameMatch = t.displayTitle.toLowerCase().contains(query) || t.name.toLowerCase().contains(query);
    final organizerMatch = t.organizer.toLowerCase().contains(query);
    final mapMatch = t.mapName.toLowerCase().contains(query);
    return nameMatch || organizerMatch || mapMatch;
  }).toList();
});

/// Alias for backward compatibility
final filteredOfficialTournamentsProvider = visibleTournamentsProvider;

// ── 2. BLASTX ESPORTS TOURNAMENTS SECTION PROVIDERS ──

/// Async provider for dedicated BlastX LIVE Tournaments API (`/tournaments?status=LIVE`)
final blastxLiveTournamentsApiProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final list = await repo.getTournaments(
    limit: 50,
    status: 'LIVE',
  );
  return list;
});

/// Async provider for dedicated BlastX UPCOMING Tournaments API (`/tournaments?status=UPCOMING`)
final blastxUpcomingTournamentsApiProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final list = await repo.getTournaments(
    limit: 50,
    status: 'UPCOMING',
  );
  return list;
});

/// Async provider for dedicated BlastX Tournaments API (`/tournaments`)
final blastxTournamentsApiProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final list = await repo.getTournaments(
    limit: 50,
  );
  return list;
});

/// BlastX E-Sports tournaments list
final appTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final apiResult = ref.watch(blastxTournamentsApiProvider);
  return apiResult.valueOrNull ?? const [];
});

/// BlastX Live tournaments
final appLiveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final liveResult = ref.watch(blastxLiveTournamentsApiProvider);
  final liveList = liveResult.valueOrNull;
  if (liveList != null && liveList.isNotEmpty) return liveList;
  final appTournaments = ref.watch(appTournamentsProvider);
  return appTournaments.where((t) => t.isLive).toList();
});

/// BlastX Upcoming tournaments
final appUpcomingTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final upcomingResult = ref.watch(blastxUpcomingTournamentsApiProvider);
  final upcomingList = upcomingResult.valueOrNull;
  if (upcomingList != null && upcomingList.isNotEmpty) return upcomingList;
  final appTournaments = ref.watch(appTournamentsProvider);
  return appTournaments.where((t) => t.status == TournamentStatus.upcoming).toList();
});

/// Simple search query provider for upcoming tournaments.
final upcomingSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered list of upcoming BlastX tournaments based on search query.
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

/// Filtered list of BlastX live tournaments based on search query.
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

// ── 3. COMMON LOOKUP & ROOM DETAILS PROVIDERS ──

/// Async family provider - fetch / refresh a single tournament by ID directly from backend API
final tournamentDetailApiProvider = FutureProvider.family<TournamentModel, String>((ref, id) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return await repo.getTournamentDetail(id);
});

/// Family provider - fetch a single tournament by its ID (prefers fresh detail API data)
final tournamentByIdProvider = Provider.family<TournamentModel?, String>((ref, id) {
  final detailResult = ref.watch(tournamentDetailApiProvider(id));
  final fetched = detailResult.valueOrNull;
  if (fetched != null) return fetched;

  final ffList = ref.watch(liveTournamentsProvider);
  try {
    return ffList.firstWhere((t) => t.id == id);
  } catch (_) {}

  final bxList = ref.watch(appTournamentsProvider);
  try {
    return bxList.firstWhere((t) => t.id == id);
  } catch (_) {}

  return null;
});

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

/// Family provider for fetching RoomDetailsState for a given tournament ID
final roomDetailsProvider = FutureProvider.family<RoomDetailsState, String>((ref, tournamentId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final tournament = ref.watch(tournamentByIdProvider(tournamentId));
  return repo.getRoomDetailsState(tournamentId, tournament: tournament);
});

/// Family provider for fetching registered teams list for a tournament
final registeredTeamsProvider = FutureProvider.family<List<TournamentTeamModel>, String>((ref, tournamentId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getRegisteredTeams(tournamentId);
});

