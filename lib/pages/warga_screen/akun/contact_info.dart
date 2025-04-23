import 'dart:convert';
import 'package:dlh_project/pages/warga_screen/akun/tambah_alamat.dart';
import 'package:dlh_project/pages/warga_screen/akun/ganti_email.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/widget/edit_alamat.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AlamatService {
  final String baseUrl = "https://prohildlhcilegon.id/api/alamat/get-by-user/";

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            const Text(
              'Contact Info',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoggedIn ? _buildLoggedInContent() : _buildLoginPrompt(),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.rightToBracket,
              size: 60, color: Colors.blue),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const Login())),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Login',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent() {
    return ListView(
      children: [
        _buildEmailCard(),
        const SizedBox(height: 16),
        _buildAlamatCard(),
      ],
    );
  }

  Widget _buildEmailCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.email, color: Colors.blue),
        title:
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(userEmail),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const GantiEmail())),
      ),
    );
  }

  Widget _buildAlamatCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alamat',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                IconButton(
                  icon:
                      const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const TambahAlamat())),
                ),
              ],
            ),
            const Divider(),
            _alamatData.isEmpty
                ? const Text('Belum ada alamat yang ditambahkan.')
                : Column(
                    children: _alamatData.map((alamat) {
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "${alamat['kecamatan']}, ${alamat['kelurahan']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(alamat['deskripsi'] ?? '',
                                style: const TextStyle(color: Colors.black87)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () => _editAlamat(context, alamat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _confirmDeleteAlamat(
                                      context, alamat['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.location_on,
                                      color: Colors.blue),
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
    final url = "https://prohildlhcilegon.id/api/alamat/delete/$alamatId";
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
    final url = "https://prohildlhcilegon.id/api/alamat/update/${alamat['id']}";
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
