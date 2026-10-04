import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification_item_model.dart';

class NotificationNotifier extends StateNotifier<List<NotificationItemModel>> {
  NotificationNotifier()
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
        ]);

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
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItemModel>>((ref) {
  return NotificationNotifier();
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationProvider);
  return list.where((item) => !item.isRead).length;
});
