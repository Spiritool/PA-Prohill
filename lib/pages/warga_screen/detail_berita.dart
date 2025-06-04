import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class DetailBerita extends StatelessWidget {
  final dynamic berita;

  const DetailBerita({super.key, required this.berita});

  @override
  Widget build(BuildContext context) {
    final gambarUrl =
        '$baseipapi/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Tombol kembali di kiri
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.chevron_left, size: 28),
                      ),
                    ),

                    // Teks NEWS di tengah
                    const Center(
                      child: Text(
                        'NEWS',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                    // // Notifikasi di kanan
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: Stack(
                    //     children: [
                    //       const Icon(Icons.notifications_none, size: 28),
                    //       Positioned(
                    //         right: 0,
                    //         child: Container(
                    //           padding: const EdgeInsets.all(3),
                    //           decoration: const BoxDecoration(
                    //             color: Colors.red,
                    //             shape: BoxShape.circle,
                    //           ),
                    //           child: const Text(
                    //             '3',
                    //             style: TextStyle(
                    //               color: Colors.white,
                    //               fontSize: 10,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),
              // Gambar berita dengan ukuran lebih kecil
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Rasio lebar:tinggi seperti pada desain
                  child: Image.network(
                    gambarUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 100);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Konten berita
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      berita['judul'] ?? 'Judul Berita',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Penulis dan waktu
                    Row(
                      children: [
                        const Icon(Icons.edit, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          berita['penulis'] ?? 'Nama Penulis',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const Spacer(),
                        Text(
                          berita['waktu'] ?? '5 hours ago',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Deskripsi
                    Text(
                      berita['description'] ?? 'Deskripsi tidak tersedia.',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
