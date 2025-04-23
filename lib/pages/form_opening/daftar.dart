import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Daftar extends StatefulWidget {
  const Daftar({super.key});

  @override
  _DaftarState createState() => _DaftarState();
}

class _DaftarState extends State<Daftar> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noHpController =
      TextEditingController(text: '62');
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _register() async {
    final String nama = _namaController.text.trim();
    final String email = _emailController.text.trim();
    final String noHp = _noHpController.text.trim();
    final String password = _passwordController.text.trim();

    if (nama.isEmpty || email.isEmpty || noHp.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua inputan harus diisi!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://jera.kerissumenep.com/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'no_hp': noHp,
          'password': password,
          'role': "warga",
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          _showAlert('Registrasi berhasil!', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Login()),
            );
          });
        } else {
          String errorMessage = _parseErrorMessages(responseData);
          _showAlert('Registrasi gagal: $errorMessage');
        }
      } else {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String errorMessage = _parseErrorMessages(responseData);
        _showAlert('Registrasi gagal: $errorMessage');
      }
    } catch (e) {
      _showAlert('Terjadi kesalahan: $e');
    }
  }

  String _parseErrorMessages(Map<String, dynamic> responseData) {
    String errorMessage = '';
    responseData.forEach((key, value) {
      if (value is List) {
        for (var msg in value) {
          errorMessage += '$msg\n';
        }
      }
    });
    return errorMessage.trim();
  }

  void _showAlert(String message, [VoidCallback? onClose]) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pemberitahuan'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (onClose != null) {
                  onClose();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? toggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.black)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: label,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
              if (isPassword)
                IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.remove_red_eye_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: toggle,
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context); // back ke halaman sebelumnya
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E2C28),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(label: 'Nama', controller: _namaController),
                    const SizedBox(height: 24),
                    _buildTextField(
                        label: 'Email', controller: _emailController),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'No HP ( Awali 62 )',
                      controller: _noHpController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Password',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      isPassword: true,
                      toggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Login()));
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      children: [
                        TextSpan(text: 'Sudah punya akun? '),
                        TextSpan(
                          text: 'Log in',
                          style: TextStyle(
                            color: Color(0xFFA4DB47),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
