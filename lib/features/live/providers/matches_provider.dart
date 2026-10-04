import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import '../../tournaments/data/repositories/tournament_repository.dart';
import '../data/models/tournament_model.dart';

/// ============================================================
/// MATCHES PROVIDER
/// ============================================================
/// Family notifier supplying tournament matches.
/// Integrated with RealTimeSyncManager for 10-second smart auto-refresh.
/// Retains existing data during background refreshes without flickering.
/// ============================================================

class MatchesNotifier extends StateNotifier<AsyncValue<List<MatchModel>>> {
  MatchesNotifier(this._repository, this._syncManager, this._tournamentId)
      : super(const AsyncValue.loading()) {
    _initSync();
  }

  final TournamentRepository _repository;
  final RealTimeSyncManager _syncManager;
  final String _tournamentId;

  String get _taskKey => 'matches_$_tournamentId';

  void _initSync() {
    fetchMatches();
    _syncManager.register(
      key: _taskKey,
      fetcher: () => _repository.getMatches(_tournamentId),
      onChanged: (data) {
        if (mounted && data is List) {
          final matches = data.map((e) => e is MatchModel ? e : MatchModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          state = AsyncValue.data(matches);
        }
      },
    );
  }

  Future<void> fetchMatches({bool isSilent = false}) async {
    if (!isSilent && !state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final matches = await _repository.getMatches(_tournamentId);
      if (mounted) {
        state = AsyncValue.data(matches);
      }
    } catch (err, stack) {
      if (mounted) {
        if (!isSilent || !state.hasValue) {
          state = AsyncValue.error(err, stack);
        }
      }
    }
  }

  Future<void> refresh() async {
    await fetchMatches(isSilent: false);
  }

  @override
  void dispose() {
    _syncManager.unregister(_taskKey);
    super.dispose();
  }
}

final matchesProvider = StateNotifierProvider.family
    .autoDispose<MatchesNotifier, AsyncValue<List<MatchModel>>, String>(
  (ref, tournamentId) {
    final repo = ref.watch(tournamentRepositoryProvider);
    final syncManager = ref.watch(realTimeSyncManagerProvider);
    return MatchesNotifier(repo, syncManager, tournamentId);
  },
);
