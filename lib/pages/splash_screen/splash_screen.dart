import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/warga_screen/home.dart';
import 'package:dlh_project/pages/petugas_screen/home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<Widget> _getNextScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');

    // Determine the next screen based on the user's role
    if (role == 'petugas') {
      return const HomePetugasPage();
    } else if (role == 'warga') {
      return const HomePage();
    } else {
      return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getNextScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else {
          return AnimatedSplashScreen(
            splash: Stack(
              children: [
                // Background color
                Container(
                  color: BlurStyle,
                ),
                // Top logo
                Positioned(
                  top: 226,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    "assets/images/ic_dlh.png",
                    height: 113,
                  ),
                ),
                // Center text
                const Center(
                  child: Text(
                    'PROHIL DLH CILEGON',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            nextScreen: snapshot.data!,
            splashIconSize: double.infinity,
            backgroundColor: Colors.transparent,
            splashTransition: SplashTransition.fadeTransition,
            duration: 3000,
          );
        }
      },
    );
  }
}
