import 'dart:convert';
import 'dart:developer';

import 'package:dlh_project/config/local_notif.dart';
import 'package:dlh_project/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("background");
  _showCustomNotif(message);
}

void _handleMessage(RemoteMessage message) {
  Map data = message.data;

  if (data.containsKey('navigate_to')) {
    navigatorKey.currentState?.pushNamed(data['navigate_to']);
  }
}

void _showCustomNotif(RemoteMessage message) {
  if (message.data.containsKey('notif_title')) {
    LocalNotif.showNotif(
      id: message.hashCode,
      title: message.data['notif_title'],
      body: message.data['notif_body'],
      payload: jsonEncode(message.data),
    );
  }
}

class FCM {
  static Future<void> init() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    final settings = await FirebaseMessaging.instance.requestPermission();

    log('User granted permission: ${settings.authorizationStatus}');

    // ✅ Ambil FCM Token
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      log("🔥 FCM Registration Token: $token");
      // Di sini kamu juga bisa kirim token ini ke server kamu jika perlu
    }

    // ✅ Listen perubahan token
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      log("🔁 Token diperbarui: $newToken");
      // Update token di server jika perlu
    });

    _foregroundHandler();
    _backgroundHandler();
    _listenOpenNotif();
  }

  static _foregroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('foreground');

      _showCustomNotif(message);
    });
  }

  static _backgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static initialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      //handle message
    }
  }

  static _listenOpenNotif() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
}
