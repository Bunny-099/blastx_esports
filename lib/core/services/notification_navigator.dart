import 'package:flutter/material.dart';
import '../router/app_router.dart';
import '../transitions/fire_page_route.dart';
import '../../features/live/presentation/team/tournament_match_room_screen.dart';
import '../../features/live/presentation/team/team_lobby_screen.dart';
import '../../features/live/presentation/tournament_detail_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/squad/presentation/my_squad_screen.dart';

/// Central Notification Tap & Deep Link Navigator
/// Maps backend notification contract types to application screens safely.
class NotificationNavigator {
  NotificationNavigator._();

  static Map<String, dynamic>? _pendingPayload;
  static final Set<String> _processedIds = {};

  /// Store payload if app was launched before router or auth check was ready
  static void setPendingPayload(Map<String, dynamic> data) {
    _pendingPayload = data;
  }

  /// Process pending notification payload once router & auth session are ready
  static void processPendingPayloadIfAny({required bool isLoggedIn}) {
    if (_pendingPayload != null) {
      final payload = Map<String, dynamic>.from(_pendingPayload!);
      _pendingPayload = null;
      handleTap(payload, isLoggedIn: isLoggedIn);
    }
  }

  /// Central handler for notification tap events across all 4 entry points
  static void handleTap(Map<String, dynamic> rawData, {bool isLoggedIn = true}) {
    if (rawData.isEmpty) return;

    // FCM payload data values are strings. Parse them safely into strings.
    final data = <String, dynamic>{};
    rawData.forEach((key, value) {
      data[key] = value?.toString();
    });

    // Deduplication check to prevent double handling from multiple listeners
    final String dedupeId = (data['notificationId'] ??
            data['notification_id'] ??
            data['messageId'] ??
            data['matchId'] ??
            data.toString())
        .toString();

    if (_processedIds.contains(dedupeId)) {
      debugPrint("Notification tap ignored: duplicate notification ID ($dedupeId)");
      return;
    }
    _processedIds.add(dedupeId);
    if (_processedIds.length > 50) {
      _processedIds.remove(_processedIds.first);
    }

    if (!isLoggedIn) {
      debugPrint("User not logged in. Storing notification payload until auth completed.");
      _pendingPayload = data;
      return;
    }

    final navState = AppRouter.navigatorKey.currentState;
    if (navState == null) {
      debugPrint("AppRouter navigator key state not ready yet. Storing notification payload.");
      _pendingPayload = data;
      return;
    }

    final type = data['type']?.toString().toLowerCase().trim() ?? '';
    final tournamentId = data['tournamentId']?.toString() ?? data['tournament_id']?.toString();

    debugPrint("NotificationNavigator handling tap -> type: '$type', tid: '$tournamentId'");

    try {
      switch (type) {
        case 'room_credentials_released':
        case 'room_released':
        case 'room_published':
        case 'room_details_live':
        case 'match_starting_soon':
        case 'match_reminder':
          if (tournamentId != null && tournamentId.isNotEmpty) {
            navState.push(
              FirePageRoute(
                page: TournamentDetailScreen(
                  tournamentId: tournamentId,
                  initialTabIndex: 2, // My Lobby / Room Tab
                ),
              ),
            );
          } else {
            _navigateToNotifications(navState);
          }
          break;

        case 'stage_advanced':
        case 'stage_qualified':
        case 'qualified':
        case 'result_published':
        case 'eliminated':
          if (tournamentId != null && tournamentId.isNotEmpty) {
            navState.push(
              FirePageRoute(
                page: TournamentDetailScreen(
                  tournamentId: tournamentId,
                  initialTabIndex: 3, // Standings / Brackets Tab
                ),
              ),
            );
          } else {
            _navigateToNotifications(navState);
          }
          break;

        case 'squad_invite':
        case 'roster_approval_request':
        case 'roster_approval_response':
          navState.push(
            FirePageRoute(
              page: const MySquadScreen(),
            ),
          );
          break;

        case 'join_request':
        case 'join_approved':
        case 'join_rejected':
        case 'member_removed':
          if (tournamentId != null && tournamentId.isNotEmpty) {
            navState.push(
              FirePageRoute(
                page: TeamLobbyScreen(tournamentId: tournamentId),
              ),
            );
          } else {
            navState.push(
              FirePageRoute(
                page: const MySquadScreen(),
              ),
            );
          }
          break;

        case 'payment_success':
        case 'payment_failed':
        case 'registration_submitted':
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
        case 'group_allocated':
        case 'schedule_changed':
          if (tournamentId != null && tournamentId.isNotEmpty) {
            navState.push(
              FirePageRoute(
                page: TournamentDetailScreen(tournamentId: tournamentId),
              ),
            );
          } else {
            _navigateToNotifications(navState);
          }
          break;

        default:
          // Unknown type -> Safe Fallback
          _navigateToNotifications(navState);
          break;
      }
    } catch (e) {
      debugPrint("Error during NotificationNavigator navigation: $e");
      _navigateToNotifications(navState);
    }
  }

  static void _navigateToNotifications(NavigatorState navState) {
    try {
      navState.push(
        FirePageRoute(
          page: const NotificationsScreen(),
        ),
      );
    } catch (e) {
      debugPrint("Fallback navigation to NotificationsScreen failed: $e");
    }
  }
}
