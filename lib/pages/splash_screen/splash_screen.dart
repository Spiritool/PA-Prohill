import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/warga_screen/home.dart';
import 'package:dlh_project/pages/petugas_screen/home.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<Widget> _getNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');

    if (role == 'petugas') {
      return const HomePetugasPage();
    } else if (role == 'warga') {
      return const HomePage();
    } else {
      return const HomePage(); // default
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getNextScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Tetap tampilkan splash dengan loading indicator
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        } else {
          return AnimatedSplashScreen(
            duration: 2500,
            splashIconSize: double.infinity,
            splash: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1CB5E0), Color(0xFF000046)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: MediaQuery.of(context).size.height * 0.18,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'JEMPOLIN',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            nextScreen: snapshot.data!,
            splashTransition: SplashTransition.fadeTransition,
          );
        }
      },
    );
  }
}
