import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/warga_screen/home.dart';
import 'package:dlh_project/pages/petugas_screen/home.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<Widget> _getNextScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');

      switch (role) {
        case 'petugas':
          return const HomePetugasPage();
        case 'warga':
          return const HomePage();
        default:
          // Could redirect to login/onboarding if no role is set
          return const HomePage();
      }
    } catch (e) {
      // Handle any SharedPreferences errors
      debugPrint('Error getting user role: $e');
      return const HomePage();
    }
  }

  // Custom painter untuk membuat pola batik
  Widget _buildBatikBackground() {
    return CustomPaint(
      painter: BatikPatternPainter(),
      size: Size.infinite,
    );
  }

  Widget _buildSplashContent(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Background batik
          _buildBatikBackground(),

          // Overlay gradient untuk mempertahankan warna brand
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6600).withOpacity(0.8),
                  const Color(0xFFCC3300).withOpacity(0.8)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add some animation to the logo
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween(begin: 0.8, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: MediaQuery.of(context).size.height * 0.18,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Add fade-in animation to text
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1200),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: const Text(
                        'JEMPOLIN',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Optional: Add a subtitle or tagline
                TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 1400),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: const Text(
                        'Sistem Pengelolaan Sampah',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getNextScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading splash with batik background
          return Scaffold(
            body: Stack(
              children: [
                _buildBatikBackground(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6600).withOpacity(0.8),
                        const Color(0xFFCC3300).withOpacity(0.8)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          // Handle error state with batik background
          return Scaffold(
            body: Stack(
              children: [
                _buildBatikBackground(),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF6600).withOpacity(0.8),
                        const Color(0xFFCC3300).withOpacity(0.8)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Show animated splash
          return AnimatedSplashScreen(
            duration: 2500,
            splashIconSize: double.infinity,
            splash: _buildSplashContent(context),
            backgroundColor: Colors.transparent,
            nextScreen: snapshot.data!,
            splashTransition: SplashTransition.fadeTransition,
          );
        }
      },
    );
  }
}

// Custom painter untuk membuat pola batik tradisional Indonesia
class BatikPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Base colors untuk batik
    final Paint darkPaint = Paint()
      ..color = const Color(0xFF8B4513) // Coklat tua
      ..style = PaintingStyle.fill;

    final Paint lightPaint = Paint()
      ..color = const Color(0xFFD2691E) // Coklat muda
      ..style = PaintingStyle.fill;

    final Paint accentPaint = Paint()
      ..color = const Color(0xFFFFD700) // Emas
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Fill background dengan warna dasar
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), darkPaint);

    // Gambar pola batik parang atau kawung
    _drawParangPattern(canvas, size, lightPaint, accentPaint);
    _drawKawungPattern(canvas, size, lightPaint, accentPaint);
    _drawFloralPattern(canvas, size, accentPaint);
  }

  void _drawParangPattern(
      Canvas canvas, Size size, Paint lightPaint, Paint accentPaint) {
    final double spacing = 80;
    final double waveHeight = 40;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing * 2) {
        Path path = Path();
        path.moveTo(x, y);
        path.quadraticBezierTo(x + spacing / 2, y - waveHeight, x + spacing, y);
        path.quadraticBezierTo(
            x + spacing * 1.5, y + waveHeight, x + spacing * 2, y);

        canvas.drawPath(path, accentPaint);
      }
    }
  }

  void _drawKawungPattern(
      Canvas canvas, Size size, Paint lightPaint, Paint accentPaint) {
    final double spacing = 100;
    final double radius = 25;

    for (double y = spacing / 2; y < size.height; y += spacing) {
      for (double x = spacing / 2; x < size.width; x += spacing) {
        // Gambar 4 lingkaran yang saling berpotongan (motif kawung)
        canvas.drawCircle(
            Offset(x - radius / 2, y - radius / 2), radius * 0.6, lightPaint);
        canvas.drawCircle(
            Offset(x + radius / 2, y - radius / 2), radius * 0.6, lightPaint);
        canvas.drawCircle(
            Offset(x - radius / 2, y + radius / 2), radius * 0.6, lightPaint);
        canvas.drawCircle(
            Offset(x + radius / 2, y + radius / 2), radius * 0.6, lightPaint);

        // Outline
        canvas.drawCircle(
            Offset(x - radius / 2, y - radius / 2), radius * 0.6, accentPaint);
        canvas.drawCircle(
            Offset(x + radius / 2, y - radius / 2), radius * 0.6, accentPaint);
        canvas.drawCircle(
            Offset(x - radius / 2, y + radius / 2), radius * 0.6, accentPaint);
        canvas.drawCircle(
            Offset(x + radius / 2, y + radius / 2), radius * 0.6, accentPaint);
      }
    }
  }

  void _drawFloralPattern(Canvas canvas, Size size, Paint accentPaint) {
    final double spacing = 150;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        // Gambar bunga sederhana
        _drawSimpleFlower(
            canvas, Offset(x + spacing / 2, y + spacing / 2), accentPaint);
      }
    }
  }

  void _drawSimpleFlower(Canvas canvas, Offset center, Paint paint) {
    final double petalRadius = 12;
    final double petalDistance = 18;

    // Gambar 6 kelopak bunga
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * (3.14159 / 180);
      Offset petalCenter = Offset(
        center.dx + petalDistance * cos(angle),
        center.dy + petalDistance * sin(angle),
      );

      // Kelopak bunga berbentuk elips
      canvas.save();
      canvas.translate(petalCenter.dx, petalCenter.dy);
      canvas.rotate(angle);

      Path petalPath = Path();
      petalPath.addOval(Rect.fromCenter(
        center: Offset.zero,
        width: petalRadius * 2,
        height: petalRadius,
      ));

      canvas.drawPath(petalPath, paint);
      canvas.restore();
    }

    // Pusat bunga
    canvas.drawCircle(center, 6, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
