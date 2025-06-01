import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:dlh_project/pages/form_opening/login.dart';
import 'editprofil.dart';
import 'dart:developer';

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

    return ClipOval(
      child: Container(
        width: 250, // dari 120 jadi 250
        height: 250, // dari 120 jadi 250
        color: primaryColor.withOpacity(0.1),
        child: imageProvider != null
            ? Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: 250, // sesuaikan juga agar penuh
                height: 250,
              )
            : Icon(Icons.person,
                size: 120, color: primaryColor), // ikon diperbesar
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.15),
              child: Icon(icon, color: primaryColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[700],
                      )),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      )),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.circleUser,
                size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Login untuk Edit Profil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildProfilePhoto(),
          const SizedBox(height: 24),
          _buildInfoTile('Nama', userName, Icons.person),
          _buildInfoTile('No. HP', userPhone, Icons.phone),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Edit Profil', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title:
            const Text('General Info', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildContent(),
    );
  }
}
