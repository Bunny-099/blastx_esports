import 'package:flutter/foundation.dart';

/// ============================================================
/// ROOM DETAILS MODEL
/// Holds sensitive custom room credentials (Room ID & Password)
/// ============================================================

@immutable
class RoomDetails {
  final String roomId;
  final String password;
  final DateTime? visibleFrom;

  const RoomDetails({
    required this.roomId,
    required this.password,
    this.visibleFrom,
  });

  factory RoomDetails.fromJson(Map<String, dynamic> json) {
    final rawVisibleFrom = json['visible_from'] ?? json['visibleFrom'] ?? json['reveal_at'] ?? json['revealAt'];
    final parsedVisibleFrom = rawVisibleFrom != null ? DateTime.tryParse(rawVisibleFrom.toString()) : null;

    final rawRoomId = json['room_id'] ?? json['roomId'] ?? json['room_code'] ?? '';
    final rawPassword = json['password'] ?? json['room_password'] ?? json['roomPassword'] ?? '';

    return RoomDetails(
      roomId: rawRoomId.toString(),
      password: rawPassword.toString(),
      visibleFrom: parsedVisibleFrom,
    );
  }

  Map<String, dynamic> toJson() => {
    'room_id': roomId,
    'password': password,
    if (visibleFrom != null) 'visible_from': visibleFrom!.toIso8601String(),
  };
}

/// ============================================================
/// ROOM DETAILS SEALED STATE
/// Represents the result state of fetching custom room details
/// ============================================================

sealed class RoomDetailsState {
  const RoomDetailsState();
}

/// Room ID and password are available to the registered player
final class RoomDetailsAvailable extends RoomDetailsState {
  final RoomDetails roomDetails;
  const RoomDetailsAvailable(this.roomDetails);
}

/// User is not registered in this tournament
final class RoomDetailsNotRegistered extends RoomDetailsState {
  const RoomDetailsNotRegistered();
}

/// Registered, but room details are locked until revealAt timestamp
final class RoomDetailsNotYetAvailable extends RoomDetailsState {
  final DateTime? revealAt;
  const RoomDetailsNotYetAvailable({this.revealAt});
}

/// Request failed with an unexpected error
final class RoomDetailsError extends RoomDetailsState {
  final String message;
  const RoomDetailsError(this.message);
}
