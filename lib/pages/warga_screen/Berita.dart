import 'dart:convert';
import 'package:dlh_project/pages/warga_screen/detail_berita.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = 10.0;
    double imageWidth = screenWidth - padding;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Berita',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
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

          return ListView.builder(
            padding: const EdgeInsets.all(5),
            itemCount: beritaList.length,
            itemBuilder: (context, index) {
              final berita = beritaList[index];
              // ignore: prefer_interpolation_to_compose_strings
              final gambarUrl =
                  // ignore: prefer_interpolation_to_compose_strings
                  'https://jera.kerissumenep.com/storage/gambar-berita/' +
                      berita['gambar_konten'][0]['nama'];

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailBerita(berita: berita),
                              ),
                            );
                          },
                          child: Image.network(
                            gambarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 100);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: imageWidth,
                      child: Text(
                        berita['judul'],
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
