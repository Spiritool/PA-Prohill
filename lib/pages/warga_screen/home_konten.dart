import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/detail_berita.dart';
import 'package:dlh_project/pages/warga_screen/harga_sampah.dart';
import 'package:dlh_project/pages/warga_screen/chat.dart';
import 'package:dlh_project/pages/warga_screen/point.dart';
import 'package:dlh_project/pages/warga_screen/qna.dart';
import 'package:dlh_project/pages/warga_screen/rangking.dart';
import 'package:dlh_project/pages/warga_screen/saldo.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:dlh_project/pages/warga_screen/Berita.dart';
import 'package:dlh_project/pages/warga_screen/sampah_liar.dart';
import 'package:dlh_project/pages/warga_screen/sampah_terpilah.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class HomeKonten extends StatefulWidget {
  final int userId;

  const HomeKonten({super.key, required this.userId, required String userName});

  @override
  State<HomeKonten> createState() => _HomeKontenState();
}

class _HomeKontenState extends State<HomeKonten> {
  String? fcmToken = '';
  String? userName;
  String? _logoUrl;
  String? userPhoto;
  final List<String> _imageUrls = [];
  bool _showPopup = false;
  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
    fetchSettings();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userPhoto = prefs.getString('user_profile_photo'); // Ambil foto
    });
  }

  ImageProvider<Object> _getProfileImage() {
    try {
      if (userPhoto != null && userPhoto!.isNotEmpty) {
        if (userPhoto!.startsWith('http')) {
          return NetworkImage(userPhoto!);
        } else {
          return FileImage(File(userPhoto!));
        }
      }
    } catch (_) {
      // fallback default
    }
    return const NetworkImage('https://randomuser.me/api/portraits/men/1.jpg');
  }

  Future<List<String>> fetchSettings() async {
    final String url = "$baseipapi/api/setting";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> settingsData = data['data'];

          final List<String> logoUrls = settingsData
              .where((item) =>
                  item is Map<String, dynamic> &&
                  item['nama_aplikasi'] != "Jerapah App" &&
                  item['logo_aplikasi'] != null)
              .map((item) => item['logo_aplikasi'] as String)
              .toList();

          return logoUrls;
        } else {
          return [];
        }
      } else {
        throw Exception(
            'Failed to load setting data: Status code \${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching setting data: \$e');
    }
  }

  Widget serviceCard(String title, String imageUrl) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image:
            DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(8),
      child: Text(title,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Widget iconButton(BuildContext context, IconData icon, String label,
      VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Icon(icon, color: const Color(0xFFFF6600), size: 36),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget communityCard(String title, String imageUrl) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image:
            DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.all(8),
      child: Text(title,
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main content structure
            Column(
              children: [
                // Header with orange background
                Container(
                  height: 220, // Restored original height
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6600),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header title
                      Center(
                        child: Text(
                          'Home',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile section with avatar, name, and date
                      Row(
                        children: [
                          // Name and date column (dibiarkan di sebelah kiri)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Greeting text
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Hi, ',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: userName ?? 'Guest',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 5),
                                // Date
                                Text(
                                  DateFormat('MMMM dd, yyyy')
                                      .format(DateTime.now()),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 15),

                          // Avatar (pindah ke kanan)
                          GestureDetector(
                            onTap: _togglePopup,
                            child: (userName != 'Guest')
                                ? CircleAvatar(
                                    radius: 30,
                                    backgroundImage: _getProfileImage(),
                                  )
                                : const CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(
                                        'https://randomuser.me/api/portraits/men/1.jpg'),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content area with white background
                Expanded(
                  child: Container(
                    color: Colors
                        .grey[100], // Background color for the remaining space
                  ),
                ),
              ],
            ),

            // Overlapping white content container
            Positioned(
              top: 160, // Adjusted position
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10), // Top padding for overlap

                        // My Services Title
                        Text(
                          'My Services',
                          style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),

                        // News horizontal ListView
                        _buildNewsSection(),
                        const SizedBox(height: 20),

                        // Service icons grid
                        _buildServiceGrid(),
                        const SizedBox(height: 25),

                        // Awareness Community Title
                        Text('Awareness Community',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),

                        // Awareness Community ListView
                        _buildAwarenessSection(),
                        const SizedBox(height: 5),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Popup overlay (only when popup is active)
            if (_showPopup) _buildPopupOverlayModified(),

            // FAB with overlay when popup is active
            _buildFloatingActionButton(),
          ],
        ),
      ),
    );
  }

// Alternative approach using Transform.translate for more control
  Widget buildAlternativeOverlap() {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(color: Colors.grey[100]),

            // Header
            Container(
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6600),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              // Header content here...
            ),

            // Overlapping content with Transform
            Transform.translate(
              offset: const Offset(
                  0, -40), // Move up by 40 pixels to create overlap
              child: Container(
                margin: const EdgeInsets.only(top: 260), // Position from top
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 60), // Space for overlap
                        // Your content here...
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Separate widget methods for better organization
  Widget _buildNewsSection() {
    return SizedBox(
      height: 170,
      child: FutureBuilder<List<dynamic>>(
        future: fetchBerita(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final beritaList = snapshot.data!.reversed.toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: beritaList.length,
            itemBuilder: (context, index) {
              final berita = beritaList[index];
              final gambarUrl =
                  '$baseipapi/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 250,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailBerita(berita: berita),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      gambarUrl,
                      fit: BoxFit.cover,
                      width: 250,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildServiceGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.8,
      children: [
        iconButton(context, Icons.recycling, 'Sampah\nTerpilah', () {
          if (userName == 'Guest') {
            _showLoginRequiredDialog(context);
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SampahTerpilah(),
                ));
          }
        }),
        iconButton(context, Icons.delete_forever_outlined, 'Sampah\nLiar', () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SampahLiar(),
              ));
        }),
        iconButton(context, Icons.attach_money, 'Harga\nSampah', () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HargaSampah(),
              ));
        }),
        iconButton(
            context, Icons.emoji_events_outlined, 'Leaderboard\nRecycling', () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LeaderboardPage(),
              ));
        }),
        iconButton(context, Icons.feedback_outlined, 'Feedback', () async {
          final token = await FirebaseMessaging.instance.getToken();
          setState(() {
            fcmToken = token ?? '-';
          });
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('FCM Token'),
              content: SelectableText(fcmToken!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                )
              ],
            ),
          );
        }),
        iconButton(context, Icons.card_giftcard, 'Point\nReward!', () {
          if (userName == 'Guest') {
            _showLoginRequiredDialog(context);
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PointScreen(),
                ));
          }
        }),
        iconButton(context, Icons.card_giftcard, 'Wallet\nSampah!', () {
          if (userName == 'Guest') {
            _showLoginRequiredDialog(context);
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SaldoSampahScreen(),
                ));
          }
        }),
      ],
    );
  }

  Widget _buildAwarenessSection() {
    return SizedBox(
      height: 170,
      child: FutureBuilder<List<dynamic>>(
        future: fetchBerita(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final beritaList = snapshot.data!;
          return ListView(
            scrollDirection: Axis.horizontal,
            children: beritaList.map((berita) {
              final gambarUrl =
                  'https://prohildlhcilegon.id/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';
              final judul = berita['judul'] ?? 'Judul Tidak Tersedia';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailBerita(berita: berita),
                      ));
                },
                child: Container(
                  width: 192,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          gambarUrl,
                          width: 192,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 192,
                              height: 120,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 192,
                              height: 120,
                              child: Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Positioned(
      top: 40,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(height: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              (userName != 'Guest')
                  ? GestureDetector(
                      onTap: _togglePopup,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: _getProfileImage(),
                      ),
                    )
                  : const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                          'https://randomuser.me/api/portraits/men/1.jpg'),
                    ),
              if (_showPopup)
                Positioned(
                  child: GestureDetector(
                    onTap: _togglePopup,
                    child: Material(
                      elevation: 4,
                      shape: const CircleBorder(),
                      color: Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.close, size: 40),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPopupOverlayModified() {
    return Stack(
      children: [
        // Background overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: () => setState(() => _showPopup = false),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),

        // Point popup - pindah ke kanan
        Positioned(
          top: 130, // Sesuaikan dengan posisi avatar
          right: 30, // Ganti dari left: 30
          child: _buildPopupCard(
            title: "Total Point",
            icon:
                Image.asset('assets/icons/money 4.png', width: 24, height: 24),
            value: "1",
            onTap: () {
              if (userName == 'Guest') {
                _showLoginRequiredDialog(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PointScreen(),
                    ));
              }
            },
          ),
        ),

        // Balance popup - pindah ke kanan
        Positioned(
          top: 200, // Sesuaikan dengan posisi avatar
          right: 30, // Ganti dari left: 30
          child: _buildPopupCard(
            title: "Balance",
            icon: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 14,
                color: Colors.green[700],
              ),
            ),
            value: "Rp 50.000",
            onTap: () {
              if (userName == 'Guest') {
                _showLoginRequiredDialog(context);
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SaldoSampahScreen(),
                    ));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopupCard({
    required String title,
    required Widget icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTap: onTap,
                  child: const Icon(Icons.chevron_right, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              if (userName != 'Guest') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        userId: widget.userId,
                        userName: userName ?? 'Guest',
                      ),
                    ));
              } else {
                _showLoginRequiredDialog(context);
              }
            },
            backgroundColor: const Color(0xFFFF6600),
            child: const Icon(Icons.support_agent, color: Colors.white),
          ),
          if (_showPopup)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
        ],
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Text(
                "Login Diperlukan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Anda harus login terlebih dahulu untuk mengakses halaman ini.',
            style: TextStyle(color: Colors.black87, fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  Future<List<dynamic>> fetchBerita() async {
    final response = await http.get(Uri.parse('$baseipapi/api/berita'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return data['data'];
      } else {
        throw Exception('Gagal untuk memuat berita');
      }
    } else {
      throw Exception('Gagal koneksi ke API');
    }
  }
}
