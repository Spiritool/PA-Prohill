import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/ScreenSampah.dart';
import 'package:dlh_project/pages/warga_screen/detail_berita.dart';
import 'package:dlh_project/pages/warga_screen/harga_sampah.dart';
import 'package:dlh_project/pages/warga_screen/chat.dart';
import 'package:dlh_project/pages/warga_screen/qna.dart';
import 'package:flutter/material.dart';
import 'package:dlh_project/pages/warga_screen/Berita.dart';
import 'package:dlh_project/pages/warga_screen/sampah_liar.dart';
import 'package:dlh_project/pages/warga_screen/sampah_terpilah.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class HomeKontenPetugas extends StatefulWidget {
  final int userId;

  const HomeKontenPetugas({super.key, required this.userId, required String userName});

  @override
  State<HomeKontenPetugas> createState() => _HomeKontenPetugasState();
}

class _HomeKontenPetugasState extends State<HomeKontenPetugas> {
  String? userName;
  String? _logoUrl;
  final List<String> _imageUrls = [];

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
    });
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 220,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6600),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                      DateFormat('MMMM dd, yyyy')
                                          .format(DateTime.now()),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ]),
                              const CircleAvatar(
                                backgroundImage: NetworkImage(
                                    'https://randomuser.me/api/portraits/men/1.jpg'),
                                radius: 24,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Services',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: FutureBuilder<List<dynamic>>(
                          //         future: fetchBerita(),
                          //         builder: (context, snapshot) {
                          //           if (snapshot.connectionState ==
                          //               ConnectionState.waiting) {
                          //             return const Center(
                          //                 child: CircularProgressIndicator());
                          //           } else if (snapshot.hasError) {
                          //             return Center(
                          //                 child:
                          //                     Text('Error: ${snapshot.error}'));
                          //           } else if (!snapshot.hasData ||
                          //               snapshot.data!.isEmpty) {
                          //             return const Center(
                          //                 child: Text('No data available'));
                          //           }

                          //           // Balik urutan daftar untuk mendapatkan yang terbaru di awal
                          //           final beritaList =
                          //               snapshot.data!.reversed.toList();

                          //           return Container(
                          //             padding: const EdgeInsets.all(5),
                          //             height: 170,
                          //             child: ListView.builder(
                          //               scrollDirection: Axis.horizontal,
                          //               itemCount: beritaList.length,
                          //               itemBuilder: (context, index) {
                          //                 final berita = beritaList[index];
                          //                 final gambarUrl =
                          //                     'https://prohildlhcilegon.id/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

                          //                 return Container(
                          //                   margin: const EdgeInsets.symmetric(
                          //                       horizontal: 8),
                          //                   width: 250,
                          //                   child: Column(
                          //                     crossAxisAlignment:
                          //                         CrossAxisAlignment.start,
                          //                     children: [
                          //                       GestureDetector(
                          //                         onTap: () {
                          //                           Navigator.push(
                          //                             context,
                          //                             MaterialPageRoute(
                          //                               builder: (context) =>
                          //                                   DetailBerita(
                          //                                       berita: berita),
                          //                             ),
                          //                           );
                          //                         },
                          //                         child: ClipRRect(
                          //                           borderRadius:
                          //                               BorderRadius.circular(
                          //                                   15), // Menentukan kelengkungan sudut
                          //                           child: Image.network(
                          //                             gambarUrl,
                          //                             fit: BoxFit.cover,
                          //                             width: 250,
                          //                             height: 150,
                          //                             errorBuilder: (context,
                          //                                 error, stackTrace) {
                          //                               return const Icon(
                          //                                 Icons.broken_image,
                          //                                 size: 100,
                          //                               );
                          //                             },
                          //                             loadingBuilder: (context,
                          //                                 child,
                          //                                 loadingProgress) {
                          //                               if (loadingProgress ==
                          //                                   null) {
                          //                                 return child;
                          //                               }
                          //                               return Center(
                          //                                 child:
                          //                                     CircularProgressIndicator(
                          //                                   value: loadingProgress
                          //                                               .expectedTotalBytes !=
                          //                                           null
                          //                                       ? loadingProgress
                          //                                               .cumulativeBytesLoaded /
                          //                                           (loadingProgress
                          //                                                   .expectedTotalBytes ??
                          //                                               1)
                          //                                       : null,
                          //                                 ),
                          //                               );
                          //                             },
                          //                           ),
                          //                         ),
                          //                       ),
                          //                     ],
                          //                   ),
                          //                 );
                          //               },
                          //             ),
                          //           );
                          //         },
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 0.8,
                            children: [
                              iconButton(context, Icons.attach_money,
                                  'Hitung\nExchange', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HargaSampah(),
                                  ),
                                );
                              }),
                              iconButton(context, Icons.emoji_events_outlined,
                                  'Join Contest\n& Win', () {}),
                              iconButton(context, Icons.feedback_outlined,
                                  'Feedback', () {}),
                              iconButton(context, Icons.play_circle_outline,
                                  'Tutorial', () {}),
                              iconButton(
                                  context,
                                  Icons.videogame_asset_outlined,
                                  'Play &\nReward!',
                                  () {}),
                            ],
                          ),
                          const SizedBox(height: 25),
                          Text('Latest News',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
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
                                      child: Text('Error: ${snapshot.error}'));
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
                                                DetailBerita(berita: berita),
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
                                            // Gambar
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                gambarUrl,
                                                width: 192,
                                                height: 120,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    width: 192,
                                                    height: 120,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                        Icons.broken_image),
                                                  );
                                                },
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return const SizedBox(
                                                    width: 192,
                                                    height: 120,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Judul
                                            Text(
                                              judul,
                                              style: const TextStyle(
                                                fontSize:
                                                    11, // Ukuran kecil tapi tetap kebaca di mobile
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
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  if (userName != 'Guest') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          userId: widget
                              .userId, // Ganti dengan userId yang ada di HomeKonten
                          userName: userName ??
                              'Guest', // Ganti dengan userName yang ada atau default ke 'Guest'
                        ),
                      ),
                    );
                  } else {
                    // Tindakan alternatif jika user adalah Guest (misalnya menampilkan dialog atau halaman lain)
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Not Authorized'),
                          content:
                              Text('You must be logged in to access the chat.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                backgroundColor: Colors.green, // Warna tombol
                child: const Icon(Icons.support_agent, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLoginRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Login Diperlukan"),
        content: const Text(
            'Anda harus login terlebih dahulu untuk mengakses halaman ini.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Arahkan ke halaman login jika diperlukan
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
            child: const Text('Login'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
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
