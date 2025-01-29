import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

    // Initialize the controllers with the current values of the alamat data
    _kecamatanController =
        TextEditingController(text: widget.alamat['kecamatan']);
    _kelurahanController =
        TextEditingController(text: widget.alamat['kelurahan']);
    _deskripsiController =
        TextEditingController(text: widget.alamat['deskripsi']);

    // Set the initial selected kecamatan name to the current one
    _selectedKecamatanName = widget.alamat['kecamatan'];

    // Fetch kecamatan data when the screen is loaded
    _fetchKecamatanData();
  }

  @override
  void dispose() {
    // Dispose the controllers when the widget is removed from the widget tree
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
          title: const Text('Error'),
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

          // Periksa apakah kecamatan yang dipilih ada dalam daftar
          if (_kecamatanList.any(
              (item) => item['nama_kecamatan'] == _selectedKecamatanName)) {
            _selectedKecamatanName = widget.alamat['kecamatan'];
          } else {
            _selectedKecamatanName = null; // Set ke null jika tidak ditemukan
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
        centerTitle: true,
        title: const Text(
          'Edit Alamat',
          textAlign: TextAlign.center,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
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
                    child: Text(item['nama_kecamatan']),
                  );
                },
              ).toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _kelurahanController,
              decoration: const InputDecoration(
                labelText: 'Kelurahan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _deskripsiController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Rumah, Toko, Kantor, RT/RW)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
