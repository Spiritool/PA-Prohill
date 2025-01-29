import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Penimbangan extends StatefulWidget {
  final int idSampah; // ID for the specific waste item

  const Penimbangan({super.key, required this.idSampah});

  @override
  _PenimbanganState createState() => _PenimbanganState();
}

class _PenimbanganState extends State<Penimbangan> {
  final _kertasController = TextEditingController();
  final _plastikController = TextEditingController();
  final _logamController = TextEditingController();
  final _lainnyaController = TextEditingController();
  final _minyakController = TextEditingController();

  Future<void> _submitData() async {
    final jumlahKertas = double.tryParse(_kertasController.text) ?? 0;
    final jumlahPlastik = double.tryParse(_plastikController.text) ?? 0;
    final jumlahLogam = double.tryParse(_logamController.text) ?? 0;
    final jumlahLainnya = double.tryParse(_lainnyaController.text) ?? 0;
    final jumlahMinyak = double.tryParse(_minyakController.text) ?? 0;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Submit penimbangan data
      final penimbanganResponse = await http.post(
        Uri.parse(
            'https://jera.kerissumenep.com/api/pengangkutan-sampah/penimbangan-sampah/${widget.idSampah}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jumlah_kertas': jumlahKertas,
          'jumlah_plastik': jumlahPlastik,
          'jumlah_logam': jumlahLogam,
          'jumlah_sampah_lain': jumlahLainnya,
          'jumlah_minyak_jalantah': jumlahMinyak,
        }),
      );

      if (penimbanganResponse.statusCode == 200) {
        // Update status to 'done'
        final statusUpdateResponse = await http.post(
          Uri.parse(
              'https://jera.kerissumenep.com/api/pengangkutan-sampah/done/${widget.idSampah}'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        if (statusUpdateResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Data penimbangan berhasil disimpan dan status diperbarui menjadi Done')),
          );
          Navigator.pop(context, true); // Return success status
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Gagal memperbarui status menjadi Done: ${statusUpdateResponse.reasonPhrase}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal menyimpan data penimbangan: ${penimbanganResponse.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: ${e.toString()}')),
      );
    } finally {
      Navigator.pop(context); // Dismiss loading indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Penimbangan"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                'Masukkan Data Penimbangan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _kertasController,
                decoration: const InputDecoration(
                  labelText: 'Berat Sampah Kertas (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _plastikController,
                decoration: const InputDecoration(
                  labelText: 'Berat Sampah Plastik (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _logamController,
                decoration: const InputDecoration(
                  labelText: 'Berat Sampah Logam (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lainnyaController,
                decoration: const InputDecoration(
                  labelText: 'Berat Sampah Lainnya (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minyakController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Minyak Jelantah (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
