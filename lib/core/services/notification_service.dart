import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:blastix_esports/core/services/notification_navigator.dart';
import 'package:blastix_esports/core/services/storage_service.dart';
import 'package:blastix_esports/core/sync/real_time_sync_manager.dart';
import 'package:blastix_esports/features/auth/data/auth_repository.dart';
import 'package:blastix_esports/features/live/providers/live_provider.dart';
import 'package:blastix_esports/features/live/providers/team_provider.dart';
import 'package:blastix_esports/features/notifications/providers/notification_provider.dart';
import 'package:blastix_esports/features/splash/providers/splash_providers.dart';

/// Top-level background message handler required by FirebaseMessaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase.initializeApp in background handler error: $e");
  }

  // If message.notification != null, Android system handles showing it.
  // Avoid duplicate notifications.
  if (message.notification != null) {
    debugPrint("Background message contains notification payload; skipping local display.");
    return;
  }

  // If message.notification == null (data-only message), show local notification
  try {
    final title = message.data['title']?.toString() ?? 'BlastiX Alert';
    final body = message.data['body']?.toString() ?? '';

    if (body.isEmpty && title == 'BlastiX Alert') return;

    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
    );

    const channel = AndroidNotificationChannel(
      'blastix_high_importance_channel',
      'BlastiX Notifications',
      description: 'High importance notifications for tournaments and match alerts.',
      importance: Importance.max,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  } catch (e) {
    debugPrint("Error displaying data-only notification in background isolate: $e");
  }
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationTapped =>
      _notificationStreamController.stream;

  bool _initialized = false;
  ProviderContainer? _container;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _permissionDenied = false;

  bool get isPermissionDenied => _permissionDenied;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'blastix_high_importance_channel',
    'BlastiX Notifications',
    description: 'High importance notifications for tournaments and match alerts.',
    importance: Importance.max,
  );

  /// Set ProviderContainer reference for real-time provider updates
  void setProviderContainer(ProviderContainer container) {
    _container = container;
  }

  /// Initialize Firebase Messaging & Local Notifications
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. Request Permission (Android 13+ & iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _permissionDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;
      debugPrint('Notification Authorization Status: ${settings.authorizationStatus}');

      // Set iOS foreground presentation options so iOS won't break Android
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Setup Local Notifications (For Foreground & Local display)
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            _handleNotificationClick(response.payload!);
          }
        },
      );

      // Create High Importance Channel for Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // 3. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 4. Foreground Message Listener (Task 3)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground FCM message: ${message.messageId}');
        _showForegroundNotification(message);
      });

      // 5. Message Click Listeners (Task 4 Entry Points a & b)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from background via FCM push: ${message.data}');
        _handleRemoteMessageClick(message);
      });

      // Check terminated launch via FCM (Entry Point b)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        debugPrint('App launched from terminated state via FCM push: ${initialMessage.data}');
        NotificationNavigator.setPendingPayload(initialMessage.data);
      }

      // Check terminated launch via Local Notification (Entry Point d)
      final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final payload = launchDetails.notificationResponse!.payload!;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          debugPrint('App launched from terminated state via local notification: $data');
          NotificationNavigator.setPendingPayload(data);
        } catch (_) {}
      }

      // 6. FCM Token Debug Log (Do NOT log full token in release)
      if (kDebugMode) {
        final token = await getToken();
        debugPrint('🔥 FCM Device Token: $token');
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Get FCM Device Token
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Register Device Token with backend (Task 1)
  Future<void> registerDeviceTokenWithBackend(
    AuthRepository authRepository,
    StorageService storageService,
  ) async {
    try {
      final tokenStr = await storageService.getToken();
      if (tokenStr == null || tokenStr.isEmpty) return;

      final fcmToken = await getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await authRepository.registerDeviceToken(fcmToken);
      }

      // Setup single token refresh listener
      setupTokenRefreshListener(authRepository, storageService);
    } catch (e) {
      debugPrint("Error registering device token with backend: $e");
    }
  }

  /// Listen to token refresh and re-send to backend if logged in
  void setupTokenRefreshListener(
    AuthRepository authRepository,
    StorageService storageService,
  ) {
    _tokenRefreshSub ??= _fcm.onTokenRefresh.listen((newToken) async {
      try {
        final tokenStr = await storageService.getToken();
        if (tokenStr != null && tokenStr.isNotEmpty && newToken.isNotEmpty) {
          await authRepository.registerDeviceToken(newToken);
        }
      } catch (e) {
        debugPrint("Error handling FCM token refresh: $e");
      }
    });
  }

  /// Unregister Device Token from backend on logout (Task 1)
  Future<void> unregisterDeviceTokenFromBackend(
    AuthRepository authRepository,
  ) async {
    try {
      final fcmToken = await getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await authRepository.unregisterDeviceToken(fcmToken);
      }
    } catch (_) {
      // Ignore failures silently on logout
    }
  }

  /// Show Heads-Up Local Notification when App is in Foreground (Task 3)
  void _showForegroundNotification(RemoteMessage message) {
    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'BlastiX Alert';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        '';

    final android = message.notification?.android;

    _localNotifications.show(
      id: message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: body.isNotEmpty ? BigTextStyleInformation(body) : null,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Refresh/Add in-app notification list and badge count (Task 3 & 6)
    if (_container != null && message.data.isNotEmpty) {
      try {
        _container!
            .read(notificationProvider.notifier)
            .addPushNotification(message.data, title: title, body: body);

        // Trigger instant sync across active sync tasks on join request or waitlist foreground push
        final type = message.data['type']?.toString().toLowerCase().trim() ?? '';
        if (type == 'join_request' ||
            type == 'join_approved' ||
            type == 'join_rejected' ||
            type == 'registration_approval' ||
            type == 'registration_approval_response' ||
            type == 'roster_change_required' ||
            type == 'roster_change_requested' ||
            type == 'roster_change_applied' ||
            type == 'roster_change_declined' ||
            type == 'roster_change_expired' ||
            type == 'registration_invalidated' ||
            type == 'waitlisted' ||
            type == 'waitlist_promoted' ||
            type == 'waitlist_invalidated') {
          RealTimeSyncManager().triggerInstantSync();
          if (_container != null) {
            _container!.invalidate(appTournamentsProvider);
            _container!.invalidate(blastxLiveTournamentsApiProvider);
            _container!.invalidate(blastxUpcomingTournamentsApiProvider);
            final tid = message.data['tournamentId']?.toString() ?? message.data['tournament_id']?.toString();
            if (tid != null && tid.isNotEmpty) {
              _container!.invalidate(teamProvider(tid));
              _container!.invalidate(tournamentByIdProvider(tid));
            }
          }
        }
      } catch (e) {
        debugPrint("Error adding push to notificationProvider: $e");
      }
    }
  }

  /// Show local notification for room details release or tournament updates
  void showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) {
    _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  void _handleRemoteMessageClick(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _handleNotificationClick(jsonEncode(message.data));
    }
  }

  Future<void> _handleNotificationClick(String payloadJson) async {
    try {
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;
      debugPrint("Notification payload tapped: $data");

      // Notify stream listeners (e.g. MatchesTab)
      _notificationStreamController.add(data);

      // Add to in-app notifications screen if container available
      if (_container != null) {
        try {
          _container!
              .read(notificationProvider.notifier)
              .addPushNotification(data);
        } catch (_) {}
      }

      // Check user login state and route via NotificationNavigator
      bool isLoggedIn = true;
      if (_container != null) {
        try {
          final storage = _container!.read(storageServiceProvider);
          final token = await storage.getToken();
          isLoggedIn = token != null && token.isNotEmpty;
        } catch (_) {}
      }

      NotificationNavigator.handleTap(data, isLoggedIn: isLoggedIn);
    } catch (e) {
      debugPrint("Error parsing notification payload: $e");
    }
  }

  /// Prompt user if notification permission is denied (Task 5)
  void showPermissionDeniedPromptIfNecessary(BuildContext context) {
    if (!_permissionDenied || !context.mounted) return;

    // Show a small, non-blocking floating SnackBar offering to open settings (once)
    _permissionDenied = false; // reset flag so prompt is shown only once
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notifications are disabled for BlastiX Arena.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'SETTINGS',
          textColor: const Color(0xFF00E5FF),
          onPressed: () {
            _localNotifications
                .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission();
          },
        ),
      ),
    );
  }
}
