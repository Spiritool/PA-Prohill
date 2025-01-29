import 'dart:convert';
import 'package:dlh_project/pages/warga_screen/tambah_alamat.dart';
import 'package:dlh_project/widget/edit_alamat.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/password_reset.dart';
import 'package:dlh_project/pages/warga_screen/ganti_email.dart';
import 'package:dlh_project/widget/infoField.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AlamatService {
  final String baseUrl =
      "https://jera.kerissumenep.com/api/alamat/get-by-user/";

  Future<List<dynamic>> fetchAlamatByUser(int userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl$userId"));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return jsonData['data']; // Mengembalikan list alamat
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

class Akun extends StatefulWidget {
  const Akun({super.key});

  @override
  _AkunState createState() => _AkunState();
}

class _AkunState extends State<Akun> {
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Akun',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: _isLoggedIn ? _buildLoggedInContent() : _buildLoginButton(),
      ),
    );
  }

  Widget _buildLoggedInContent() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              InfoField(label: 'Nama', value: userName),
              _buildEmailField(),
              InfoField(label: 'No. HP', value: userPhone),
              _buildAddressField(),
              _buildPasswordResetField(),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildEditAllButton(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildLogoutButton(),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Login(),
            ),
          );
        },
        child: const Text('Login'),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        color: BlurStyle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Informasi Akun',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                userEmail,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GantiEmail(),
                ),
              );
            },
            child: const Text(
              'Edit',
              style: TextStyle(fontSize: 16, color: red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alamat:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const TambahAlamat(),
                      ),
                    );
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _alamatData.isEmpty
              ? const Center(child: Text("Tidak ada data alamat."))
              : Column(
                  children: _alamatData.map((alamat) {
                    return ListTile(
                      title: Text(
                          "${alamat['kecamatan']}, ${alamat['kelurahan']}"),
                      subtitle: Text("${alamat['deskripsi']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.edit),
                            color: Colors.orange,
                            onPressed: () => _editAlamat(context, alamat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.red,
                            onPressed: () {
                              _confirmDeleteAlamat(context, alamat['id']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.location_on),
                            color: Colors.blue,
                            onPressed: () {
                              final url = alamat['kordinat'];
                              if (url != null) {
                                _openGoogleMaps(url);
                              }
                            },
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
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                _deleteAlamat(alamatId);
                Navigator.of(context).pop();
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAlamat(int alamatId) async {
    final url = "https://jera.kerissumenep.com/api/alamat/delete/$alamatId";
    final response = await http.delete(Uri.parse(url));

    if (response.statusCode == 200) {
      // Successfully deleted the address, now refresh the address list
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
        .push(
      MaterialPageRoute(
        builder: (context) => EditAlamatScreen(alamat: alamat),
      ),
    )
        .then((updatedAlamat) {
      if (updatedAlamat != null) {
        _updateAlamat(updatedAlamat);
      }
    });
  }

  Future<void> _updateAlamat(Map<String, dynamic> alamat) async {
    final url =
        "https://jera.kerissumenep.com/api/alamat/update/${alamat['id']}";
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

  Widget _buildPasswordResetField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Ganti Password:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordReset(),
                ),
              );
            },
            child: const Text(
              'Edit',
              style: TextStyle(fontSize: 16, color: red),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEditAllButton() {
    return ElevatedButton(
      onPressed: _showEditAllDialog,
      child: const Text('Edit Semua Data'),
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _logout,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
      ),
      child: const Text(
        'Logout',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _showEditAllDialog() {
    TextEditingController usernameController =
        TextEditingController(text: userName);
    TextEditingController phoneController =
        TextEditingController(text: userPhone);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Semua Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'No. HP ( Awali 62 )',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final userNameInput = usernameController.text;
                final userPhoneInput = phoneController.text;

                // Check if the username has at least 8 characters
                if (userNameInput.length < 8) {
                  // Show a snackbar with an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama harus memiliki minimal 8 karakter!'),
                    ),
                  );
                  return; // Do not proceed with the API request
                }

                SharedPreferences prefs = await SharedPreferences.getInstance();
                final idUser = prefs.getInt('user_id') ?? 0;

                // Prepare the API request
                final String apiUrl =
                    'https://jera.kerissumenep.com/api/user/update/$idUser?_method=PUT';
                final String? token = prefs.getString('token');

                final Map<String, String> headers = {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                };

                final Map<String, dynamic> body = {
                  'nama': userNameInput,
                  'no_hp': userPhoneInput,
                };

                try {
                  // Send the PUT request to update user data
                  final response = await http.put(
                    Uri.parse(apiUrl),
                    headers: headers,
                    body: jsonEncode(body),
                  );

                  if (response.statusCode == 200) {
                    // Handle success
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Data berhasil diperbarui!')),
                    );

                    // Update SharedPreferences with the new data
                    await prefs.setString('user_name', userNameInput);
                    await prefs.setString('user_phone', userPhoneInput);
                  } else {
                    // Log the full response for debugging
                    print('Response body: ${response.body}');

                    // Handle error with a fallback message
                    final errorMessage = jsonDecode(response.body)['message'] ??
                        'Error: ${response.statusCode} - ${response.reasonPhrase}';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Gagal memperbarui data: $errorMessage')),
                    );
                  }
                } catch (e) {
                  // Handle exceptions
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }

                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _isLoggedIn = false;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }
}
