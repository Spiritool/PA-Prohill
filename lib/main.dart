import 'package:dlh_project/config/fcm.dart';
import 'package:dlh_project/config/local_notif.dart';
import 'package:dlh_project/pages/splash_screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('✅ Firebase initialized');

    // Load environment variables
    await dotenv.load(fileName: ".env");
    log('✅ Environment loaded');

    // Initialize notifications
    await LocalNotif.init();
    log('✅ LocalNotif initialized');

    await FCM.init();
    log('✅ FCM initialized');

    runApp(MyApp());
  } catch (e) {
    log('❌ Error in main: $e');
    // Run app anyway with basic setup
    runApp(MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String fcmToken = '-';
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Add delay to ensure app is fully loaded
      await Future.delayed(Duration(seconds: 1));

      // Handle initial messages
      await LocalNotif.initialMessage();
      await FCM.initialMessage();

      log('✅ Initial notifications handled');
    } catch (e) {
      log('❌ Error initializing notifications: $e');
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "JEMPOLIN",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      // Add error handling for navigation
      builder: (context, child) {
        // Handle any uncaught errors in navigation
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          log('❌ Flutter Error: ${errorDetails.exception}');
          return Material(
            child: Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please restart the app',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child ?? Container();
      },
      // Add routes for better navigation handling
      routes: {
        '/home': (context) => const SplashScreen(),
        // Add other routes here if needed
        // '/history': (context) => const History(),
      },
      // Handle unknown routes
      onUnknownRoute: (settings) {
        log('❌ Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
