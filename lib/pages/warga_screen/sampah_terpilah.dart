import 'dart:io';
import 'dart:convert';
import 'package:dlh_project/constant/color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:dlh_project/pages/warga_screen/home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class SampahTerpilah extends StatefulWidget {
  const SampahTerpilah({super.key});

  @override
  _SampahTerpilahState createState() => _SampahTerpilahState();
}

class _SampahTerpilahState extends State<SampahTerpilah> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _locationController = TextEditingController();
  String? _latitude;
  String? _longitude;
  bool _locationFetched = false;
  String? _locationUrl;
  bool _photoSelected = false;

  List<Map<String, dynamic>> _alamatList = [];
  List<Map<String, dynamic>> _kecamatanList = [];
  String? _pilihKecamatan;
  String? _pilihAlamat;
  String _deskripsi = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
        _photoSelected = true;
      });
    }
  }

  void _showImageSourceSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Pilih Sumber Foto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Kamera',
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImage(ImageSource.camera);
                  }),
              _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Galeri',
                  onTap: () {
                    Navigator.of(context).pop();
                    _getImage(ImageSource.gallery);
                  }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: black.withOpacity(0.1),
            child: Icon(icon, size: 28, color: black),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: black)),
        ],
      ),
    );
  }

  Future<void> fetchData() async {
    await Future.wait([
      _fetchKecamatanData(),
      _fetchAlamatData(),
    ]);
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
        _showErrorDialog('Failed to load kecamatan data');
      }
    } catch (e) {
      _showErrorDialog('Error fetching kecamatan data: $e');
    }
  }

  Future<void> _fetchAlamatData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');

      var response = await http.get(
          Uri.parse('$baseipapi/api/alamat/get-by-user/$userId'),
          headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['success']) {
          List<Map<String, dynamic>> alamatData =
              List<Map<String, dynamic>>.from(data['data'] ?? []);

          setState(() {
            _alamatList = alamatData;
          });

          // Cek jika alamat kosong, tampilkan popup
          if (alamatData.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showAlamatKosongDialog();
            });
          }
        } else {
          // Jika response tidak success, kemungkinan alamat kosong
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAlamatKosongDialog();
          });
        }
      } else {
        _showErrorDialog(
            'Terjadi kesalahan dalam pengambilan data. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showAlamatKosongDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa dismiss dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 320,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4CAF50),
                  Color(0xFF66BB6A),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan icon
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Alamat Belum Tersedia',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Content
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Untuk melaporkan sampah, Anda perlu mengisi alamat terlebih dahulu.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Langkah-langkah
                      const Text(
                        'Langkah mudah mengisi alamat:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D50),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildStepItem(
                        number: '1',
                        title: 'Buka Menu Akun',
                        description: 'Tap ikon profil di pojok kanan atas',
                        icon: Icons.account_circle,
                      ),

                      _buildStepItem(
                        number: '2',
                        title: 'Pilih Contact Info',
                        description: 'Cari dan pilih menu "Contact Info"',
                        icon: Icons.contact_mail,
                      ),

                      _buildStepItem(
                        number: '3',
                        title: 'Tambah Alamat',
                        description: 'Isi detail alamat lengkap Anda',
                        icon: Icons.add_location,
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context)
                                    .pop(); // Kembali ke halaman sebelumnya
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side:
                                    const BorderSide(color: Color(0xFF4CAF50)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Nanti Saja',
                                style: TextStyle(
                                  color: Color(0xFF4CAF50),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                                // Navigasi ke halaman contact info/alamat
                                // Ganti dengan route yang sesuai dengan aplikasi Anda
                                // Navigator.pushNamed(context, '/contact-info');

                                // Atau jika ada navigator spesifik untuk alamat:
                                // Navigator.push(context, MaterialPageRoute(
                                //   builder: (context) => ContactInfoPage(),
                                // ));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Isi Alamat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepItem({
    required String number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are not enabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        _showErrorDialog('Location permissions are not granted');
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
        _locationUrl =
            'geo:${position.latitude},${position.longitude}?q=${position.latitude},${position.longitude}';
        _locationController.text = 'Sudah mendapatkan lokasi Anda';
        _locationFetched = true;
      });
    } catch (e) {
      _showErrorDialog('Error getting location: $e');
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

  void _launchURL() async {
    if (_locationUrl != null) {
      final url = _locationUrl!;
      try {
        if (await canLaunch(url)) {
          await launch(
            url,
            forceSafariVC: false,
            forceWebView: false,
          );
        } else {
          _showErrorDialog('Could not launch URL: $url');
        }
      } catch (e) {
        _showErrorDialog('Error launching URL: $e');
      }
    } else {
      _showErrorDialog('Location URL is null');
    }
  }

  Future<void> _submitForm() async {
    if (_pilihKecamatan == null ||
        _pilihAlamat == null ||
        _image == null ||
        _deskripsi.isEmpty) {
      _showErrorDialog('Pastikan semua data terisi!');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseipapi/api/pengangkutan-sampah/store'),
      );

      request.fields['id_kecamatan'] = _pilihKecamatan!;
      request.fields['id_alamat'] = _pilihAlamat!;
      request.fields['id_user_warga'] = userId.toString();
      request.fields['deskripsi'] = _deskripsi;

      var file = await http.MultipartFile.fromPath('foto_sampah', _image!.path);
      request.files.add(file);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog loading

      if (response.statusCode == 201) {
        _showSuccessDialog('Data berhasil dikirim');
      } else {
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
        _showErrorDialog(
            'Gagal mengirimkan data.\nStatus: ${response.statusCode}\n\nBody: ${response.body}');
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Tutup dialog loading
      debugPrint('Exception: $e');
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
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
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Sampah Daur Ulang',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2E7D50),
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E7D50),
              size: 20,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // Header Card dengan Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4CAF50),
                    Color(0xFF81C784),
                    Color(0xFFA5D6A7),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '♻️ Sampah Daur Ulang',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.recycling,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mari Jaga Lingkungan! 🌱",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Sampah daur ulang adalah sampah yang dipisahkan berdasarkan jenis sebelum dibuang, memudahkan pengelolaan dan mengurangi dampak lingkungan.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Form Card dengan Modern Design
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Color(0xFF4CAF50),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Data Laporan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D50),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Kecamatan Dropdown
                  // _buildModernDropdown(
                  //   value: _pilihKecamatan,
                  //   hint: 'Pilih Kecamatan',
                  //   icon: Icons.location_city,
                  //   items: _kecamatanList.map<DropdownMenuItem<String>>(
                  //     (Map<String, dynamic> item) {
                  //       return DropdownMenuItem<String>(
                  //         value: item['id'].toString(),
                  //         child: Text(item['nama_kecamatan'].toString()),
                  //       );
                  //     },
                  //   ).toList(),
                  //   onChanged: (String? newValue) {
                  //     setState(() {
                  //       _pilihKecamatan = newValue;
                  //     });
                  //   },
                  // ),

                  const SizedBox(height: 20),

                  // Alamat Dropdown
                  _buildModernDropdown(
                    value: _pilihAlamat,
                    hint: 'Pilih Alamat Lengkap',
                    icon: Icons.place,
                    items: _alamatList.map<DropdownMenuItem<String>>(
                      (Map<String, dynamic> item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(
                            '${item['kelurahan']}, ${item['kecamatan']}, ${item['deskripsi']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _pilihAlamat = newValue;

                        // Auto select kecamatan berdasarkan alamat yang dipilih
                        if (newValue != null) {
                          // Method 1: Menggunakan try-catch (Recommended)
                          try {
                            var selectedAlamat = _alamatList.firstWhere(
                              (alamat) => alamat['id'].toString() == newValue,
                            );

                            // Jika ada field id_kecamatan langsung
                            if (selectedAlamat.containsKey('id_kecamatan') &&
                                selectedAlamat['id_kecamatan'] != null) {
                              _pilihKecamatan =
                                  selectedAlamat['id_kecamatan'].toString();
                            }
                            // Cari berdasarkan nama kecamatan
                            else if (selectedAlamat.containsKey('kecamatan')) {
                              try {
                                var matchingKecamatan =
                                    _kecamatanList.firstWhere(
                                  (kecamatan) =>
                                      kecamatan['nama_kecamatan']
                                          .toString()
                                          .toLowerCase()
                                          .trim() ==
                                      selectedAlamat['kecamatan']
                                          .toString()
                                          .toLowerCase()
                                          .trim(),
                                );
                                _pilihKecamatan =
                                    matchingKecamatan['id'].toString();
                              } catch (e) {
                                debugPrint(
                                    'Kecamatan tidak ditemukan: ${selectedAlamat['kecamatan']}');
                              }
                            }
                          } catch (e) {
                            debugPrint(
                                'Alamat tidak ditemukan dengan id: $newValue');
                          }
                        } else {
                          // Reset kecamatan jika alamat dikosongkan
                          _pilihKecamatan = null;
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Photo Upload Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _photoSelected
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      color: _photoSelected
                          ? const Color(0xFF4CAF50).withOpacity(0.05)
                          : Colors.grey.shade50,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _photoSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _photoSelected
                              ? Icons.check_circle
                              : Icons.camera_alt,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Foto Sampah',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        _photoSelected
                            ? '✅ Foto sudah dipilih'
                            : '📷 Tap untuk mengambil foto',
                        style: TextStyle(
                          color: _photoSelected
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: _showImageSourceSelection,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Photo Preview
                  if (_photoSelected && _image != null)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Description Field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      color: Colors.grey.shade50,
                    ),
                    child: TextField(
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Sampah',
                        labelStyle: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        hintText:
                            'Jelaskan kondisi dan jenis sampah yang ditemukan...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        _deskripsi = value;
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // Modern Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF4CAF50),
                Color(0xFF66BB6A),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4CAF50).withOpacity(0.4),
                spreadRadius: 0,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              _submitForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Laporkan Sekarang!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Helper method untuk membuat dropdown yang modern
  Widget _buildModernDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              hint,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        onChanged: onChanged,
        items: items,
        isExpanded: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Colors.white,
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 16,
        ),
      ),
    );
  }
}
