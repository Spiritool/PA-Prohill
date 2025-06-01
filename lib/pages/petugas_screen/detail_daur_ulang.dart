import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sampah.dart'; // Import model SampahLiarData
import 'penimbangan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/pages/petugas_screen/mapPetugasSingle.dart';

class DetailSampahDaurUlangPage extends StatelessWidget {
  final SampahData sampah;

  const DetailSampahDaurUlangPage({super.key, required this.sampah});

  Future<void> updateStatusSampahDaurUlang(
      int idSampah, int idUserPetugas, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        // 'https://prohildlhcilegon.id/api/pengangkutan-sampah/proses/$idSampah';
        'http://192.168.1.21:8000/api/pengangkutan-sampah/proses/$idSampah';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'id_user_petugas': idUserPetugas,
    };

    try {
      // Debugging: Print request details
      print('Request URL: $apiUrl');
      print('Request Headers: $headers');
      print('Request Body: ${json.encode(body)}');

      // Send the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Status updated successfully.');
      } else {
        print('Error: API URL: $apiUrl');
        print('Error status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        // Handle the error
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        throw Exception('Failed to update status: $errorMessage');
      }
    } catch (e) {
      // Handle any exceptions
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> updateStatusFailed(int idSampah, int idUserPetugas) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        'https://prohildlhcilegon.id/api/pengangkutan-sampah/failed/$idSampah';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'id_user_petugas': idUserPetugas,
    };

    try {
      // Send the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Status updated successfully.');
      } else {
        // Handle the error
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        throw Exception('Failed to update status: $errorMessage');
      }
    } catch (e) {
      // Handle any exceptions
      throw Exception('Error updating status: $e');
    }
  }

  void _launchWhatsApp(String phone) async {
    final url = "https://wa.me/$phone";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _launchMaps(String lokasi) async {
    final url = Uri.encodeFull(
        "https://www.google.com/maps/search/?api=1&query=$lokasi");
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Laporan Pending Sampah Liar"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama dan UPT
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/detail/nama_detail.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nama",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(sampah.name ?? "-"),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // No HP dan tombol chat WA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/detail/nomor_detail.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("No. HP",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(sampah.noHp ?? "-"),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _launchWhatsApp(sampah.noHp ?? ""),
                  icon: Image.asset(
                    'assets/detail/wa_detail.png',
                    width: 32,
                    height: 32,
                  ),
                  label: const Text("Chat via WA"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 86, 229, 91)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lokasi dan tombol Maps
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/detail/alamat_detail.png',
                            width: 32,
                            height: 32,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Alamat",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${sampah.alamat.kecamatan ?? "-"}, "
                                  "${sampah.alamat.kelurahan ?? "-"}, "
                                  "${sampah.alamat.deskripsi ?? "-"}",
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                    // Kirim data ke halaman MapSingle
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapSingle(
                          sampah: sampah, isDaurUlang: true, // Mengirim objek sampah lengkap
                        ),
                      ),
                    );
                  },
                      icon: Image.asset(
                        'assets/detail/map_detail.png',
                        width: 32,
                        height: 32,
                      ),
                      label: const Text("Cek Lokasi"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 86, 229, 91),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),

            // Status dan Tanggal (dirapikan seperti No HP dan tombol WA)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/detail/status_detail.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Status",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(sampah.status ?? "-"),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Image.asset(
                      'assets/detail/tanggal_detail.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tanggal",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(DateFormat('dd-MM-yyyy').format(sampah.tanggal)),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 16),

            // Deskripsi
            Row(
              children: [
                Image.asset(
                  'assets/detail/deskripsi_detail.png',
                  width: 32,
                  height: 32,
                ),
                SizedBox(width: 8),
                Text("Deskripsi",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(sampah.deskripsi),
            const SizedBox(height: 16),

            // Foto bukti
            Row(
              children: [
                Image.asset(
                  'assets/detail/foto_detail.png',
                  width: 32,
                  height: 32,
                ),
                SizedBox(width: 8),
                Text("Foto", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _buildBuktiFoto([sampah.fotoSampah]),
            const SizedBox(height: 24),
          ],
        ),
      ),
      // Tombol Proses dan batal
      bottomNavigationBar: (sampah.status != "done")
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Tombol Batalkan
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Konfirmasi"),
                            content: const Text(
                                "Apakah kamu yakin ingin membatalkan laporan ini?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Ya"),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        final prefs = await SharedPreferences.getInstance();
                        final idUser = prefs.getInt('user_id') ?? 0;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        try {
                          await updateStatusFailed(sampah.id, idUser);
                          Navigator.pop(context); // Tutup loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Laporan berhasil dibatalkan')),
                          );
                          Navigator.pop(context, true); // Kembali dan refresh
                        } catch (e) {
                          Navigator.pop(context); // Tutup loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Gagal membatalkan laporan: $e')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFFFE4E1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Batalkan",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tombol Proses atau Penimbangan
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Konfirmasi"),
                            content: Text(
                              (sampah.status == "pending")
                                  ? "Apakah kamu yakin ingin memproses laporan ini?"
                                  : "Apakah kamu yakin ingin melanjutkan ke proses penimbangan?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text("Batal"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text("Ya"),
                              ),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        final prefs = await SharedPreferences.getInstance();
                        final idUser = prefs.getInt('user_id') ?? 0;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        if (sampah.status == "pending") {
                          await updateStatusSampahDaurUlang(
                            sampah.id,
                            idUser,
                            "proses",
                          );

                          Navigator.pop(context); // Tutup loading

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Status berubah menjadi Proses'),
                            ),
                          );

                          Navigator.pop(
                              context, true); // Refresh halaman sebelumnya
                        } else if (sampah.status == "proses") {
                          Navigator.pop(context); // Tutup loading

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Penimbangan(
                                idSampah: sampah.id,
                              ),
                            ),
                          );

                          if (result != null && result) {
                            Navigator.pop(context, true); // Refresh list
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD8F5E0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        (sampah.status == "pending")
                            ? "Proses"
                            : (sampah.status == "proses")
                                ? "Lanjut Penimbangan"
                                : "Selesai",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildBuktiFoto(List<String> fotoUrls) {
    const baseUrl = 'https://prohildlhcilegon.id/storage/foto-sampah/';

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: fotoUrls.length,
      itemBuilder: (context, index) {
        final fullUrl = baseUrl + fotoUrls[index];
        return Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Mencetak detail kesalahan ke konsol debug
            debugPrint('Gagal memuat gambar: $fullUrl');
            debugPrint('Error: $error');
            if (stackTrace != null) {
              debugPrint('StackTrace: $stackTrace');
            }

            // Menampilkan placeholder saat gambar gagal dimuat
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
              ),
            );
          },
        );
      },
    );
  }
}
