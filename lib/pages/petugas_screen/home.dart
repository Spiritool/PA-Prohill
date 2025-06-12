import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/petugas_screen/Home_Konten.dart';
import 'package:dlh_project/pages/petugas_screen/akun_petugas.dart';
import 'package:dlh_project/pages/petugas_screen/activityPetugas.dart';
import 'package:dlh_project/pages/warga_screen/Berita.dart';
import 'package:dlh_project/pages/warga_screen/history.dart';
import 'package:dlh_project/pages/warga_screen/uptd.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePetugasPage extends StatefulWidget {
  final int initialIndex; // 🆕 Tambahan untuk mengatur tab awal
  
  const HomePetugasPage({super.key, this.initialIndex = 0});
  
  @override
  State<HomePetugasPage> createState() => _HomePetugasPageState();
}

class _HomePetugasPageState extends State<HomePetugasPage> {
  late int _selectedIndex;
  String? userName;
  int? userId;
  String? userRole;
  bool _isLoggedIn = false;
  
  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 🆕 Gunakan initialIndex saat init
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userId = prefs.getInt('user_id') ?? 0;
      userRole = prefs.getString('user_role') ?? 'warga'; // Default ke 'warga'
      _isLoggedIn = userName != 'Guest';
      
      // Jika bukan petugas, tampilkan dialog peringatan
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
              Navigator.of(context).pop(); // Tutup dialog
              Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          // Gradient shadow effect
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 0
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.home_rounded,
                    size: 24,
                    color: _selectedIndex == 0 ? Colors.white : Colors.grey[600],
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 1
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.assignment_rounded,
                    size: 24,
                    color: _selectedIndex == 1 ? Colors.white : Colors.grey[600],
                  ),
                ),
                label: 'Aktivitas',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 2
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.article_rounded,
                    size: 24,
                    color: _selectedIndex == 2 ? Colors.white : Colors.grey[600],
                  ),
                ),
                label: 'Berita',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 3
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 24,
                    color: _selectedIndex == 3 ? Colors.white : Colors.grey[600],
                  ),
                ),
                label: 'UPTD/TPS',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _selectedIndex == 4
                      ? BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF8A65), Color(0xFFFF7043)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.4),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  child: Icon(
                    Icons.person_rounded,
                    size: 24,
                    color: _selectedIndex == 4 ? Colors.white : Colors.grey[600],
                  ),
                ),
                label: 'Akun',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFFFF7043),
            unselectedItemColor: Colors.grey[600],
            onTap: _onItemTapped,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFF7043),
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}