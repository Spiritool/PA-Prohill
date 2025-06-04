import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black87, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Tambah Alamat',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF6600).withOpacity(0.1),
                      const Color(0xFFFF6600).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFFF6600).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6600),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Alamat',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lengkapi data alamat Anda dengan detail',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Form Section
              _buildModernDropdown(
                value: _selectedKecamatanName,
                hint: 'Pilih Kecamatan',
                label: 'Kecamatan',
                icon: Icons.map_outlined,
                items: _kecamatanList.map((item) {
                  return DropdownMenuItem<String>(
                    value: item['nama_kecamatan'],
                    child: Text(item['nama_kecamatan']),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedKecamatanName = newValue;
                    _selectedKelurahan = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              _buildModernDropdown(
                value: _selectedKelurahan,
                hint: 'Pilih Kelurahan',
                label: 'Kelurahan',
                icon: Icons.location_city,
                items: _selectedKecamatanName != null
                    ? _kelurahanMap[_selectedKecamatanName]!
                        .map((value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList()
                    : [],
                onChanged: _selectedKecamatanName != null
                    ? (newValue) {
                        setState(() => _selectedKelurahan = newValue);
                      }
                    : null,
              ),

              const SizedBox(height: 20),

              _buildModernTextField(
                controller: _deskripsiController,
                label: 'Deskripsi',
                hint: 'Contoh: Rumah, Toko, RT/RW',
                icon: Icons.description_outlined,
              ),

              const SizedBox(height: 24),

              // Location Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi GPS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: _isLoading
                                  ? LinearGradient(
                                      colors: [
                                        Colors.grey[300]!,
                                        Colors.grey[200]!
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6600),
                                        Color(0xFFFF8833)
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFFF6600).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isLoading ? null : _getCurrentLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.my_location,
                                      color: Colors.white),
                              label: Text(
                                _isLoading ? 'Mengambil...' : 'Ambil Lokasi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _kordinat == null
                            ? Colors.red[50]
                            : Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _kordinat == null
                              ? Colors.red[200]!
                              : Colors.green[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _kordinat == null
                                ? Icons.location_off
                                : Icons.check_circle,
                            color: _kordinat == null
                                ? Colors.red[600]
                                : Colors.green[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _kordinat == null
                                ? "Lokasi belum diambil"
                                : "Lokasi berhasil diambil",
                            style: TextStyle(
                              color: _kordinat == null
                                  ? Colors.red[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_kordinat != null) ...[
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _lihatLokasi,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6600),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                        ),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text(
                          'Lihat Lokasi di Google Maps',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6600), Color(0xFFFF8833)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6600).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _tambahAlamat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text(
                    'Simpan Alamat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required String hint,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(
              hint,
              style: TextStyle(color: Colors.grey[600]),
            ),
            onChanged: onChanged,
            items: items,
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: const Color(0xFFFF6600),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFFFF6600),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
