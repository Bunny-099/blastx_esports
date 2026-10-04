import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/live/data/models/leaderboard_model.dart';
import 'package:blastix_esports/features/tournaments/data/repositories/tournament_repository.dart';

/// ============================================================
/// LEADERBOARD PROVIDER — Real-time Free Fire Standings
/// ============================================================
/// AsyncNotifier provider parameterized by tournamentId.
/// Integrated with RealTimeSyncManager for 10-second smart auto-refresh.
/// Retains previous data during background refreshes to prevent UI flickering.
/// ============================================================

class LeaderboardNotifier
    extends FamilyAsyncNotifier<LeaderboardResponse, String> {
  DateTime? _lastRefreshedAt;

  DateTime? get lastRefreshedAt => _lastRefreshedAt;

  String get _taskKey => 'leaderboard_$arg';

  @override
  FutureOr<LeaderboardResponse> build(String arg) async {
    final syncManager = ref.watch(realTimeSyncManagerProvider);

    ref.onDispose(() {
      syncManager.unregister(_taskKey);
    });

    syncManager.register(
      key: _taskKey,
      fetcher: () => _fetch(arg),
      onChanged: (data) {
        if (data is LeaderboardResponse) {
          _lastRefreshedAt = DateTime.now();
          state = AsyncData(data);
        }
      },
    );

    final data = await _fetch(arg);
    _lastRefreshedAt = DateTime.now();
    return data;
  }

  Future<LeaderboardResponse> _fetch(String tournamentId, {String? round}) async {
    final repo = ref.read(tournamentRepositoryProvider);
    return await repo.getLeaderboardResponse(tournamentId, round: round);
  }

  /// Compatibility method for UI tab visibility
  void setTabVisibility(bool isVisible) {}

  /// Explicit user pull-to-refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final newData = await _fetch(arg);
      _lastRefreshedAt = DateTime.now();
      state = AsyncData(newData);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final leaderboardProvider =
    AsyncNotifierProvider.family<LeaderboardNotifier, LeaderboardResponse, String>(
  LeaderboardNotifier.new,
);
