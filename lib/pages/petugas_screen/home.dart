import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/petugas_screen/Home_Konten.dart';
import 'package:dlh_project/pages/petugas_screen/akun_petugas.dart';
import 'package:dlh_project/pages/petugas_screen/historyPetugas.dart';
import 'package:dlh_project/pages/petugas_screen/activityPetugas.dart';
import 'package:dlh_project/pages/warga_screen/Berita.dart';
import 'package:dlh_project/pages/warga_screen/history.dart';
import 'package:dlh_project/pages/warga_screen/uptd.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePetugasPage extends StatefulWidget {
  const HomePetugasPage({super.key});

  @override
  State<HomePetugasPage> createState() => _HomePetugasPageState();
}

class _HomePetugasPageState extends State<HomePetugasPage> {
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

      // Check if the user is not 'petugas' and redirect or show a warning
      if (userRole != 'petugas') {
        _showAccessDeniedDialog();
      }
    });
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Akses Ditolak'),
        content: const Text('Halaman ini hanya dapat diakses oleh Petugas.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back to the previous page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeKontenPetugas(
        userName: userName ?? 'Guest',
        userId: userId ?? 0,
      ),
      if (_isLoggedIn)
        userRole == 'petugas' ? const ActivityPetugasPage() : const History(),
      const Berita(),
      const Uptd(),
      const AkunPetugas(),

    ];

    return Scaffold(
      body: SafeArea(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'Berita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_rounded),
            label: 'UPTD/TPS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Akun',
          ),
        ],
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
}
