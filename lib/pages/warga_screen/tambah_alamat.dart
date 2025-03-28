import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart'; // Untuk mengambil lokasi
import 'package:url_launcher/url_launcher.dart'; // Untuk membuka Google Maps

class TambahAlamat extends StatefulWidget {
  const TambahAlamat({super.key});

  @override
  _TambahAlamatState createState() => _TambahAlamatState();
}

class _TambahAlamatState extends State<TambahAlamat> {
  final TextEditingController _deskripsiController = TextEditingController();

  String? _kordinat;
  bool _isLoading = false;
  List<Map<String, dynamic>> _kecamatanList = [];
  final Map<String, List<String>> _kelurahanMap = {
    'Cibeber': [
      'Bulakan',
      'Cibeber',
      'Cikerai',
      'Kalitimbang',
      'Karangasem',
      'Kedaleman'
    ],
    'Cilegon': ['Bagendung', 'Bendungan', 'Ciwaduk', 'Ciwedus', 'Ketileng'],
    'Citangkil': [
      'Citangkil',
      'Deringo',
      'Kebonsari',
      'Lebakdenok',
      'Samangraya',
      'Tamanbaru',
      'Warnasari'
    ],
    'Ciwandan': [
      'Banjar Negara',
      'Gunungsugih',
      'Kepuh',
      'Kubangsari',
      'Randakari',
      'Tegalratu'
    ],
    'Gerogol': ['Gerem', 'Gerogol/Grogol', 'Kotasari', 'Rawa Arum'],
    'Jombang': [
      'Gedong Dalem',
      'Jombang Wetan',
      'Masigit',
      'Panggung Rawi',
      'Sukmajaya'
    ],
    'Pulomerak': ['Lebak Gede', 'Mekarsari', 'Suralaya', 'Tamansari'],
    'Purwakarta': [
      'Kebondalem',
      'Kotabumi',
      'Pabean',
      'Purwakarta',
      'Ramanuju',
      'Tegal Bunder'
    ],
  };

  String? _selectedKecamatanName;
  String? _selectedKelurahan;

  @override
  void initState() {
    super.initState();
    _fetchKecamatanData();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _kordinat =
            "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
      );
    }
  }

  Future<void> _fetchKecamatanData() async {
    const String url = "http://10.251.134.25:8000/api/kecamatan";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _kecamatanList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        throw Exception('Failed to load kecamatan data');
      }
    } catch (e) {
      _showErrorDialog('Error fetching kecamatan data: $e');
    }
  }

  Future<void> _tambahAlamat() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID pengguna atau token tidak ditemukan')),
      );
      return;
    }

    final kelurahan = _selectedKelurahan;
    final deskripsi = _deskripsiController.text;

    if (_selectedKecamatanName == null ||
        kelurahan == null ||
        _kordinat == null ||
        deskripsi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Semua field harus diisi dan lokasi harus diambil')),
      );
      return;
    }

    final url = Uri.parse('http://10.251.134.25:8000/api/alamat/store');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_user': userId,
        'kecamatan': _selectedKecamatanName,
        'kelurahan': kelurahan,
        'kordinat': _kordinat,
        'deskripsi': deskripsi,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (responseData['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        Navigator.pop(context); // Kembali ke halaman sebelumnya
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Gagal menambah alamat')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambah alamat. Coba lagi.')),
      );
    }
  }

  void _lihatLokasi() async {
    if (_kordinat != null) {
      if (await canLaunch(_kordinat!)) {
        await launch(_kordinat!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka peta.')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Tambah Alamat',
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
              DropdownButtonFormField<String>(
                value: _selectedKecamatanName,
                hint: const Text('Pilih Kecamatan'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedKecamatanName = newValue;
                    _selectedKelurahan =
                        null; // Reset kelurahan saat kecamatan berubah
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
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedKelurahan,
                hint: const Text('Pilih Kelurahan'),
                onChanged: _selectedKecamatanName != null
                    ? (String? newValue) {
                        setState(() {
                          _selectedKelurahan = newValue;
                        });
                      }
                    : null,
                items: _selectedKecamatanName != null
                    ? _kelurahanMap[_selectedKecamatanName]!
                        .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList()
                    : [],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi ( Rumah, Toko, Kantor, RT/RW )',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text('Dapatkan Lokasi'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _kordinat == null
                          ? "Lokasi belum diambil"
                          : "Alamat Sudah diambil",
                      style: TextStyle(
                        color: _kordinat == null ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (_kordinat != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _lihatLokasi,
                    child: const Text('Lihat Lokasi'),
                  ),
                ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _tambahAlamat,
                  child: const Text('Tambah Alamat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
