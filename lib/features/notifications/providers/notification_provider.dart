import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import '../data/models/notification_item_model.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItemModel>> {
  final RealTimeSyncManager? _syncManager;

  NotificationNotifier([this._syncManager])
      : super([
          NotificationItemModel(
            id: '1',
            title: '🔥 Room ID & Password Available',
            body: 'Room details for Free Fire Solo Clutch Tournament #204 are live!',
            type: 'tournament',
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            isRead: false,
          ),
          NotificationItemModel(
            id: '2',
            title: '💰 Wallet Credited',
            body: '₹500 Prize Money credited to your BlastX wallet.',
            type: 'wallet',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: false,
          ),
          NotificationItemModel(
            id: '3',
            title: '🎉 Welcome to BlastiX Arena!',
            body: 'Complete your gamer profile to unlock custom challenges and rewards.',
            type: 'system',
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            isRead: true,
          ),
        ]) {
    _initSync();
  }

  void _initSync() {
    _syncManager?.register(
      key: 'notifications',
      fetcher: () async => state.map((e) => e.toJson()).toList(),
      onChanged: (data) {
        if (data is List) {
          final list = data
              .map((e) => NotificationItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          state = list;
        }
      },
    );
  }

  void addNotification(NotificationItemModel item) {
    state = [item, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final item in state)
        if (item.id == id) item.copyWith(isRead: true) else item
    ];
  }

  void markAllAsRead() {
    state = [for (final item in state) item.copyWith(isRead: true)];
  }

  void removeNotification(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearAll() {
    state = [];
  }

  @override
  void dispose() {
    _syncManager?.unregister('notifications');
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItemModel>>((ref) {
  final syncManager = ref.watch(realTimeSyncManagerProvider);
  return NotificationNotifier(syncManager);
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationProvider);
  return list.where((item) => !item.isRead).length;
});
