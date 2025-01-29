import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/petugas_screen/historyPetugas.dart';
import 'package:dlh_project/pages/warga_screen/history.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_konten.dart';
import 'berita.dart';
import 'akun.dart';
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
      userRole = prefs.getString('user_role') ?? 'warga'; // Default to 'warga'
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
      const Akun(),
    ];

    final List<BottomNavigationBarItem> bottomNavigationBarItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      if (_isLoggedIn)
        const BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.newspaper),
        label: 'Berita',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.location_on_rounded),
        label: 'UPTD/TPS',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Akun',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: bottomNavigationBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: BlurStyle,
        unselectedItemColor: grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
