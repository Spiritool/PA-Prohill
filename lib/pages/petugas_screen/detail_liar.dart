import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sampah.dart'; // Import model SampahLiarData
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inputFotoSampah.dart';
import 'package:dlh_project/pages/petugas_screen/mapPetugasSingle.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class DetailSampahLiarPage extends StatelessWidget {
  final SampahLiarData sampah;

  const DetailSampahLiarPage({super.key, required this.sampah});

  // Color theme constants
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8A50);
  static const Color lightOrange = Color(0xFFFFF4E6);
  static const Color darkOrange = Color(0xFFE55A2B);
  static const Color accentOrange = Color(0xFFFFB084);
  static const Color backgroundGrey = Color(0xFFF8F9FA);

  Future<void> updateStatusSampahLiar(
      int idSampah, int idUserPetugas, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        '$baseipapi/api/pengangkutan-sampah-liar/proses/$idSampah';

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
        print('Error: API URL: $apiUrl');
        print('Error status code: ${response.statusCode}');
        print('Error response body: ${response.body}');

        try {
          final errorMessage =
              jsonDecode(response.body)['message'] ?? 'Unknown error';
          throw Exception('Failed to update status: $errorMessage');
        } catch (e) {
          throw Exception(
              'Failed to update status, received non-JSON response: ${response.body}');
        }
      }
    } catch (e) {
      print('Error updating status: $e');
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> updateStatusFailedSampahLiar(
      int idSampah, int idUserPetugas) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final String apiUrl =
        '$baseipapi/api/pengangkatan-sampah-liar/failed/$idSampah';

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'proses':
        return Colors.blue;
      case 'done':
      case 'selesai':
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
        return "Konfirmasi";
      default:
        return "Selesai";
    }
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

  Widget _buildBuktiFoto(List<String> fotoUrls) {
    final baseUrl = '$baseipapi/storage/foto-sampah/';
    
    // Filter out empty or null URLs
    final validUrls = fotoUrls.where((url) => url.isNotEmpty).toList();
    
    if (validUrls.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: lightOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentOrange.withOpacity(0.3)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: primaryOrange,
                size: 48,
              ),
              SizedBox(height: 8),
              Text(
                'Tidak ada foto bukti',
                style: TextStyle(
                  color: primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: validUrls.length,
      itemBuilder: (context, index) {
        final fullUrl = baseUrl + validUrls[index];
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
                          'Gambar tidak ada',
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
      await updateStatusFailedSampahLiar(sampah.id, idUser);
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
              : "Apakah kamu yakin ingin mengonfirmasi laporan ini sebagai selesai?",
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
        await updateStatusSampahLiar(sampah.id, idUser, 'proses');
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Status berubah menjadi Proses'),
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
            content: Text('Gagal memproses laporan: $e'),
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
          builder: (context) => InputFotoSampah(idSampah: sampah.id),
        ),
      );
      
      if (result != null && result) {
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
          await updateStatusSampahLiar(sampah.id, idUser, 'selesai');
          Navigator.pop(context); // Tutup loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Status berhasil diperbarui menjadi Selesai'),
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          Navigator.pop(context, true); // Refresh list
        } catch (e) {
          Navigator.pop(context); // Tutup loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memperbarui status: $e'),
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  } // <- This closing brace was missing!

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        title: const Text(
          "Detail Laporan Sampah Liar",
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    
                    // Email
                    _buildInfoRow(
                      icon: Icons.email,
                      title: "Email Pelapor",
                      content: sampah.email ?? "-",
                      iconColor: primaryOrange,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tanggal
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      title: "Tanggal Laporan",
                      content: DateFormat('dd MMMM yyyy').format(sampah.tanggal),
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
                  _buildCard(child: Column(
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
                  _buildCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Lokasi"),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: Icons.location_on,
                          title: "Alamat",
                          content: "Lokasi Sampah Liar", // Sesuaikan dengan data yang tersedia
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
                                  isDaurUlang: false,
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
                  _buildCard(child: Column(
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
                            border: Border.all(color: accentOrange.withOpacity(0.3)),
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
                  
                  const SizedBox(height: 16),
                  
                  // Photo Card
                  _buildCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Foto Bukti"),
                        const SizedBox(height: 16),
                        _buildBuktiFoto([sampah.fotoSampah]),
                      ],
                    ),
                  ),
                  
                  // Foto Pengangkutan (hanya jika status done)
                  if ((sampah.status?.toLowerCase() ?? "") == "done" && 
                      sampah.fotoPengangkutan != null && 
                      sampah.fotoPengangkutan!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildCard(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("Foto Bukti Pengangkutan"),
                          const SizedBox(height: 16),
                          _buildBuktiFoto([sampah.fotoPengangkutan!]),
                        ],
                      ),
                    ),
                  ],
                  
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
}