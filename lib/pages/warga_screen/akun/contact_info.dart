import 'dart:convert';
import 'package:dlh_project/pages/warga_screen/akun/tambah_alamat.dart';
import 'package:dlh_project/pages/warga_screen/akun/ganti_email.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/widget/edit_alamat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class AlamatService {
  final String baseUrl = "$baseipapi/api/alamat/get-by-user/";

  Future<List<dynamic>> fetchAlamatByUser(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl$userId"));
      final jsonData = json.decode(response.body);

      if (response.statusCode == 200 && jsonData['success']) {
        return jsonData['data'];
      } else {
        throw Exception(jsonData['message']);
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }
}

class ContactInfo extends StatefulWidget {
  const ContactInfo({super.key});

  @override
  State<ContactInfo> createState() => _ContactInfoState();
}

class _ContactInfoState extends State<ContactInfo> {
  String userName = 'Guest';
  String userEmail = 'user@example.com';
  String userPhone = '081234567890';
  List<dynamic> _alamatData = [];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchAlamatData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userEmail = prefs.getString('user_email') ?? 'user@example.com';
      userPhone = prefs.getString('user_phone') ?? '081234567890';
      _isLoggedIn = userName != 'Guest';
    });
  }

  Future<void> _fetchAlamatData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId != null) {
      final alamatService = AlamatService();
      final data = await alamatService.fetchAlamatByUser(userId);
      setState(() => _alamatData = data);
    }
  }

  void _openGoogleMaps(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka lokasi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF6600).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFFFF6600), size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Contact Info',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoggedIn ? _buildLoggedInContent() : _buildLoginPrompt(),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6600).withOpacity(0.1),
                  const Color(0xFFFF6600).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.lock_person_outlined,
              size: 50,
              color: Color(0xFFFF6600),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Login Required',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Please login to access your contact information',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6600).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const Login())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Login to Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 20),
        _buildEmailCard(),
        const SizedBox(height: 20),
        _buildAlamatCard(),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFF6600).withOpacity(0.1),
                const Color(0xFFFF6600).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.email_outlined,
            color: Color(0xFFFF6600),
            size: 24,
          ),
        ),
        title: const Text(
          'Email Address',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            userEmail,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        trailing: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFFF6600).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFFFF6600),
            size: 16,
          ),
        ),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GantiEmail())),
      ),
    );
  }

  Widget _buildAlamatCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFF6600).withOpacity(0.1),
                            const Color(0xFFFF6600).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFF6600),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Addresses',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6600), Color(0xFFFF8533)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6600).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TambahAlamat())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.withOpacity(0.1),
                    Colors.grey.withOpacity(0.3),
                    Colors.grey.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _alamatData.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No addresses added yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first address to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _alamatData.map((alamat) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF8F9FA),
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF6600).withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFF6600),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    "${alamat['kecamatan']}, ${alamat['kelurahan']}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text(
                                alamat['deskripsi'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _buildActionButton(
                                  icon: Icons.edit_outlined,
                                  color: const Color(0xFFFF6600),
                                  onPressed: () => _editAlamat(context, alamat),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.delete_outline,
                                  color: const Color(0xFFE74C3C),
                                  onPressed: () => _confirmDeleteAlamat(
                                      context, alamat['id']),
                                ),
                                const SizedBox(width: 8),
                                _buildActionButton(
                                  icon: Icons.location_on_outlined,
                                  color: const Color(0xFF3498DB),
                                  onPressed: () {
                                    final url = alamat['kordinat'];
                                    if (url != null) _openGoogleMaps(url);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _editAlamat(BuildContext context, Map<String, dynamic> alamat) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditAlamatScreen(alamat: alamat)),
    ).then((updatedAlamat) {
      if (updatedAlamat != null) {
        _updateAlamat(updatedAlamat);
      }
    });
  }

  void _confirmDeleteAlamat(BuildContext context, int alamatId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              _deleteAlamat(alamatId);
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAlamat(int alamatId) async {
    final url = "$baseipapi/api/alamat/delete/$alamatId";
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      _fetchAlamatData();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil dihapus')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus alamat')));
    }
  }

  Future<void> _updateAlamat(Map<String, dynamic> alamat) async {
    final url = "$baseipapi/api/alamat/update/${alamat['id']}";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(alamat),
    );

    if (response.statusCode == 200) {
      _fetchAlamatData();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alamat berhasil diperbarui')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui alamat')));
    }
  }
}
