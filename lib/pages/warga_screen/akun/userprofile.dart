import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/about.dart';
import 'package:dlh_project/pages/warga_screen/akun/akun.dart';
import 'package:dlh_project/pages/warga_screen/contactus.dart';
import 'package:dlh_project/pages/warga_screen/qna.dart';
import 'package:dlh_project/pages/warga_screen/saldo.dart';
import 'package:dlh_project/pages/warga_screen/syarat.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key, required int selectedIndex});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getString('user_name') !=
          null; // Memeriksa apakah ada username yang disimpan
    });
  }

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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 12,
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6600).withOpacity(0.1),
                      const Color(0xFFFF6600).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF6600).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFFF6600),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Konfirmasi Logout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin logout?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade50,
                      Color(0xFFE3F2FD),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue.shade700,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Anda perlu login kembali untuk mengakses aplikasi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  backgroundColor: Colors.grey.shade50,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6600).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6600),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.exit_to_app_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _logout();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6600),
                const Color(0xFFFF6600).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6600).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'User Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Kelola profil dan pengaturan akun',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: [
              const SizedBox(height: 24),
              // Profile Status Card
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoggedIn
                        ? [
                            const Color(0xFFFF6600).withOpacity(0.1),
                            const Color(0xFFFF6600).withOpacity(0.05),
                          ]
                        : [
                            Colors.grey.shade100,
                            Colors.grey.shade50,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isLoggedIn
                        ? const Color(0xFFFF6600).withOpacity(0.2)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isLoggedIn
                            ? const Color(0xFFFF6600)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isLoggedIn ? Icons.check_circle : Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoggedIn ? 'Anda sudah masuk' : 'Belum masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _isLoggedIn
                                  ? const Color(0xFFFF6600)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLoggedIn
                                ? 'Nikmati semua fitur aplikasi'
                                : 'Masuk untuk mengakses semua fitur',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Items
              _isLoggedIn
                  ? _buildEnhancedProfileTile(
                      icon: Icons.person_rounded,
                      text: 'Account',
                      subtitle: 'Kelola informasi akun',
                      color: const Color(0xFFFF6600),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Akun(
                                    selectedIndex: 1,
                                  )),
                        );
                      },
                    )
                  : _buildEnhancedProfileTile(
                      icon: Icons.login_rounded,
                      text: 'Login',
                      subtitle: 'Masuk ke akun Anda',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Login()),
                        );
                      },
                    ),
              _buildEnhancedProfileTile(
                icon: Icons.account_balance_wallet,
                text: 'Saldo Sampah',
                subtitle: 'Detail Sampah Balanced',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SaldoSampahScreen()),
                  );
                },
              ),
              _buildEnhancedProfileTile(
                icon: Icons.mail_outline_rounded,
                text: 'Contact Us',
                subtitle: 'Hubungi tim support',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContactSupportPage()),
                  );
                },
              ),
              _buildEnhancedProfileTile(
                icon: Icons.description_rounded,
                text: 'Terms & Conditions',
                subtitle: 'Syarat dan ketentuan',
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TermsAndConditionsPage()),
                ),
              ),
              _buildEnhancedProfileTile(
                icon: Icons.help_outline_rounded,
                text: 'F A Q',
                subtitle: 'Pertanyaan yang sering diajukan',
                color: Colors.indigo,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QnAPage()),
                  );
                },
              ),
              _buildEnhancedProfileTile(
                icon: Icons.info_outline_rounded,
                text: 'About',
                subtitle: 'Tentang aplikasi',
                color: Colors.cyan,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => JempolinHomePage()),
                  );
                },
              ),
              // _buildEnhancedProfileTile(
              //   icon: Icons.location_on_rounded,
              //   text: 'Location',
              //   subtitle: 'Pengaturan lokasi',
              //   color: Colors.red,
              // ),
              if (_isLoggedIn)
                _buildEnhancedProfileTile(
                  icon: Icons.logout_rounded,
                  text: 'Logout',
                  subtitle: 'Keluar dari akun',
                  color: Colors.red.shade600,
                  onTap: _confirmLogout,
                  isDestructive: true,
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedProfileTile({
    required IconData icon,
    required String text,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive ? Colors.red.shade100 : Colors.grey.shade100,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.shade50 : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isDestructive ? Colors.red.shade100 : color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red.shade600 : color,
            size: 24,
          ),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red.shade700 : Colors.black87,
            letterSpacing: -0.2,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }
}
