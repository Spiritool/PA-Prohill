import 'package:flutter/material.dart';

class QnAPage extends StatelessWidget {
  const QnAPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Q & A'),
        backgroundColor: Colors.blueAccent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          QnAItem(
            question: 'Bagaimana cara mengganti password?',
            answer: 'Pergi ke pengaturan, lalu pilih "Ganti Password".',
          ),
          QnAItem(
            question: 'Bagaimana jika lupa password?',
            answer: 'Gunakan fitur "Lupa Password" di halaman login.',
          ),
          QnAItem(
            question: 'Apakah bisa mengubah email?',
            answer: 'Saat ini, perubahan email belum didukung.',
          ),
          QnAItem(
            question: 'Bagaimana cara menghubungi support?',
            answer: 'Kirim email ke support@example.com.',
          ),
        ],
      ),
    );
  }
}

class QnAItem extends StatelessWidget {
  final String question;
  final String answer;

  const QnAItem({required this.question, required this.answer, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(answer),
          ),
        ],
      ),
    );
  }
}
