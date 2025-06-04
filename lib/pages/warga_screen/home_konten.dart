import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/detail_berita.dart';
import 'package:dlh_project/pages/warga_screen/harga_sampah.dart';
import 'package:dlh_project/pages/warga_screen/chat.dart';
import 'package:dlh_project/pages/warga_screen/point.dart';
import 'package:dlh_project/pages/warga_screen/qna.dart';
import 'package:dlh_project/pages/warga_screen/rangking.dart';
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
    const String url = "https://prohildlhcilegon.id/api/setting";

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
            // Konten utama, termasuk background orange dan isi konten
            Positioned.fill(
              child: Column(
                children: [
                  Container(
                    height: 220,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
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
                        const SizedBox(height: 12),
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
                        Text(
                          DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              child: Column(
                children: [
                  const SizedBox(
                      height: 130), // untuk jarak dari header ke bawah
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // My Services Title
                              Text(
                                'My Services',
                                style: GoogleFonts.poppins(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 15),

                              // Horizontal ListView untuk berita (pakai FutureBuilder)
                              Row(
                                children: [
                                  Expanded(
                                    child: FutureBuilder<List<dynamic>>(
                                      future: fetchBerita(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                              child:
                                                  CircularProgressIndicator());
                                        } else if (snapshot.hasError) {
                                          return Center(
                                              child: Text(
                                                  'Error: ${snapshot.error}'));
                                        } else if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return const Center(
                                              child: Text('No data available'));
                                        }

                                        final beritaList =
                                            snapshot.data!.reversed.toList();

                                        return Container(
                                          padding: const EdgeInsets.all(5),
                                          height: 170,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: beritaList.length,
                                            itemBuilder: (context, index) {
                                              final berita = beritaList[index];
                                              final gambarUrl =
                                                  'https://prohildlhcilegon.id/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                width: 250,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                DetailBerita(
                                                                    berita:
                                                                        berita),
                                                          ),
                                                        );
                                                      },
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                        child: Image.network(
                                                          gambarUrl,
                                                          fit: BoxFit.cover,
                                                          width: 250,
                                                          height: 150,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 100,
                                                            );
                                                          },
                                                          loadingBuilder: (context,
                                                              child,
                                                              loadingProgress) {
                                                            if (loadingProgress ==
                                                                null) {
                                                              return child;
                                                            }
                                                            return Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                value: loadingProgress
                                                                            .expectedTotalBytes !=
                                                                        null
                                                                    ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        (loadingProgress.expectedTotalBytes ??
                                                                            1)
                                                                    : null,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // GridView ikon layanan
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                childAspectRatio: 0.8,
                                children: [
                                  iconButton(context, Icons.recycling,
                                      'Sampah\nTerpilah', () {
                                    if (userName == 'Guest') {
                                      _showLoginRequiredDialog(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SampahTerpilah(),
                                        ),
                                      );
                                    }
                                  }),
                                  iconButton(
                                      context,
                                      Icons.delete_forever_outlined,
                                      'Sampah\nLiar', () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SampahLiar(),
                                      ),
                                    );
                                  }),
                                  iconButton(context, Icons.attach_money,
                                      'Harga\nSampah', () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const HargaSampah(),
                                      ),
                                    );
                                  }),
                                  iconButton(
                                      context,
                                      Icons.emoji_events_outlined,
                                      'Leaderboard\nRecycling', () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LeaderboardPage(),
                                      ),
                                    );
                                  }),
                                  iconButton(context, Icons.feedback_outlined,
                                      'Feedback', () async {
                                    final token = await FirebaseMessaging
                                        .instance
                                        .getToken();
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
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Tutup'),
                                          )
                                        ],
                                      ),
                                    );
                                  }),
                                  iconButton(context, Icons.card_giftcard,
                                      'Point\nReward!', () {
                                    if (userName == 'Guest') {
                                      _showLoginRequiredDialog(context);
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PointScreen(),
                                        ),
                                      );
                                    }
                                  }),
                                ],
                              ),

                              const SizedBox(height: 25),

                              // Awareness Community Title
                              Text('Awareness Community',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),

                              // ListView horizontal Awareness Community
                              SizedBox(
                                height: 170,
                                child: FutureBuilder<List<dynamic>>(
                                  future: fetchBerita(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'));
                                    } else if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return const Center(
                                          child: Text('No data available'));
                                    }

                                    final beritaList = snapshot.data!;

                                    return ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: beritaList.map((berita) {
                                        final gambarUrl =
                                            'https://prohildlhcilegon.id/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';
                                        final judul = berita['judul'] ??
                                            'Judul Tidak Tersedia';

                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DetailBerita(
                                                        berita: berita),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 192,
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: Image.network(
                                                    gambarUrl,
                                                    width: 192,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return Container(
                                                        width: 192,
                                                        height: 120,
                                                        color: Colors.grey[300],
                                                        child: const Icon(
                                                            Icons.broken_image),
                                                      );
                                                    },
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return const SizedBox(
                                                        width: 192,
                                                        height: 120,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2),
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
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ======= Avatar + Popup =======
            Positioned(
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
            ),

            // Popup di atas avatar
            if (_showPopup)
              Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPopup = false;
                        });
                      },
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 130,
                    right: 30,
                    child: Material(
                      elevation: 5,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Total Point",
                              style: TextStyle(
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
                                    Image.asset('assets/icons/money 4.png',
                                        width: 24, height: 24),
                                    SizedBox(width: 6),
                                    Text(
                                      "1",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 32),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 20),
                                  child: GestureDetector(
                                    onTap: () {
                                      if (userName == 'Guest') {
                                        _showLoginRequiredDialog(context);
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PointScreen(),
                                          ),
                                        );
                                      }
                                    },
                                    child: Icon(Icons.chevron_right, size: 24),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Overlay gelap saat popup aktif (kalau popup lain juga ada)
            // (Kalau popup avatar sudah ada overlay ini, bisa dihapus untuk menghindari dobel)

            // FAB kanan bawah dengan overlay saat popup aktif
            Positioned(
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
                          ),
                        );
                      } else {
                        _showLoginRequiredDialog(context);
                      }
                    },
                    backgroundColor: Color(0xFFFF6600),
                    child: const Icon(Icons.support_agent, color: Colors.white),
                  ),
                  if (_showPopup)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
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
    final response =
        await http.get(Uri.parse('https://prohildlhcilegon.id/api/berita'));
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
