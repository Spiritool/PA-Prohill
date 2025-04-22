import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk jsonEncode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/password_reset.dart';
import 'package:dlh_project/pages/warga_screen/akun/ganti_email.dart'; // Import GantiEmail page

class AkunPetugas extends StatefulWidget {
  const AkunPetugas({super.key});

  @override
  _AkunPetugasState createState() => _AkunPetugasState();
}

class _AkunPetugasState extends State<AkunPetugas> {
  String userName = 'Guest';
  String userEmail = 'user@example.com';
  String userPhone = '081234567890';
  String userStatus = 'ready';
  final List<String> _addresses = ['Rumah', 'Kantor', 'Kos'];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStatus();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userEmail = prefs.getString('user_email') ?? 'user@example.com';
      userPhone = prefs.getString('user_phone') ?? '081234567890';
      userStatus = prefs.getString('status') ?? 'ready';
      _addresses.addAll(prefs.getStringList('addresses') ?? []);
      _isLoggedIn = userName != 'Guest';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Akun Petugas',
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

  String _status = 'ready'; // Default value

  Widget _buildLoggedInContent() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              // InfoField(label: 'Nama', value: userName),
              _buildNameField(), // Custom name field with edit button
              _buildNomorField(), // Custom phone number field with edit button
              _buildEmailField(), // Custom email field with edit button
              _buildPasswordResetField(),

              // ✅ Dropdown Status dengan API
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(
                        //   'Status: $userStatus',
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status: ${_status == "ready" ? "Ready" : "Tidak Ready"}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Switch(
                              value: _status ==
                                  "ready", // Jika "ready", maka switch aktif (ON)
                              onChanged: (bool newValue) async {
                                String newStatus =
                                    newValue ? "ready" : "tidak ready";

                                setState(() {
                                  _status = newStatus;
                                });

                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setString('user_status', newStatus);

                                _updateUserStatus(
                                    newStatus); // 🔥 Panggil API untuk update status
                              },
                              activeColor: Colors.green, // Warna saat ON
                              inactiveThumbColor: Colors.red, // Warna saat OFF
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildEditAllButton()),
            const SizedBox(width: 10),
            Expanded(child: _buildLogoutButton()),
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
    return Stack(
      children: [
        // Container Utama
        Container(
          width: double.infinity,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFD1EFE3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 0, 0), // Warna border
              width: 1, // Ketebalan border
            ),
          ),
          child: const Center(
            child: Text(
              'Profil Petugas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Gambar di Pojok Kanan Atas
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 60, // Sesuaikan ukuran gambar
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, // Agar gambar dalam lingkaran
              // Warna background jika ingin efek outline
            ),
            padding:
                const EdgeInsets.all(4), // Tambahkan padding agar gambar tidak mentok
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png', // Ganti dengan path gambar kamu
                fit: BoxFit.cover, // Agar gambar menyesuaikan
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, // Latar belakang putih
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon di sebelah kiri
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(child: Image.asset('assets/icons/nama.png')
                // Jika ingin gambar kustom, ganti dengan Image.asset('assets/icon.png')
                ),
          ),
          const SizedBox(width: 10), // Spasi antara ikon dan teks

          // Nama dan label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nama:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNomorField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white, // Latar belakang putih
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ikon di sebelah kiri
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(child: Image.asset('assets/icons/nomer.png')
                // Jika ingin gambar kustom, ganti dengan Image.asset('assets/icon.png')
                ),
          ),
          const SizedBox(width: 10), // Spasi antara ikon dan teks

          // Nama dan label
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'No. Hp:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userPhone,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ],
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
        children: [
          // Ikon di sebelah kiri
          Image.asset(
            'assets/icons/email.png', // Sesuaikan dengan path ikon email
            width: 30, // Ukuran ikon
            height: 30,
          ),
          const SizedBox(width: 10), // Spasi antara ikon dan teks
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold, // Bold seperti pada "Nama:"
                  ),
                ),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          // Tombol Edit di sebelah kanan
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const GantiEmail(), // Navigate to GantiEmail page
                ),
              );
            },
            child: const Text(
              'Edit',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
      children: [
        // Gambar kunci dari assets
        Image.asset(
          'assets/icons/password.png', // Pastikan path sesuai
          width: 24, // Sesuaikan ukuran dengan desain
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),

        // Teks "Ganti Password:"
        const Text(
          'Ganti Password:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const Spacer(),

        // Tombol "Edit"
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
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
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
                    'https://prohildlhcilegon.id/api/user/update/$idUser?_method=PUT';
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

  Future<void> _updateUserData(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final userId =
        prefs.getInt('user_id'); // Dapatkan user_id dari SharedPreferences
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan data pengguna.')),
      );
      return;
    }

    final url = Uri.parse(
        'https://prohildlhcilegon.id/api/user/update/$userId?_method=PUT');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nama': name,
        'no_hp': phone,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        userName = name;
        userPhone = phone;
      });
      _saveUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data berhasil diperbarui!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui data.')),
      );
    }
  }

  void _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
    await prefs.setString('user_phone', userPhone);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all data from SharedPreferences
    await prefs.clear();

    // Navigate back to login page
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  Future<void> _updateUserStatus(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan data pengguna.')),
      );
      return;
    }

    final requestBody = jsonEncode({'status': status});
    print('Status yang dikirim: $status'); // ✅ Debugging
    print('Body JSON yang dikirim: $requestBody');

    final url = Uri.parse(
        'https://prohildlhcilegon.id/api/user/$userId/status?_method=PUT');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      setState(() {
        userStatus = status;
      });
      await prefs.setString('status', status); // ✅ Simpan status terbaru
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status berhasil diperbarui!')),
      );
    } else {
      print('Gagal memperbarui status. Response: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status: ${response.body}')),
      );
    }
  }

  Future<void> _loadUserStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _status =
          prefs.getString('user_status') ?? 'ready'; // ✅ Ambil status terbaru
    });
  }
}
