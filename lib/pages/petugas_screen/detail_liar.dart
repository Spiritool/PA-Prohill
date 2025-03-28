import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'sampah.dart'; // Import model SampahLiarData

class DetailSampahLiarPage extends StatelessWidget {
  final SampahLiarData sampah;

  const DetailSampahLiarPage({super.key, required this.sampah});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Sampah Liar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dilaporkan oleh: ${sampah.email}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Deskripsi: ${sampah.deskripsi}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text("Tanggal: ${DateFormat('dd-MM-yyyy').format(sampah.tanggal)}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text("Bukti Foto:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // _buildBuktiFoto(sampah.foto),
          ],
        ),
      ),
    );
  }

  Widget _buildBuktiFoto(List<String> fotoUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: fotoUrls.length,
      itemBuilder: (context, index) {
        return Image.network(fotoUrls[index], fit: BoxFit.cover);
      },
    );
  }
}
