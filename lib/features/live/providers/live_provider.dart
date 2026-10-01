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
  final repo = ref.watch(tournamentRepositoryProvider);
  final list = await repo.getTournaments(limit: 50, game: 'Free Fire');
  // Light client-side safety check to ensure Free Fire tournaments
  return list
      .where((t) => t.game.isEmpty || t.game.trim().toLowerCase().contains('free fire'))
      .toList();
});

/// Main provider - list of all live/upcoming Free Fire tournaments.
final liveTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  final apiResult = ref.watch(apiTournamentsProvider);
  return apiResult.valueOrNull ?? const [];
});

/// Official tournaments (Garena / Free Fire)
final officialTournamentsProvider = Provider<List<TournamentModel>>((ref) {
  return ref.watch(liveTournamentsProvider);
});

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
