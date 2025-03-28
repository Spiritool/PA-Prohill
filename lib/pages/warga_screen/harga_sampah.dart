import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HargaSampah extends StatefulWidget {
  const HargaSampah({super.key});

  @override
  State<HargaSampah> createState() => _HargaSampahState();
}

class _HargaSampahState extends State<HargaSampah> {
  final String baseUrl = 'https://jera.kerissumenep.com'; // Base URL API

  Future<List<dynamic>> fetchHargaSampah() async {
    final response = await http.get(Uri.parse('$baseUrl/api/harga-barang'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Gagal koneksi ke API');
    }
  }

  String formatHarga(String harga) {
    double? hargaDouble = double.tryParse(harga);
    if (hargaDouble == null) return '0'; // Jika parsing gagal, kembalikan 0
    return hargaDouble % 1 == 0
        ? hargaDouble
            .toInt()
            .toString() // Jika bilangan bulat, tampilkan tanpa desimal
        : hargaDouble
            .toString(); // Jika ada desimal selain .00, tetap tampilkan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Harga Sampah',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchHargaSampah(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final hargaSampahList = snapshot.data!;

          return ListView.builder(
            itemCount: hargaSampahList.length,
            itemBuilder: (context, index) {
              final item = hargaSampahList[index] as Map<String, dynamic>;

              final namaBarang = item['Nama_Barang'] ?? 'Tidak tersedia';
              final hargaBeli = item['Harga_Beli'] ?? '0';
              String gambarUrl = item['gambar'] ?? '';

              if (gambarUrl.isNotEmpty) {
                gambarUrl = '$baseUrl$gambarUrl'.replaceAll(r'\', '');
              } else {
                gambarUrl = 'https://via.placeholder.com/150';
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: GestureDetector(
                          onTap: () {},
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
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        namaBarang,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Harga: Rp${formatHarga(hargaBeli)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
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
