import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sampah.dart'; // Import model SampahLiarData
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inputFotoSampah.dart';

class DetailSampahLiarPage extends StatelessWidget {
  final SampahLiarData sampah;

  const DetailSampahLiarPage({super.key, required this.sampah});

  Future<void> updateStatusSampahLiar(
      int idSampah, int idUserPetugas, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/proses/$idSampah';

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
        // Debugging: Print URL, status code, and response body when an error occurs
        // print('Error: API URL: $apiUrl');
        // print('Error status code: ${response.statusCode}');
        // print('Error response body: ${response.body}');

        // Check if the response is JSON before decoding
        try {
          final errorMessage =
              jsonDecode(response.body)['message'] ?? 'Unknown error';
          throw Exception('Failed to update status: $errorMessage');
        } catch (e) {
          // If response is not in JSON format, log the raw response
          throw Exception(
              'Failed to update status, received non-JSON response: ${response.body}');
        }
      }
    } catch (e) {
      // Handle any exceptions
      print('Error updating status: $e');
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> updateStatusFailedSampahLiar(
      int idSampah, int idUserPetugas) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        'https://prohildlhcilegon.id/api/pengangkutan-sampah-liar/failed/$idSampah';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'id_user_petugas': idUserPetugas,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Status updated successfully.');
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        throw Exception('Failed to update status: $errorMessage');
      }
    } catch (e) {
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
                      'assets/detail/email_detail.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Email",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(sampah.email ?? "-"),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map, size: 32),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Lokasi",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("test" ?? "-"),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _launchMaps(sampah.kordinat ?? ""),
                  icon: Image.asset(
                    'assets/detail/map_detail.png',
                    width: 32,
                    height: 32,
                  ),
                  label: const Text("Cek Lokasi"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 86, 229, 91)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status dan tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        const Text("Status",
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                        const Text("Tanggal",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('dd-MM-yyyy').format(sampah.tanggal)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

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

      // Tombol Batalkan dan Proses/Konfirmasi
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Tombol Batalkan
            Expanded(
              child: ElevatedButton(
                onPressed: (sampah.status == "done")
                    ? null
                    : () async {
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
                        final idUserPetugas = prefs.getInt('user_id') ?? 0;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        await updateStatusFailedSampahLiar(
                            sampah.id, idUserPetugas);

                        Navigator.pop(context); // Close loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Laporan berhasil dibatalkan')),
                        );
                        Navigator.pop(context, true); // Back to previous
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFE4E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Batalkan",
                    style: TextStyle(fontSize: 16, color: Colors.black)),
              ),
            ),
            const SizedBox(width: 16),

            // Tombol Proses/Konfirmasi
            Expanded(
              child: ElevatedButton(
                onPressed: (sampah.status == "selesai")
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Konfirmasi"),
                            content: Text(
                              (sampah.status == "pending")
                                  ? "Apakah kamu yakin ingin memproses laporan ini?"
                                  : "Apakah kamu yakin ingin mengonfirmasi laporan ini sebagai selesai?",
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
                        final idUserPetugas = prefs.getInt('user_id') ?? 0;

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );

                        if (sampah.status == "pending") {
                          await updateStatusSampahLiar(
                              sampah.id, idUserPetugas, 'proses');
                          Navigator.pop(context); // close loading
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Status berubah menjadi Proses')),
                          );
                          Navigator.pop(context, true);
                        } else if (sampah.status == "proses") {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  InputFotoSampah(idSampah: sampah.id),
                            ),
                          );
                          if (result != null && result) {
                            await updateStatusSampahLiar(
                                sampah.id, idUserPetugas, 'selesai');
                            Navigator.pop(context); // close loading
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Status berhasil diperbarui menjadi Selesai')),
                            );
                            Navigator.pop(context, true);
                          } else {
                            Navigator.pop(context); // cancel upload
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
                          ? "Konfirmasi"
                          : "Selesai",
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
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
