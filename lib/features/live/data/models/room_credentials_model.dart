/// Room credentials model holding roomId and password
class RoomCredentialsModel {
  final String roomId;
  final String roomPassword;
  final DateTime? visibleFrom;
  final DateTime? scheduledAt;

  const RoomCredentialsModel({
    required this.roomId,
    required this.roomPassword,
    this.visibleFrom,
    this.scheduledAt,
  });

  factory RoomCredentialsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final rawRoomId = data['room_id'] ?? data['roomId'] ?? data['room_code'] ?? data['roomCode'] ?? data['id'];
    final rawPassword = data['room_password'] ?? data['roomPassword'] ?? data['password'] ?? data['pass'] ?? data['room_pass'] ?? data['roomPass'];

    return RoomCredentialsModel(
      roomId: rawRoomId?.toString() ?? '',
      roomPassword: rawPassword?.toString() ?? '',
      visibleFrom: parseDate(data['visible_from'] ?? data['visibleFrom']),
      scheduledAt: parseDate(data['scheduled_at'] ?? data['scheduledAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'room_id': roomId,
        'room_password': roomPassword,
        'visible_from': visibleFrom?.toIso8601String(),
        'scheduled_at': scheduledAt?.toIso8601String(),
      };
}

/// Sealed state for Room Credentials response
sealed class RoomCredentialsState {
  const RoomCredentialsState();
}

/// Successfully fetched credentials
final class RoomCredentialsAvailable extends RoomCredentialsState {
  final RoomCredentialsModel credentials;
  const RoomCredentialsAvailable(this.credentials);
}

/// Room details not yet available (HIDDEN / 425 ROOM_NOT_AVAILABLE)
final class RoomCredentialsNotYetAvailable extends RoomCredentialsState {
  final DateTime? revealAt;
  final String message;
  const RoomCredentialsNotYetAvailable({
    this.revealAt,
    this.message = 'Room details will be published soon.',
  });
}

/// Not eligible to view room details (NOT_PLAYING_MEMBER, ELIMINATED, NOT_IN_THIS_MATCH, NOT_REGISTERED)
final class RoomCredentialsNotEligible extends RoomCredentialsState {
  final String code;
  final String userMessage;

  const RoomCredentialsNotEligible({
    required this.code,
    required this.userMessage,
  });

  factory RoomCredentialsNotEligible.fromCode(String code, {DateTime? revealAt, String? customMsg}) {
    final cleanCode = code.toUpperCase().trim();
    if (customMsg != null && customMsg.trim().isNotEmpty) {
      return RoomCredentialsNotEligible(code: cleanCode, userMessage: customMsg);
    }
    final msg = switch (cleanCode) {
      'NOT_PLAYING_MEMBER' => 'Only the Playing 4 can see room details.',
      'ELIMINATED' => 'Your team is eliminated from this tournament.',
      'NOT_IN_THIS_MATCH' => 'Your team is not in this match group.',
      'NOT_REGISTERED' => 'You are not registered in this tournament.',
      _ => 'You are not eligible to view this room.',
    };
    return RoomCredentialsNotEligible(code: cleanCode, userMessage: msg);
  }
}

/// Error state for network / server error
final class RoomCredentialsError extends RoomCredentialsState {
  final String message;
  const RoomCredentialsError(this.message);
}
