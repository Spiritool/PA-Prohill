import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sampah.dart'; // Import model SampahLiarData
import 'package:url_launcher/url_launcher.dart';

class DetailSampahLiarPage extends StatelessWidget {
  final SampahLiarData sampah;

  const DetailSampahLiarPage({super.key, required this.sampah});

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
                    const Icon(Icons.assignment_ind, size: 32),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nama",
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
                    const Icon(Icons.phone, size: 32),
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
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text("Chat via WA"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 86, 229, 91)),
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
                  icon: const Icon(Icons.map_outlined),
                  label: const Text("Cek Lokasi"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 86, 229, 91)),
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
                    const Icon(Icons.fact_check_outlined, size: 32),
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
                    const Icon(Icons.calendar_today_outlined, size: 32),
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
            const Row(
              children: [
                Icon(Icons.notes, size: 32),
                SizedBox(width: 8),
                Text("Deskripsi",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(sampah.deskripsi),
            const SizedBox(height: 16),

            // Foto bukti
            const Row(
              children: [
                Icon(Icons.photo_camera_back, size: 32),
                SizedBox(width: 8),
                Text("Foto", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            _buildBuktiFoto([sampah.fotoSampah]),
            const SizedBox(height: 24),

            // Tombol proses
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Logika pemrosesan bisa ditambahkan di sini
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8F5E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                ),
                child: const Text("Proses",
                    style: TextStyle(fontSize: 18, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuktiFoto(List<String> fotoUrls) {
    const baseUrl = 'https://jera.kerrissumenep.com/storage/foto-sampah/';

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
