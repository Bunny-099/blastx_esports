import 'package:blastix_esports/features/live/data/models/room_details_model.dart';
import 'package:blastix_esports/features/live/data/models/tournament_model.dart';
import 'package:blastix_esports/features/tournaments/data/repositories/tournament_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ============================================================
/// LIVE PROVIDER — Free Fire Exclusive Edition
/// ============================================================
/// Riverpod providers that supply Free Fire tournament data to UI.
/// Fetches real tournaments from backend API with game='Free Fire'.
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

/// Async provider for backend tournaments API
final apiTournamentsProvider = FutureProvider<List<TournamentModel>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final filter = ref.watch(statusFilterProvider);
  final statusParam = filter == TournamentStatusFilter.all ? null : filter.name.toUpperCase();
  final list = await repo.getTournaments(
    limit: 50,
    game: 'Free Fire',
    status: statusParam,
  );
  // Light client-side safety check to ensure Free Fire tournaments
  return list
      .where((t) => t.game.isEmpty || t.game.trim().toLowerCase().contains('free fire'))
      .toList();
});

/// Main provider - list of all live/upcoming/completed Free Fire tournaments.
final liveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final apiResult = ref.watch(apiTournamentsProvider);
  return apiResult.valueOrNull ?? const [];
});

/// Official tournaments (Garena / Free Fire)
final officialTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return ref.watch(liveTournamentsProvider);
});

/// Counts of tournaments per status category for filter chips
/// TODO(backend): remove mock client-side count computation once backend supplies aggregated counts
final tournamentCountsProvider = Provider<Map<TournamentStatusFilter, int>>((ref) {
  final all = ref.watch(officialTournamentsProvider);
  return {
    TournamentStatusFilter.all: all.length,
    TournamentStatusFilter.live: all.where((t) => t.status == TournamentStatus.live).length,
    TournamentStatusFilter.upcoming: all.where((t) => t.status == TournamentStatus.upcoming).length,
    TournamentStatusFilter.completed: all.where((t) => t.status == TournamentStatus.completed).length,
  };
});

/// Filtered list applying BOTH status filter and case-insensitive search query (title, organizer, map)
/// TODO(backend): remove mock client-side filtering once backend handles q & status query parameters directly
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
    final nameMatch = t.name.toLowerCase().contains(query);
    final organizerMatch = t.organizer.toLowerCase().contains(query);
    final mapMatch = t.mapName.toLowerCase().contains(query);
    return nameMatch || organizerMatch || mapMatch;
  }).toList();
});

/// Alias for backward compatibility
final filteredOfficialTournamentsProvider = visibleTournamentsProvider;

/// BlastIX (App) tournaments
final appTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final all = ref.watch(liveTournamentsProvider);
  return all.where((t) =>
    t.organizer.toLowerCase().contains('blastix') ||
    t.organizer.toLowerCase().contains('blastx')
  ).toList();
});

/// BlastIX Live tournaments
final appLiveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final appTournaments = ref.watch(appTournamentsProvider);
  return appTournaments.where((t) => t.isLive).toList();
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

/// Family provider for fetching RoomDetailsState for a given tournament ID
final roomDetailsProvider = FutureProvider.family<RoomDetailsState, String>((ref, tournamentId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final tournament = ref.watch(tournamentByIdProvider(tournamentId));
  return repo.getRoomDetailsState(tournamentId, tournament: tournament);
});
