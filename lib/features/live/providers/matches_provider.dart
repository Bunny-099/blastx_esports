import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blastix_esports/core/services/notification_service.dart';
import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import '../../tournaments/data/repositories/tournament_repository.dart';
import '../data/models/tournament_matches_model.dart';

/// ============================================================
/// MATCHES PROVIDER
/// ============================================================
/// Family notifier supplying group-wise tournament matches response.
/// Integrated with RealTimeSyncManager for 10-second smart auto-refresh.
/// Retains existing data during background refreshes without flickering.
/// Triggers local notification when room credentials go live.
/// ============================================================

class MatchesNotifier
    extends StateNotifier<AsyncValue<TournamentMatchesResponse>> {
  MatchesNotifier(this._repository, this._syncManager, this._tournamentId)
      : super(const AsyncValue.loading()) {
    _initSync();
  }

  final TournamentRepository _repository;
  final RealTimeSyncManager _syncManager;
  final String _tournamentId;

  bool _notifiedRoomPublished = false;

  String get _taskKey => 'tournament_matches_$_tournamentId';

  void _initSync() {
    fetchMatches();
    _syncManager.register(
      key: _taskKey,
      fetcher: () => _repository.getTournamentMatches(_tournamentId),
      onChanged: (data) {
        if (mounted && data is TournamentMatchesResponse) {
          _checkRoomNotification(data);
          state = AsyncValue.data(data);
        }
      },
    );
  }

  void _checkRoomNotification(TournamentMatchesResponse response) {
    final userContext = response.userContext;
    if (userContext != null && userContext.isPublished && userContext.hasCredentials) {
      if (!_notifiedRoomPublished) {
        _notifiedRoomPublished = true;
        NotificationService.instance.showLocalNotification(
          title: '🔥 Room ID & Password Available',
          body:
              'Your room details for ${userContext.roundName} (${userContext.groupName}) are live! Tap to join.',
          payload: {
            'tournament_id': _tournamentId,
            'type': 'room_details_live',
          },
        );
      }
    }
  }

  Future<void> fetchMatches({bool isSilent = false}) async {
    if (!isSilent && !state.hasValue) {
      state = const AsyncValue.loading();
    }
    try {
      final response = await _repository.getTournamentMatches(_tournamentId);
      if (mounted) {
        _checkRoomNotification(response);
        state = AsyncValue.data(response);
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

final matchesProvider = StateNotifierProvider.family.autoDispose<
    MatchesNotifier, AsyncValue<TournamentMatchesResponse>, String>(
  (ref, tournamentId) {
    final repo = ref.watch(tournamentRepositoryProvider);
    final syncManager = ref.watch(realTimeSyncManagerProvider);
    return MatchesNotifier(repo, syncManager, tournamentId);
  },
);
