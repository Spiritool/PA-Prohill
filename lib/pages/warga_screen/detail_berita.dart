import 'package:flutter/material.dart';

class DetailBerita extends StatelessWidget {
  final dynamic berita;

  const DetailBerita({super.key, required this.berita});

  @override
  Widget build(BuildContext context) {
    final gambarUrl =
        'https://jera.kerissumenep.com/storage/gambar-berita/${berita['gambar_konten'][0]['nama']}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Detail Berita'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan gambar
            Image.network(
              gambarUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, size: 100);
              },
            ),
            const SizedBox(height: 16),

            // Menampilkan judul berita
            Text(
              berita['judul'] ?? 'Judul Berita',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Menampilkan deskripsi berita
            Text(
              berita['description'] ?? 'Deskripsi tidak tersedia.',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
