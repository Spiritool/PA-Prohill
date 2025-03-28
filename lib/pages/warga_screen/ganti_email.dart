import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Untuk jsonEncode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dlh_project/constant/color.dart';

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

    final url = Uri.parse(
        'https://jera.kerissumenep.com/api/user/update-email/$userId?_method=PUT');
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Ganti Email',
          textAlign: TextAlign.center,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Baru',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _gantiEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlurStyle,
                  ),
                  child: const Text(
                    'Ganti Email',
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
