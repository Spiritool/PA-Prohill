import 'package:dlh_project/pages/form_opening/Verifikasi_Otp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dlh_project/constant/color.dart';

class LupaPassword extends StatefulWidget {
  const LupaPassword({super.key});

  @override
  _LupaPasswordState createState() => _LupaPasswordState();
}

class _LupaPasswordState extends State<LupaPassword> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noHpController = TextEditingController();

  Future<void> resetPassword() async {
    final response = await http.post(
      Uri.parse('https://jera.kerissumenep.com/api/password/forgot'),
      body: {
        'email': emailController.text,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        // Navigasi ke halaman OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VerifikasiOtp(),
          ),
        );
      } else {
        // Tampilkan pesan kesalahan
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reset gagal, silakan periksa kembali email dan Nomor HP Anda.',
          ),
          backgroundColor: Colors.red,
        ),
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
          'Lupa Password',
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
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlurStyle,
                  ),
                  child: const Text(
                    'Reset Password',
                    style: TextStyle(color: Colors.white),
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
