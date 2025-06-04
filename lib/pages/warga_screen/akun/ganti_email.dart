import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk jsonEncode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/constant/color.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class GantiEmail extends StatefulWidget {
  const GantiEmail({super.key});

  @override
  _GantiEmailState createState() => _GantiEmailState();
}

class _GantiEmailState extends State<GantiEmail> {
  final TextEditingController _emailController = TextEditingController();

  Future<void> _gantiEmail() async {
    final newEmail = _emailController.text;

    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengguna tidak ditemukan')),
      );
      return;
    }

    final url =
        Uri.parse('$baseipapi/api/user/update-email/$userId?_method=PUT');
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'email': newEmail,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        // Update email di SharedPreferences
        await prefs.setString('user_email', newEmail);

        // Update email di state aplikasi agar perubahan terlihat langsung
        setState(() {
          _emailController.text = newEmail;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        // Kembali ke halaman sebelumnya setelah sukses
        Navigator.pop(context, newEmail);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      }
    } else {
      final responseData = jsonDecode(response.body);
      String errorMessage = 'Terjadi kesalahan';
      if (responseData.containsKey('message')) {
        errorMessage = responseData['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(0xFF2D3748),
          ),
        ),
        title: const Text(
          'Ganti Email',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header Section dengan Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6600).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    size: 60,
                    color: const Color(0xFFFF6600),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Description Text
              const Text(
                'Masukkan email baru Anda',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Modern Email Input Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email Baru',
                    labelStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: const Color(0xFFFF6600).withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFF6600),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Modern Button dengan Gradient
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _gantiEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6600),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFF6600),
                          const Color(0xFFFF8533),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Ganti Email',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email yang baru akan digunakan untuk login dan notifikasi',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
