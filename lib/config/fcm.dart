import 'dart:convert';
import 'dart:developer';

import 'package:dlh_project/config/local_notif.dart';
import 'package:dlh_project/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:dlh_project/pages/splash_screen/splash_screen.dart';
import 'package:dlh_project/pages/warga_screen/history.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("background");
  _showCustomNotif(message);
}

void _handleMessage(RemoteMessage message) {
  Map data = message.data;

  if (data.containsKey('navigate_to')) {
    String route = data['navigate_to'];

    if (route == '/history') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const History()),
      );
    } else {
      navigatorKey.currentState?.pushNamed(route);
    }
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

Future<void> saveTokenToServer(String token) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id'); // harus disimpan saat login

  if (userId == null) {
    log('❌ Gagal kirim token: userId tidak ditemukan');
    return;
  }

  final response = await http.post(
    Uri.parse('$baseipapi/user/update-fcm-token'), // GANTI URL SERVER
    headers: {
      'Content-Type': 'application/json',
      // 'Authorization': 'Bearer YOUR_TOKEN_JIKA_PAKAI_AUTH',
    },
    body: jsonEncode({
      'user_id': userId,
      'fcm_token': token,
    }),
  );

  if (response.statusCode == 200) {
    log('✅ Token berhasil dikirim ke server');
  } else {
    log('❌ Gagal kirim token ke server: ${response.body}');
  }
}

class FCM {
  static Future<void> init() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    final settings = await FirebaseMessaging.instance.requestPermission();
    log('User granted permission: ${settings.authorizationStatus}');

    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      log("🔥 FCM Registration Token: $token");
      await saveTokenToServer(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      log("🔁 Token diperbarui: $newToken");
      await saveTokenToServer(newToken);
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
      // handle
    }
  }

  static _listenOpenNotif() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }
}
