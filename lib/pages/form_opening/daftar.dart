import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/form_opening/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

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
        Uri.parse('$baseipapi/api/register'),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: label,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (isPassword)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF9CA3AF),
                      size: 22,
                    ),
                    onPressed: toggle,
                  ),
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
      backgroundColor: const Color(0xFFF8FAFC),
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF4A5568),
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Header dengan gradient text effect
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFF6600),
                                Color(0xFFFF8533),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'Buat Akun Baru',
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ayo Segera bergabung dengan kami untuk mendapatkan layanan terbaik.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    _buildTextField(
                        label: 'Nama Lengkap', controller: _namaController),
                    const SizedBox(height: 24),
                    _buildTextField(
                        label: 'Alamat Email', controller: _emailController),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Nomor Telfon/Ponsel (+62)',
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
                    const SizedBox(height: 48),
                    // Modern gradient button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF6600),
                            Color(0xFFFF8533),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6600).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Buat Akun',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            // Bottom section with modern styling
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: 'Sudah punya akun? '),
                          TextSpan(
                            text: 'Masuk',
                            style: TextStyle(
                              color: Color(0xFFFF6600),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
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
