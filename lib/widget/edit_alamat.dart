import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditAlamatScreen extends StatefulWidget {
  final Map<String, dynamic> alamat;

  const EditAlamatScreen({super.key, required this.alamat});

  @override
  _EditAlamatScreenState createState() => _EditAlamatScreenState();
}

class _EditAlamatScreenState extends State<EditAlamatScreen> {
  late TextEditingController _kecamatanController;
  late TextEditingController _kelurahanController;
  late TextEditingController _deskripsiController;
  List<Map<String, dynamic>> _kecamatanList = [];
  String? _selectedKecamatanName;

  @override
  void initState() {
    super.initState();
    _kecamatanController =
        TextEditingController(text: widget.alamat['kecamatan']);
    _kelurahanController =
        TextEditingController(text: widget.alamat['kelurahan']);
    _deskripsiController =
        TextEditingController(text: widget.alamat['deskripsi']);
    _selectedKecamatanName = widget.alamat['kecamatan'];
    _fetchKecamatanData();
  }

  @override
  void dispose() {
    _kecamatanController.dispose();
    _kelurahanController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedAlamat = {
      'id': widget.alamat['id'],
      'kecamatan': _selectedKecamatanName ?? widget.alamat['kecamatan'],
      'kelurahan': _kelurahanController.text,
      'deskripsi': _deskripsiController.text,
    };

    Navigator.of(context).pop(updatedAlamat);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _fetchKecamatanData() async {
    const String url = "https://jera.kerissumenep.com/api/kecamatan";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _kecamatanList = List<Map<String, dynamic>>.from(data['data']);
          if (_kecamatanList.any(
              (item) => item['nama_kecamatan'] == _selectedKecamatanName)) {
            _selectedKecamatanName = widget.alamat['kecamatan'];
          } else {
            _selectedKecamatanName = null;
          }
        });
      } else {
        throw Exception('Failed to load kecamatan data');
      }
    } catch (e) {
      _showErrorDialog('Error fetching kecamatan data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.grey[200], // Latar belakang abu-abu putih
        elevation: 1,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: Colors.black), // Ganti ikon kembali
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            const Text(
              'Edit Alamat',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Dropdown for Kecamatan with icon
            DropdownButtonFormField<String>(
              value: _selectedKecamatanName,
              hint: const Text('Pilih Kecamatan'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedKecamatanName = newValue;
                });
              },
              items: _kecamatanList.map<DropdownMenuItem<String>>(
                (Map<String, dynamic> item) {
                  return DropdownMenuItem<String>(
                    value: item['nama_kecamatan'],
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey[700]),
                        const SizedBox(width: 10),
                        Text(item['nama_kecamatan']),
                      ],
                    ),
                  );
                },
              ).toList(),
              decoration: InputDecoration(
                labelText: 'Kecamatan',
                labelStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Kelurahan input with icon
            TextField(
              controller: _kelurahanController,
              decoration: InputDecoration(
                labelText: 'Kelurahan',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.place, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),

            // Deskripsi input with icon
            TextField(
              controller: _deskripsiController,
              decoration: InputDecoration(
                labelText: 'Deskripsi (Rumah, Toko, Kantor, RT/RW)',
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.edit, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            const SizedBox(height: 30),

            // Save Button with gradient
            Center(
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600], // Tombol abu-abu
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  side: const BorderSide(width: 2, color: Colors.white),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
