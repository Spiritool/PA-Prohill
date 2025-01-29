import 'package:dlh_project/widget/infoField.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk jsonEncode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:dlh_project/pages/warga_screen/password_reset.dart';
import 'package:dlh_project/pages/warga_screen/ganti_email.dart'; // Import GantiEmail page

class AkunPetugas extends StatefulWidget {
  const AkunPetugas({super.key});

  @override
  _AkunPetugasState createState() => _AkunPetugasState();
}

class _AkunPetugasState extends State<AkunPetugas> {
  String userName = 'Guest';
  String userEmail = 'user@example.com';
  String userPhone = '081234567890';
  final List<String> _addresses = ['Rumah', 'Kantor', 'Kos'];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('user_name') ?? 'Guest';
      userEmail = prefs.getString('user_email') ?? 'user@example.com';
      userPhone = prefs.getString('user_phone') ?? '081234567890';
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

  Widget _buildLoggedInContent() {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              InfoField(label: 'Nama', value: userName),
              _buildEmailField(), // Custom email field with edit button
              InfoField(label: 'No. HP ', value: userPhone),
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
          'Informasi Akun Petugas',
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
                  builder: (context) =>
                      const GantiEmail(), // Navigate to GantiEmail page
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
        'https://jera.kerissumenep.com/api/user/update/$userId?_method=PUT');
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
}
