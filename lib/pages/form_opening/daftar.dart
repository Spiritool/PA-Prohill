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

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
          // Menangani pesan kesalahan
          String errorMessage = _parseErrorMessages(responseData);
          _showAlert('Registrasi gagal: $errorMessage');
        }
      } else {
        // Menangani pesan kesalahan dengan parsing body jika status code bukan 200 atau 201
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        String errorMessage = _parseErrorMessages(responseData);
        _showAlert('Registrasi gagal: $errorMessage');
      }
    } catch (e) {
      _showAlert('Terjadi kesalahan: $e');
    }
  }

  String _parseErrorMessages(Map<String, dynamic> responseData) {
    // Menggabungkan semua pesan kesalahan menjadi satu string
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Daftar',
          textAlign: TextAlign.center,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 40,
              ),
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _noHpController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'No HP ( Awali 62 )',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlurStyle,
                  ),
                  child: const Text(
                    'Daftar',
                    style: TextStyle(color: white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
