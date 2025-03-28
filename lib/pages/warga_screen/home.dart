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
        icon: Icon(Icons.home, size: 30), // Menambahkan ukuran ikon
        label: 'Home',
      ),
      if (_isLoggedIn)
        const BottomNavigationBarItem(
          icon: Icon(Icons.history, size: 30), // Menambahkan ukuran ikon
          label: 'Riwayat',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.newspaper, size: 30), // Menambahkan ukuran ikon
        label: 'Berita',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.location_on_rounded,
            size: 30), // Menambahkan ukuran ikon
        label: 'UPTD/TPS',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person, size: 30), // Menambahkan ukuran ikon
        label: 'Akun',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300), // Durasi transisi halus
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: bottomNavigationBarItems.map((item) {
          final int index = bottomNavigationBarItems.indexOf(item);
          return BottomNavigationBarItem(
            icon: Column(
              children: [
                // Garis hijau di atas ikon
                if (_selectedIndex == index)
                  Container(
                    width: 40, // Panjang garis
                    height: 3, // Ketebalan garis
                    color: const Color(0xFF78A55A), // Warna garis hijau
                    margin: const EdgeInsets.only(bottom: 4),
                  )
                else
                  const SizedBox(height: 7), // Spacer agar tetap simetris
                item.icon, // Ikon asli dari item
              ],
            ),
            label: item.label,
          );
        }).toList(),
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF78A55A),
        unselectedItemColor: const Color(0xFF434343),
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            const Color(0xFFD1EFDA), // Ganti dengan warna yang diinginkan
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
