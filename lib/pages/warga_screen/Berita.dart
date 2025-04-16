import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dlh_project/pages/warga_screen/detail_berita.dart';

class Berita extends StatelessWidget {
  const Berita({super.key});

  Future<List<dynamic>> fetchBerita() async {
    final response =
        await http.get(Uri.parse('https://jera.kerissumenep.com/api/berita'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: fetchBerita(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada data tersedia'));
            }

            final beritaList = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'NEWS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // // Search Bar
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 12),
                  //   decoration: BoxDecoration(
                  //     color: Colors.grey[200],
                  //     borderRadius: BorderRadius.circular(25),
                  //   ),
                  //   child: Row(
                  //     children: const [
                  //       Icon(Icons.search, color: Colors.grey),
                  //       SizedBox(width: 10),
                  //       Expanded(
                  //         child: TextField(
                  //           decoration: InputDecoration(
                  //             border: InputBorder.none,
                  //             hintText: 'Search News...',
                  //           ),
                  //         ),
                  //       ),
                  //       CircleAvatar(
                  //         radius: 16,
                  //         backgroundColor: Colors.orange,
                  //         child: Icon(Icons.arrow_forward,
                  //             color: Colors.white, size: 16),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  const SizedBox(height: 20),

                  // Latest News
                  const Text(
                    'Latest News',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tampilkan berita utama secara vertikal
                  // Latest News scrollable horizontally
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: beritaList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _buildMainNewsCard(context, beritaList[index]),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Kategori
                  // _buildCategoryChips(),

                  const SizedBox(height: 10),

                  // Berita Lainnya
                  ...beritaList
                      .sublist(1)
                      .map((berita) => _buildListNewsCard(context, berita))
                      .toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainNewsCard(BuildContext context, dynamic berita) {
    final gambarUrl =
        'https://jera.kerissumenep.com/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailBerita(berita: berita),
          ),
        );
      },
      child: Container(
        width: 300, // <- Tambahkan lebar untuk card horizontal
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                gambarUrl,
                height: 155,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 60),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita['judul'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.edit, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Amal Jos Chacko',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text(
                        '5 hours ago',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[600]),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListNewsCard(BuildContext context, dynamic berita) {
    final gambarUrl =
        'https://jera.kerissumenep.com/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailBerita(berita: berita)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                gambarUrl,
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita['judul'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.edit, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        berita['penulis'] ?? 'Unknown',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        'Innovation',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                      const Spacer(),
                      Text(
                        '7 hours ago',
                        style:
                            TextStyle(fontSize: 12, color: Colors.orange[700]),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildCategoryChips() {
  //   final categories = ['All', 'Science', 'Health', 'Culture'];
  //   return SizedBox(
  //     height: 36,
  //     child: ListView.builder(
  //       scrollDirection: Axis.horizontal,
  //       itemCount: categories.length,
  //       itemBuilder: (context, index) {
  //         final isActive = index == 0;
  //         return Padding(
  //           padding: const EdgeInsets.only(right: 10),
  //           child: Chip(
  //             label: Text(categories[index]),
  //             backgroundColor: isActive ? Colors.orange : Colors.grey[200],
  //             labelStyle: TextStyle(
  //               color: isActive ? Colors.white : Colors.black,
  //             ),
  //           ),
  //         );
  //       },
  //     ),
  //   );
  // }
}
