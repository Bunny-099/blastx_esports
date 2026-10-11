/// Model representing an in-app notification entry in BlastiX Esports
class NotificationItemModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'tournament', 'wallet', 'match', 'squad', 'team', 'leaderboard', 'system'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload;

  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? payload,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
    };
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'system',
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
    );
  }

  factory NotificationItemModel.fromPushData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final rawType = data['type']?.toString().toLowerCase().trim() ?? 'system';
    final parsedTitle = title ?? data['title']?.toString() ?? 'BlastiX Notification';
    final parsedBody = body ?? data['body']?.toString() ?? '';
    final id = data['notificationId']?.toString() ??
        data['notification_id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();

    String category;
    switch (rawType) {
      case 'room_published':
      case 'room_details_live':
      case 'group_allocated':
      case 'schedule_changed':
      case 'match_reminder':
        category = 'match';
        break;
      case 'squad_invite':
      case 'roster_approval_request':
      case 'roster_approval_response':
        category = 'squad';
        break;
      case 'join_request':
      case 'join_approved':
      case 'join_rejected':
      case 'member_removed':
        category = 'team';
        break;
      case 'payment_success':
      case 'payment_failed':
      case 'registration_submitted':
        category = 'wallet';
        break;
      case 'result_published':
      case 'qualified':
      case 'eliminated':
        category = 'leaderboard';
        break;
      case 'slot_confirmed':
      case 'waitlisted':
      case 'waitlist_promoted':
      case 'registration_closing':
      case 'registration_closed':
      case 'registration_reopened':
      case 'deadline_extended':
      case 'wildcard_open':
      case 'wildcard_selected':
      case 'lan_instructions':
      case 'tournament':
        category = 'tournament';
        break;
      default:
        category = 'system';
        break;
    }

    return NotificationItemModel(
      id: id,
      title: parsedTitle,
      body: parsedBody,
      type: category,
      timestamp: DateTime.now(),
      isRead: false,
      payload: data,
    );
  }
}
