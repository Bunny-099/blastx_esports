import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tournaments/data/repositories/tournament_repository.dart';
import '../data/models/tournament_model.dart';

/// ============================================================
/// MATCHES PROVIDER
/// ============================================================
/// Family notifier supplying tournament matches.
/// Polls every 30 seconds only when any match is LIVE and tab is active.
/// ============================================================

class MatchesNotifier extends StateNotifier<AsyncValue<List<MatchModel>>> {
  MatchesNotifier(this._repository, this._tournamentId)
      : super(const AsyncValue.loading()) {
    fetchMatches();
  }

  final TournamentRepository _repository;
  final String _tournamentId;
  Timer? _pollingTimer;

  Future<void> fetchMatches({bool isSilent = false}) async {
    if (!isSilent && !state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final matches = await _repository.getMatches(_tournamentId);
      if (mounted) {
        state = AsyncValue.data(matches);
        _schedulePollingIfNeeded(matches);
      }
    } catch (err, stack) {
      if (mounted) {
        if (!isSilent || !state.hasValue) {
          state = AsyncValue.error(err, stack);
        }
      }
    }
  }

  void _schedulePollingIfNeeded(List<MatchModel> matches) {
    _pollingTimer?.cancel();
    final hasLiveMatch = matches.any((m) => m.isLive);
    if (hasLiveMatch) {
      _pollingTimer = Timer(const Duration(seconds: 30), () {
        if (mounted) {
          fetchMatches(isSilent: true);
        }
      });
    }
  }

  Future<void> refresh() async {
    await fetchMatches(isSilent: false);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

final matchesProvider = StateNotifierProvider.family
    .autoDispose<MatchesNotifier, AsyncValue<List<MatchModel>>, String>(
  (ref, tournamentId) {
    final repo = ref.watch(tournamentRepositoryProvider);
    return MatchesNotifier(repo, tournamentId);
  },
);
