import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:dlh_project/pages/form_opening/login.dart';
import 'editprofil.dart';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class GeneralInfo extends StatefulWidget {
  const GeneralInfo({super.key});

  @override
  State<GeneralInfo> createState() => _GeneralInfoState();
}

class _GeneralInfoState extends State<GeneralInfo> {
  String userName = 'Guest';
  String userPhone = '081234567890';
  String? userPhoto; // tambahkan path foto
  bool isLoggedIn = false;

  final Color primaryColor = const Color(0xFF0D47A1);
  final Color bgColor = const Color(0xFFF0F4FF);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userPhone = prefs.getString('user_phone') ?? '081234567890';
      userPhoto = prefs.getString('user_profile_photo'); // ambil path foto
      isLoggedIn = userName != 'Guest';
    });
  }

  void _showEditDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialName: userName,
          initialPhone: userPhone,
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userName = result['name'] ?? userName;
        userPhone = result['phone'] ?? userPhone;
        userPhoto = prefs
            .getString('user_profile_photo'); // ✅ benar // refresh foto juga
        isLoggedIn = true;
      });
    }
  }

  Widget _buildProfilePhoto() {
    ImageProvider? imageProvider;

    if (userPhoto != null && userPhoto!.isNotEmpty) {
      if (userPhoto!.startsWith('http')) {
        imageProvider = NetworkImage(userPhoto!);
      } else {
        imageProvider = FileImage(File(userPhoto!));
      }
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF6600).withOpacity(0.8),
            Color(0xFFFF8C42).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF6600).withOpacity(0.3),
            spreadRadius: 8,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(6),
      child: ClipOval(
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: imageProvider != null
              ? Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFFF6600).withOpacity(0.1),
                        Color(0xFFFF8C42).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Color(0xFFFF6600),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6600), Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF6600).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!isLoggedIn) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade50,
              Colors.white,
              Colors.grey.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF6600).withOpacity(0.1),
                      Color(0xFFFF8C42).withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.circleUser,
                  size: 60,
                  color: Color(0xFFFF6600).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF6600), Color(0xFFFF8C42)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6600).withOpacity(0.4),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Login()),
                  ),
                  icon: const Icon(Icons.login_rounded, size: 20),
                  label: const Text(
                    'Login untuk Edit Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfilePhoto(),
            const SizedBox(height: 40),
            _buildInfoTile('Nama', userName, Icons.person_outline),
            _buildInfoTile('No. HP', userPhone, Icons.phone_outlined),
            const Spacer(),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6600), Color(0xFFFF8C42)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF6600).withOpacity(0.4),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _showEditDialog,
                icon: const Icon(Icons.edit_outlined, size: 22),
                label: const Text(
                  'Edit Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'General Info',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF6600), Color(0xFFFF8C42)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildContent(),
    );
  }
}
