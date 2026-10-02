import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blastix_esports/features/live/data/models/leaderboard_model.dart';
import 'package:blastix_esports/features/tournaments/data/repositories/tournament_repository.dart';
import 'live_provider.dart';

/// ============================================================
/// LEADERBOARD PROVIDER — Real-time Free Fire Standings
/// ============================================================
/// AsyncNotifier provider parameterized by tournamentId.
/// Supports background polling every 20s when tournament is LIVE and tab is visible.
/// Retains previous data during background refreshes to prevent UI flickering.
/// ============================================================

class LeaderboardNotifier
    extends FamilyAsyncNotifier<LeaderboardResponse, String> {
  Timer? _pollingTimer;
  bool _isTabVisible = true;
  DateTime? _lastRefreshedAt;

  DateTime? get lastRefreshedAt => _lastRefreshedAt;
  bool get isPollingActive => _pollingTimer != null && _pollingTimer!.isActive;

  @override
  FutureOr<LeaderboardResponse> build(String arg) async {
    ref.onDispose(() {
      _stopPolling();
    });

    final data = await _fetch(arg);
    _lastRefreshedAt = DateTime.now();

    _updatePollingStatus(arg);
    return data;
  }

  Future<LeaderboardResponse> _fetch(String tournamentId, {String? round}) async {
    final repo = ref.read(tournamentRepositoryProvider);
    return await repo.getLeaderboardResponse(tournamentId, round: round);
  }

  /// Sets whether the Leaderboard tab is currently visible in UI
  void setTabVisibility(bool isVisible) {
    if (_isTabVisible == isVisible) return;
    _isTabVisible = isVisible;
    _updatePollingStatus(arg);
  }

  void _updatePollingStatus(String tournamentId) {
    final tournament = ref.read(tournamentByIdProvider(tournamentId));
    final isLive = tournament?.isLive ?? false;

    if (isLive && _isTabVisible) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      pollRefresh();
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Background poll refresh that keeps current data visible without causing shimmer/flicker
  Future<void> pollRefresh() async {
    try {
      final newData = await _fetch(arg);
      _lastRefreshedAt = DateTime.now();
      state = AsyncData(newData);
    } catch (_) {
      // Maintain previous data on background refresh errors
    }
  }

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
