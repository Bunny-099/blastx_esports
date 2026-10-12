import 'package:flutter/foundation.dart';

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

    return RoomCredentialsModel(
      roomId: data['room_id']?.toString() ?? data['roomId']?.toString() ?? '',
      roomPassword: data['room_password']?.toString() ?? data['roomPassword']?.toString() ?? '',
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
    final msg = switch (cleanCode) {
      'NOT_PLAYING_MEMBER' => 'Only the Playing 4 can see room details.',
      'ELIMINATED' => 'Your team is eliminated from this tournament.',
      'NOT_IN_THIS_MATCH' => 'Your team is not in this match group.',
      'NOT_REGISTERED' => 'You are not registered in this tournament.',
      _ => customMsg ?? 'You are not eligible to view this room.',
    };
    return RoomCredentialsNotEligible(code: cleanCode, userMessage: msg);
  }
}

/// Error state for network / server error
final class RoomCredentialsError extends RoomCredentialsState {
  final String message;
  const RoomCredentialsError(this.message);
}
