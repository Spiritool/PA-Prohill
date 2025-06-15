import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sampah.dart'; // Import model SampahLiarData
import 'penimbangan.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/pages/petugas_screen/mapPetugasSingle.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class DetailSampahDaurUlangPage extends StatelessWidget {
  final SampahData sampah;

  const DetailSampahDaurUlangPage({super.key, required this.sampah});

  // Color theme constants
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8A50);
  static const Color lightOrange = Color(0xFFFFF4E6);
  static const Color darkOrange = Color(0xFFE55A2B);
  static const Color accentOrange = Color(0xFFFFB084);
  static const Color backgroundGrey = Color(0xFFF8F9FA);

  Future<void> updateStatusPengirimanHadiah(int idHadiah) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl = '$baseipapi/api/penukaran/$idHadiah/status';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'status': 'diantar',
    };

    try {
      // Debugging: Print request details
      print('Request URL: $apiUrl');
      print('Request Headers: $headers');
      print('Request Body: ${json.encode(body)}');

      // Send the POST request
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Status hadiah berhasil diupdate ke "diantar"');
      } else {
        print('Error: API URL: $apiUrl');
        print('Error status code: ${response.statusCode}');
        print('Error response body: ${response.body}');
        // Handle the error
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Unknown error';
        throw Exception('Failed to update status hadiah: $errorMessage');
      }
    } catch (e) {
      // Handle any exceptions
      throw Exception('Error updating status hadiah: $e');
    }
  }

  Future<void> updateStatusSampahDaurUlang(
      int idSampah, int idUserPetugas, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        // 'https://prohildlhcilegon.id/api/pengangkutan-sampah/proses/$idSampah';
        '$baseipapi/api/pengangkutan-sampah/proses/$idSampah';

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
        '$baseipapi/api/pengangkutan-sampah/failed/$idSampah';

    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final Map<String, dynamic> body = {
      'id_user_petugas': idUserPetugas,
    };

    try {
      // DEBUG: Print URL, headers, and body
      print('🔁 Sending POST to: $apiUrl');
      print('📦 Headers: $headers');
      print('📤 Body: ${jsonEncode(body)}');

      // Send the POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: json.encode(body),
      );

      // DEBUG: Print status code and response body
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Status updated successfully.');
      } else {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Unknown error';
        print('❌ Failed to update status: $errorMessage');
        throw Exception('Failed to update status: $errorMessage');
      }
    } catch (e) {
      print('🛑 Exception occurred: $e');
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
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        title: const Text(
          "Detail Laporan Sampah",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryOrange, secondaryOrange],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card with gradient
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [secondaryOrange, Colors.transparent],
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getStatusColor(sampah.status ?? ""),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        sampah.status?.toUpperCase() ?? "-",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama
                    _buildInfoRow(
                      icon: Icons.person,
                      title: "Nama Pelapor",
                      content: sampah.name ?? "-",
                      iconColor: primaryOrange,
                    ),
                    const SizedBox(height: 16),

                    // Tanggal
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      title: "Tanggal Laporan",
                      content:
                          DateFormat('dd MMMM yyyy').format(sampah.tanggal),
                      iconColor: primaryOrange,
                    ),
                  ],
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Contact Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Informasi Kontak"),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.phone,
                          title: "No. HP",
                          content: sampah.noHp ?? "-",
                          iconColor: primaryOrange,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          onPressed: () => _launchWhatsApp(sampah.noHp ?? ""),
                          icon: Icons.chat,
                          label: "Chat via WhatsApp",
                          color: const Color(0xFF25D366),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Lokasi"),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          title: "Alamat",
                          content: "${sampah.alamat.kecamatan ?? "-"}, "
                              "${sampah.alamat.kelurahan ?? "-"}, "
                              "${sampah.alamat.deskripsi ?? "-"}",
                          iconColor: primaryOrange,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapSingle(
                                  sampah: sampah,
                                  isDaurUlang: true,
                                ),
                              ),
                            );
                          },
                          icon: Icons.map,
                          label: "Cek Lokasi",
                          color: primaryOrange,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Deskripsi"),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: lightOrange,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: accentOrange.withOpacity(0.3)),
                          ),
                          child: Text(
                            sampah.deskripsi,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tambahkan bagian ini setelah Description Card dan sebelum Waste Collection Card

                  const SizedBox(height: 16),

                  // Hadiah Card (conditional) - tampilkan jika ada hadiah
                  if (sampah.namaHadiah.isNotEmpty)
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Hadiah Tukar Poin"),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryOrange.withOpacity(0.1),
                                  accentOrange.withOpacity(0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: primaryOrange.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                // Icon hadiah
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryOrange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Info hadiah
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Hadiah yang Dipilih",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sampah.namaHadiah,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      // if (sampah.hadiahId != null) ...[
                                      //   const SizedBox(height: 4),
                                      //   Text(
                                      //     "ID: ${sampah.hadiahId}",
                                      //     style: TextStyle(
                                      //       fontSize: 11,
                                      //       color: Colors.grey.shade600,
                                      //     ),
                                      //   ),
                                      // ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Waste Collection Card (conditional)
                  if (sampah.status == "done" &&
                      sampah.list != null &&
                      sampah.list!.isNotEmpty &&
                      sampah.list!.trim().isNotEmpty)
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Sampah Dikumpulkan"),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: lightOrange,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: accentOrange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildWasteList(sampah.list!),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Photo Card
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Foto Bukti"),
                        const SizedBox(height: 16),
                        _buildBuktiFoto([sampah.fotoSampah]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ],
        ),
      ),
      // Bottom Action Buttons
      bottomNavigationBar: (sampah.status != "done")
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleCancelAction(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      child: const Text(
                        "Batalkan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Process Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleProcessAction(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryOrange,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _getButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryOrange,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'proses':
        return Colors.blue;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getButtonText() {
    switch (sampah.status) {
      case "pending":
        return "Proses";
      case "proses":
        return "Lanjut Penimbangan";
      default:
        return "Selesai";
    }
  }

  void _handleCancelAction(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Konfirmasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Apakah kamu yakin ingin membatalkan laporan ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Ya",
              style: TextStyle(color: Colors.white),
            ),
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
        ),
      ),
    );

    try {
      await updateStatusFailed(sampah.id, idUser);
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Laporan berhasil dibatalkan'),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      Navigator.pop(context, true); // Kembali dan refresh
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membatalkan laporan: $e'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _handleProcessAction(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Konfirmasi",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          (sampah.status == "pending")
              ? "Apakah kamu yakin ingin memproses laporan ini?"
              : "Apakah kamu yakin ingin melanjutkan ke proses penimbangan?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Ya",
              style: TextStyle(color: Colors.white),
            ),
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
        ),
      ),
    );

    if (sampah.status == "pending") {
      try {
        // Update status sampah terlebih dahulu
        await updateStatusSampahDaurUlang(
          sampah.id,
          idUser,
          "proses",
        );

        // Jika ada hadiah, update status pengiriman hadiah
        if (sampah.hadiahId != null && sampah.namaHadiah.isNotEmpty) {
          await updateStatusPengirimanHadiah(sampah.hadiahId!);
          print('Status hadiah berhasil diupdate');
        }

        Navigator.pop(context); // Tutup loading

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sampah.hadiahId != null && sampah.namaHadiah.isNotEmpty
                  ? 'Status berubah menjadi Proses dan hadiah akan diantar'
                  : 'Status berubah menjadi Proses',
            ),
            backgroundColor: primaryOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        Navigator.pop(context, true); // Refresh halaman sebelumnya
      } catch (e) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses: $e'),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
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
  }

  // Method untuk membuat widget list sampah yang dikumpulkan
  List<Widget> _buildWasteList(String wasteListString) {
    List<Widget> widgets = [];

    // Cek jika string kosong atau null
    if (wasteListString.isEmpty) {
      return [
        const Text(
          "Tidak ada data sampah",
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ];
    }

    // Split string berdasarkan koma
    List<String> wasteItems = wasteListString.split(', ');

    for (String item in wasteItems) {
      if (item.trim().isEmpty) continue;

      // Split setiap item berdasarkan titik dua untuk memisahkan nama dan berat
      List<String> parts = item.split(': ');
      if (parts.length == 2) {
        String wasteName = parts[0].trim();
        String weight = parts[1].trim();

        // Skip jika nama atau berat kosong
        if (wasteName.isEmpty || weight.isEmpty) continue;

        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentOrange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wasteName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    weight,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Jika tidak ada item valid yang berhasil di-parse
    if (widgets.isEmpty) {
      return [
        const Text(
          "Format data tidak valid",
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ];
    }

    return widgets;
  }

  Widget _buildBuktiFoto(List<String> fotoUrls) {
    var baseUrl = '$baseipapi/storage/foto-sampah/';

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: fotoUrls.length,
      itemBuilder: (context, index) {
        final fullUrl = baseUrl + fotoUrls[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              fullUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Gagal memuat gambar: $fullUrl');
                debugPrint('Error: $error');
                if (stackTrace != null) {
                  debugPrint('StackTrace: $stackTrace');
                }

                return Container(
                  decoration: BoxDecoration(
                    color: lightOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: primaryOrange,
                          size: 48,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gambar tidak dapat dimuat',
                          style: TextStyle(
                            color: primaryOrange,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
