import 'package:dlh_project/pages/form_opening/reset_password.dart';
import 'package:flutter/material.dart';

class VerifikasiOtp extends StatefulWidget {
  const VerifikasiOtp({super.key});

  @override
  _VerifikasiOtpState createState() => _VerifikasiOtpState();
}

class _VerifikasiOtpState extends State<VerifikasiOtp> {
  final TextEditingController otpController = TextEditingController();

  void verifyOtp() {
    // Token yang diinputkan oleh user
    final String token = otpController.text;

    // Navigasi ke halaman reset password dengan membawa token
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPassword(token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Verifikasi OTP'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              TextField(
                controller: otpController,
                decoration: const InputDecoration(
                  labelText: 'Token OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Verifikasi Token OTP',
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
