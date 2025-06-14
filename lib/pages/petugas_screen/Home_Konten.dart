import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/petugas_screen/mapPetugas.dart';
import 'package:dlh_project/pages/petugas_screen/sop_petugas.dart';
import 'package:dlh_project/pages/warga_screen/detail_berita.dart';
import 'package:dlh_project/pages/warga_screen/harga_sampah.dart';
import 'package:dlh_project/pages/petugas_screen/leaderboard_petugas.dart';
import 'package:dlh_project/pages/petugas_screen/pointPetugas.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class HomeKontenPetugas extends StatefulWidget {
  final int userId;

  const HomeKontenPetugas(
      {super.key, required this.userId, required String userName});

  @override
  State<HomeKontenPetugas> createState() => _HomeKontenPetugasState();
}

class _HomeKontenPetugasState extends State<HomeKontenPetugas> {
  String? userName;
  String? userProfilePhoto;
  String? _logoUrl;
  final List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchSettings();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userProfilePhoto = prefs.getString('user_profile_photo');
    });
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
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  customBorder: CircleBorder(),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding: EdgeInsets.all(10),
                                          child: Align(
                                            alignment: Alignment.topRight,
                                            child: Container(
                                              width: 160,
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black26,
                                                    blurRadius: 10,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Total Point',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                              Icons
                                                                  .monetization_on,
                                                              color: Colors
                                                                  .orange),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            '1',
                                                            style: GoogleFonts
                                                                .poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Icon(Icons.arrow_forward_ios,
                                                      size: 16),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.grey[300],
                                    child: userProfilePhoto != null &&
                                            userProfilePhoto!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              userProfilePhoto!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.network(
                                                  'https://randomuser.me/api/portraits/men/1.jpg',
                                                  width: 48,
                                                  height: 48,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Icon(
                                                      Icons.person,
                                                      size: 24,
                                                      color: Colors.grey[600],
                                                    );
                                                  },
                                                );
                                              },
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                                Color>(
                                                            Color(0xFFFF6600)),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                        : ClipOval(
                                            child: Image.network(
                                              'https://randomuser.me/api/portraits/men/1.jpg',
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  size: 24,
                                                  color: Colors.grey[600],
                                                );
                                              },
                                            ),
                                          ),
                                  ),
                                ),
                              )
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
                          //                     '$baseipapi/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

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
                              // Icon buttons yang telah diperbaiki
                              iconButton(context, Icons.attach_money,
                                  'Hitung\nExchange', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HargaSampah(),
                                  ),
                                );
                              }),

// Uncomment jika diperlukan
// iconButton(
//   context,
//   Icons.emoji_events_outlined,
//   'Join Contest\n& Win',
//   () {
//     // Tambahkan fungsi untuk contest
//   }
// ),

                              iconButton(
                                  context,
                                  Icons
                                      .leaderboard_outlined, // Ganti icon untuk lebih sesuai
                                  'Peringkat', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        LeaderboardPagePetugas(),
                                  ),
                                );
                              }),

                              iconButton(
                                  context,
                                  Icons
                                      .stars_outlined, // Ganti icon untuk Point Petugas
                                  'Point Petugas', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PointScreenPetugas(),
                                  ),
                                );
                                // Tambahkan navigasi ke halaman Point Petugas
                              }),

                              iconButton(
                                  context,
                                  Icons
                                      .assignment_outlined, // Ganti icon untuk SOP
                                  'SOP Petugas', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SopPetugasPage(),
                                  ),
                                );
                              }),

                              iconButton(
                                  context,
                                  Icons.map_outlined, // Ganti icon untuk Map
                                  'Map Rute', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const mapPetugas(), // Pastikan nama class konsisten (huruf besar)
                                  ),
                                );
                              }),
                              // iconButton(
                              //     context,
                              //     Icons.videogame_asset_outlined,
                              //     'Play &\nReward!',
                              //     () {}),
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
                                        '$baseipapi/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';
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
                  // if (userName != 'Guest') {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => ChatPage(
                  //         userId: widget
                  //             .userId, // Ganti dengan userId yang ada di HomeKonten
                  //         userName: userName ??
                  //             'Guest', // Ganti dengan userName yang ada atau default ke 'Guest'
                  //       ),
                  //     ),
                  //   );
                  // } else {
                  //   // Tindakan alternatif jika user adalah Guest (misalnya menampilkan dialog atau halaman lain)
                  //   showDialog(
                  //     context: context,
                  //     builder: (BuildContext context) {
                  //       return AlertDialog(
                  //         title: Text('Not Authorized'),
                  //         content:
                  //             Text('You must be logged in to access the chat.'),
                  //         actions: <Widget>[
                  //           TextButton(
                  //             onPressed: () {
                  //               Navigator.pop(context);
                  //             },
                  //             child: Text('OK'),
                  //           ),
                  //         ],
                  //       );
                  //     },
                  //   );
                  // }
                },
                // backgroundColor: Colors.green, // Warna tombol
                // child: const Icon(Icons.support_agent, color: Colors.white),
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
