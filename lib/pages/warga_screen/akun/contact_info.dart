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
  final String baseUrl =
      "https://prohildlhcilegon.id/api/alamat/get-by-user/";

  Future<List<dynamic>> fetchAlamatByUser(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl$userId"));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          return jsonData['data'];
        } else {
          throw Exception(jsonData['message']);
        }
      } else {
        throw Exception(
            "Gagal mengambil data. Kode status: ${response.statusCode}");
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
  _ContactInfoState createState() => _ContactInfoState();
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
      AlamatService alamatService = AlamatService();
      List<dynamic> data = await alamatService.fetchAlamatByUser(userId);

      setState(() {
        _alamatData = data;
      });
    }
  }

  void _openGoogleMaps(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Contact Info',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: _isLoggedIn ? _buildLoggedInContent() : _buildLoginButton(),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.rightToBracket,
            size: 60,
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildAddressField(),
                const SizedBox(height: 12),
                _buildEmailField(),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.email, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Email',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Text(userEmail, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GantiEmail()),
              );
            },
            child: const Icon(Icons.chevron_right, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alamat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TambahAlamat()));
                  },
                  child:
                      const Icon(Icons.chevron_right, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 10),
          _alamatData.isEmpty
              ? const Text("Tidak ada data alamat.")
              : Column(
                  children: _alamatData.map((alamat) {
                    return Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${alamat['kecamatan']}, ${alamat['kelurahan']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alamat['deskripsi'],
                            style: const TextStyle(color: Colors.black54),
                          ),
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
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _confirmDeleteAlamat(context, alamat['id']),
                              ),
                              IconButton(
                                icon: const Icon(Icons.location_on,
                                    color: Colors.blue),
                                onPressed: () {
                                  final url = alamat['kordinat'];
                                  if (url != null) {
                                    _openGoogleMaps(url);
                                  }
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
    );
  }

  void _confirmDeleteAlamat(BuildContext context, int alamatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin menghapus alamat ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteAlamat(alamatId);
                Navigator.pop(context);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAlamat(int alamatId) async {
    final url = "https://prohildlhcilegon.id/api/alamat/delete/$alamatId";
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      _fetchAlamatData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil dihapus')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus alamat')),
      );
    }
  }

  void _editAlamat(BuildContext context, Map<String, dynamic> alamat) {
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (context) => EditAlamatScreen(alamat: alamat),
    ))
        .then((updatedAlamat) {
      if (updatedAlamat != null) {
        _updateAlamat(updatedAlamat);
      }
    });
  }

  Future<void> _updateAlamat(Map<String, dynamic> alamat) async {
    final url =
        "https://prohildlhcilegon.id/api/alamat/update/${alamat['id']}";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(alamat),
    );

    if (response.statusCode == 200) {
      _fetchAlamatData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat berhasil diperbarui')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui alamat')),
      );
    }
  }
}
