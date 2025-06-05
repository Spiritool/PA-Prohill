import 'dart:convert';
import 'dart:developer';
import '../main.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Flag untuk prevent multiple navigation
bool _isLocalNavigating = false;

void _onDidReceiveBackgroundNotificationResponse(
  NotificationResponse notificationResponse,
) {
  log('background notification response: ${notificationResponse.id}');
  _handleNotificationResponse(notificationResponse);
}

void _handleNotificationResponse(NotificationResponse notificationResponse) {
  // Prevent multiple navigation
  if (_isLocalNavigating) {
    log('Local navigation already in progress, skipping...');
    return;
  }

  try {
    log('payload: ${notificationResponse.payload}');
    final payloadJson = notificationResponse.payload;
    if (payloadJson == null) return;

    final payload = jsonDecode(payloadJson) as Map;
    if (payload.containsKey('navigate_to')) {
      _navigateFromNotification(payload);
    }
  } catch (e) {
    log('Error handling notification response: $e');
  }
}

Future<void> _navigateFromNotification(Map payload) async {
  if (_isLocalNavigating) return;

  _isLocalNavigating = true;

  try {
    // Add delay to ensure UI is ready
    await Future.delayed(Duration(milliseconds: 800));

    if (navigatorKey.currentState?.mounted == true) {
      await navigatorKey.currentState?.pushNamed(
        payload['navigate_to'],
        arguments: payload['arguments'],
      );
    }
  } catch (e) {
    log('Local navigation error: $e');
  } finally {
    _isLocalNavigating = false;
  }
}

class LocalNotif {
  static final _notifPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      await _notifPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      final androidSettings =
          AndroidInitializationSettings('@drawable/lc_sampah');
      final iosSettings = DarwinInitializationSettings();

      final initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifPlugin.initialize(
        initializationSettings,
        onDidReceiveBackgroundNotificationResponse:
            _onDidReceiveBackgroundNotificationResponse,
        onDidReceiveNotificationResponse: (notificationResponse) {
          log('foreground notification response: ${notificationResponse.id}');
          // Add delay for foreground responses too
          Future.delayed(Duration(milliseconds: 500), () {
            _handleNotificationResponse(notificationResponse);
          });
        },
      );
    } catch (e) {
      log('Error initializing LocalNotif: $e');
    }
  }

  // handle notif from terminate state
  static initialMessage() async {
    try {
      final notifAppLaunchDetails =
          await _notifPlugin.getNotificationAppLaunchDetails();
      if (notifAppLaunchDetails == null) return;

      final appOpenViaNotif = notifAppLaunchDetails.didNotificationLaunchApp;
      if (appOpenViaNotif) {
        final notifResponse = notifAppLaunchDetails.notificationResponse;
        if (notifResponse == null) return;

        // Add delay before handling terminate state notification
        await Future.delayed(Duration(seconds: 2));
        _handleNotificationResponse(notifResponse);
      }
    } catch (e) {
      log('Error handling initial notification: $e');
    }
  }

  static NotificationDetails _defaultNotifDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'channelId',
        'JEMPOLIN',
        channelDescription: 'Notifikasi untuk pengguna aplikasi saya',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/lc_sampah',
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> showNotif({
    int id = 0,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    try {
      await _notifPlugin.show(
        id,
        title,
        body,
        notificationDetails ?? _defaultNotifDetails(),
        payload: payload,
      );
    } catch (e) {
      log('Error showing notification: $e');
    }
  }

  static cancelNotif() async {
    try {
      await _notifPlugin.cancelAll();
    } catch (e) {
      log('Error canceling notifications: $e');
    }
  }
}
