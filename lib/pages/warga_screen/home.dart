import 'package:dlh_project/backup/historyPetugas.dart';
import 'package:dlh_project/pages/warga_screen/akun/userprofile.dart';
import 'package:dlh_project/pages/warga_screen/history.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_konten.dart';
import 'berita.dart';
import 'uptd.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? userName;
  int? userId;
  String? userRole;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userId = prefs.getInt('user_id') ?? 0;
      userRole = prefs.getString('user_role') ?? 'warga';
      _isLoggedIn = userName != 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeKonten(
        userName: userName ?? 'Guest',
        userId: userId ?? 0,
      ),
      if (_isLoggedIn)
        userRole == 'petugas' ? const HistoryPetugas() : const History(),
      const Berita(),
      const Uptd(),
      const UserProfile(),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: _buildBottomNavigationItems(),
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xFFFF6600),
          unselectedItemColor: const Color(0xFF909090),
          onTap: _onItemTapped,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.8,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            height: 1.8,
          ),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavigationItems() {
    return [
      _buildNavItem(Icons.home_outlined, Icons.home_filled, 'Home', 0),
      if (_isLoggedIn)
        _buildNavItem(Icons.history_outlined, Icons.history, 'Riwayat', 1),
      _buildNavItem(
          Icons.article_outlined, Icons.article, 'Berita', _isLoggedIn ? 2 : 1),
      _buildNavItem(Icons.location_on_outlined, Icons.location_on, 'UPTD/TPS',
          _isLoggedIn ? 3 : 2),
      _buildNavItem(
          Icons.person_outline, Icons.person, 'Akun', _isLoggedIn ? 4 : 3),
    ];
  }

  BottomNavigationBarItem _buildNavItem(
      IconData outlineIcon, IconData filledIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              size: 28,
              color: isSelected ? Color(0xFFFF6600) : const Color(0xFF909090),
            ),
            const SizedBox(height: 4),
            if (isSelected)
              Container(
                width: 24,
                height: 3,
                decoration: BoxDecoration(
                  color: Color(0xFFFF6600),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
      label: label,
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }
}
