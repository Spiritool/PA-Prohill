import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

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
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _kordinat =
            "https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
      );
    }
  }

  Future<void> _fetchKecamatanData() async {
    final String url = "$baseipapi/api/kecamatan";
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _kecamatanList = List<Map<String, dynamic>>.from(data['data']);
        });
      } else {
        throw Exception('Gagal memuat data kecamatan');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _tambahAlamat() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID atau token tidak ditemukan')),
      );
      return;
    }

    final deskripsi = _deskripsiController.text;

    if (_selectedKecamatanName == null ||
        _selectedKelurahan == null ||
        _kordinat == null ||
        deskripsi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Lengkapi semua kolom dan ambil lokasi terlebih dahulu')),
      );
      return;
    }

    final url = Uri.parse('$baseipapi/api/alamat/store');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id_user': userId,
        'kecamatan': _selectedKecamatanName,
        'kelurahan': _selectedKelurahan,
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
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(responseData['message'] ?? 'Gagal menambahkan alamat')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menambah alamat. Coba lagi.')),
      );
    }
  }

  void _lihatLokasi() async {
    if (_kordinat != null && await canLaunch(_kordinat!)) {
      await launch(_kordinat!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 4),
            const Text(
              'Tambah Alamat',
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedKecamatanName,
                hint: const Text('Pilih Kecamatan'),
                onChanged: (newValue) {
                  setState(() {
                    _selectedKecamatanName = newValue;
                    _selectedKelurahan = null;
                  });
                },
                items: _kecamatanList.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['nama_kecamatan'],
                    child: Text(item['nama_kecamatan']),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  labelText: "Kecamatan",
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedKelurahan,
                hint: const Text('Pilih Kelurahan'),
                onChanged: _selectedKecamatanName != null
                    ? (newValue) {
                        setState(() => _selectedKelurahan = newValue);
                      }
                    : null,
                items: _selectedKecamatanName != null
                    ? _kelurahanMap[_selectedKecamatanName]!
                        .map((value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList()
                    : [],
                decoration: const InputDecoration(
                  labelText: "Kelurahan",
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Rumah, Toko, RT/RW)',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Ambil Lokasi'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _kordinat == null
                          ? "Lokasi belum diambil"
                          : "Lokasi berhasil diambil",
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
                  child: TextButton.icon(
                    onPressed: _lihatLokasi,
                    icon: const Icon(Icons.map),
                    label: const Text('Lihat Lokasi di Google Maps'),
                  ),
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _tambahAlamat,
                  icon: const Icon(Icons.save),
                  label: const Text('Simpan Alamat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
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
