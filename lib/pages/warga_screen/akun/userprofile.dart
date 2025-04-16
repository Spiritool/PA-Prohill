import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/akun/akun.dart';
import 'package:dlh_project/pages/warga_screen/qna.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileApp extends StatelessWidget {
  const UserProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: UserProfile(),
    );
  }
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isLoggedIn = true;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isLoggedIn = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7AC142),
              ),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Menghilangkan tombol kembali
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100,
        title: const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'User Profile',
            style: TextStyle(
              color: Color(0xFF7AC142),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            ProfileTile(
              icon: Icons.person,
              text: 'Account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Akun()),
                );
              },
            ),
            const ProfileTile(icon: Icons.apartment, text: 'Recurring Details'),
            const ProfileTile(icon: Icons.mail_outline, text: 'Contact Us'),
            const ProfileTile(
                icon: Icons.description, text: 'Terms & Conditions'),
            ProfileTile(
              icon: Icons.help_outline,
              text: 'F A Q',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QnAPage()),
                );
              },
            ),
            const ProfileTile(icon: Icons.info_outline, text: 'About'),
            const ProfileTile(
                icon: Icons.location_on_outlined, text: 'Location'),
            // Cek apakah sudah login, jika sudah tampilkan tombol logout
            if (_isLoggedIn)
              ProfileTile(
                icon: Icons.logout,
                text: 'Logout',
                onTap: _confirmLogout,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFDBE4C6), width: 0.8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF7AC142)),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
