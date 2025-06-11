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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.error_outline, color: Colors.red.shade600),
              ),
              const SizedBox(width: 12),
              const Text('Error',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
    const String url = "https://prohildlhcilegon.id/api/kecamatan";
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
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: Colors.orange.shade700, size: 20),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Edit Alamat',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade800,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.edit_location,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Informasi Alamat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Perbarui detail alamat Anda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Form Fields
              _buildFormField(
                child: DropdownButtonFormField<String>(
                  value: _selectedKecamatanName,
                  hint: Text('Pilih Kecamatan',
                      style: TextStyle(color: Colors.grey.shade600)),
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
                            Icon(Icons.location_city,
                                color: Colors.orange.shade600, size: 20),
                            const SizedBox(width: 12),
                            Text(item['nama_kecamatan'],
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                  decoration: InputDecoration(
                    labelText: 'Kecamatan',
                    labelStyle: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.location_city,
                          color: Colors.orange.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.orange.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.orange.shade500, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                  ),
                ),
                icon: Icons.location_city,
                label: 'Kecamatan',
              ),

              const SizedBox(height: 20),

              _buildFormField(
                child: TextField(
                  controller: _kelurahanController,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Kelurahan',
                    labelStyle: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.place, color: Colors.orange.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.orange.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.orange.shade500, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                  ),
                ),
                icon: Icons.place,
                label: 'Kelurahan',
              ),

              const SizedBox(height: 20),

              _buildFormField(
                child: TextField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Deskripsi (Rumah, Toko, Kantor, RT/RW)',
                    labelStyle: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(Icons.description,
                          color: Colors.orange.shade600),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.orange.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide:
                          BorderSide(color: Colors.orange.shade500, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 18),
                  ),
                ),
                icon: Icons.description,
                label: 'Deskripsi',
              ),

              const SizedBox(height: 40),

              // Save Button
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade300,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required Widget child,
    required IconData icon,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
