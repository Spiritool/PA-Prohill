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

// Flag untuk prevent multiple navigation
bool _isNavigating = false;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    log("background message received");
    await _showCustomNotif(message);
  } catch (e) {
    log('Error in background handler: $e');
  }
}

void _handleMessage(RemoteMessage message) {
  // Prevent multiple navigation
  if (_isNavigating) {
    log('Navigation already in progress, skipping...');
    return;
  }

  try {
    Map data = message.data;

    if (data.containsKey('navigate_to')) {
      String route = data['navigate_to'];
      _navigateToRoute(route);
    }
  } catch (e) {
    log('Error handling message: $e');
  }
}

Future<void> _navigateToRoute(String route) async {
  if (_isNavigating) return;
  
  _isNavigating = true;
  
  try {
    // Add delay to ensure UI is ready
    await Future.delayed(Duration(milliseconds: 500));
    
    if (navigatorKey.currentState?.mounted == true) {
      if (route == '/history') {
        await navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const History()),
        );
      } else {
        await navigatorKey.currentState?.pushNamed(route);
      }
    }
  } catch (e) {
    log('Navigation error: $e');
  } finally {
    _isNavigating = false;
  }
}

Future<void> _showCustomNotif(RemoteMessage message) async {
  try {
    if (message.data.containsKey('notif_title')) {
      await LocalNotif.showNotif(
        id: message.hashCode,
        title: message.data['notif_title'],
        body: message.data['notif_body'],
        payload: jsonEncode(message.data),
      );
    }
  } catch (e) {
    log('Error showing notification: $e');
  }
}

Future<void> saveTokenToServer(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      log('❌ Gagal kirim token: userId tidak ditemukan');
      return;
    }

    final response = await http.post(
      Uri.parse('$baseipapi/user/update-fcm-token'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'fcm_token': token,
      }),
    ).timeout(Duration(seconds: 10)); // Add timeout

    if (response.statusCode == 200) {
      log('✅ Token berhasil dikirim ke server');
    } else {
      log('❌ Gagal kirim token ke server: ${response.body}');
    }
  } catch (e) {
    log('❌ Error saving token: $e');
  }
}

class FCM {
  static Future<void> init() async {
    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);

      final settings = await FirebaseMessaging.instance.requestPermission();
      log('User granted permission: ${settings.authorizationStatus}');

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        log("🔥 FCM Registration Token: $token");
        await saveTokenToServer(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        try {
          log("🔁 Token diperbarui: $newToken");
          await saveTokenToServer(newToken);
        } catch (e) {
          log('Error refreshing token: $e');
        }
      });

      _foregroundHandler();
      _backgroundHandler();
      _listenOpenNotif();
    } catch (e) {
      log('Error initializing FCM: $e');
    }
  }

  static _foregroundHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      try {
        log('foreground message received');
        await _showCustomNotif(message);
      } catch (e) {
        log('Error in foreground handler: $e');
      }
    });
  }

  static _backgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static initialMessage() async {
    try {
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        // Add delay before handling initial message
        await Future.delayed(Duration(seconds: 1));
        _handleMessage(initialMessage);
      }
    } catch (e) {
      log('Error handling initial message: $e');
    }
  }

  static _listenOpenNotif() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      try {
        log('App opened from notification');
        // Add delay to ensure app is fully loaded
        Future.delayed(Duration(milliseconds: 1000), () {
          _handleMessage(message);
        });
      } catch (e) {
        log('Error handling opened notification: $e');
      }
    });
  }
}