import 'dart:convert';
import 'dart:io';
import 'package:dlh_project/constant/color.dart';
import 'package:dlh_project/pages/warga_screen/home.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Add this for opening location in Google Maps
import 'package:flutter_dotenv/flutter_dotenv.dart';

final baseipapi = dotenv.env['LOCAL_IP'];

class SampahLiar extends StatefulWidget {
  const SampahLiar({super.key});

  @override
  _SampahLiarState createState() => _SampahLiarState();
}

class _SampahLiarState extends State<SampahLiar> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController =
      TextEditingController(text: '62');
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _latitude;
  String? _longitude;
  bool _locationFetched = false;
  bool _photoSelected = false;
  bool _isLoading = false;
  bool _isLocationLoading = false;

  List<Map<String, dynamic>> _kecamatanList = [];
  String? _selectedKecamatanId;

  @override
  void initState() {
    super.initState();
    _fetchKecamatanData();
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
        throw Exception('Failed to load kecamatan data');
      }
    } catch (e) {
      _showErrorDialog('Error fetching kecamatan data: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLocationLoading = true; // Show loading indicator
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog('Location services are not enabled');
      setState(() {
        _isLocationLoading = false; // Hide loading indicator
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Location permissions are permanently denied');
        setState(() {
          _isLocationLoading = false; // Hide loading indicator
        });
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
        _locationController.text = 'Sudah mendapatkan lokasi Anda';
        _locationFetched = true;
        _isLocationLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Error getting location: $e');
      setState(() {
        _isLocationLoading = false;
      });
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

  Future<void> _submitForm() async {
    if (_locationFetched &&
        _photoSelected &&
        _emailController.text.isNotEmpty &&
        _phoneNumberController.text.isNotEmpty &&
        _deskripsiController.text.isNotEmpty &&
        _selectedKecamatanId != null) {
      setState(() {
        _isLoading = true;
      });
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
        var request = http.MultipartRequest(
          'POST',
          Uri.parse(
              '$baseipapi/api/pengangkutan-sampah-liar/store'),
        );
        request.fields['id_kecamatan'] = _selectedKecamatanId!;
        request.fields['email'] = _emailController.text;
        request.fields['no_hp'] = _phoneNumberController.text;
        request.fields['deskripsi'] = _deskripsiController.text;
        request.fields['kordinat'] =
            'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude'; // Ensure correct format
        if (_image != null) {
          request.files.add(
            await http.MultipartFile.fromPath('foto_sampah', _image!.path),
          );
        }

        var response = await request.send();

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Laporan berhasil dikirim!')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // Get error detail from response
          final responseBody = await http.Response.fromStream(response);
          _showErrorDialog(
              'Gagal mengirim laporan. Pesan: ${responseBody.body}');
        }
      } catch (e) {
        _showErrorDialog('Terjadi kesalahan: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      _showErrorDialog('Pastikan semua data telah diisi.');
    }
  }

  Future<void> _openMap() async {
    if (_latitude != null && _longitude != null) {
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude'; // Ensure correct URL format
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        _showErrorDialog('Tidak dapat membuka Google Maps.');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneNumberController.dispose();
    _deskripsiController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pelaporan Sampah Liar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF1E293B),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF64748B), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                      Color(0xFFB91C1C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.report_gmailerrorred_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Laporkan Sampah Liar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Bantu jaga lingkungan dengan melaporkan sampah liar di sekitar Anda",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment_rounded,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Form Pelaporan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Dropdown Kecamatan
                    _buildFormField(
                      label: 'Pilih Kecamatan',
                      icon: Icons.location_city_rounded,
                      child: DropdownButtonFormField<String>(
                        value: _selectedKecamatanId,
                        hint: const Text('Pilih Kecamatan',
                            style: TextStyle(color: Color(0xFF94A3B8))),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedKecamatanId = newValue;
                          });
                        },
                        items: _kecamatanList.map<DropdownMenuItem<String>>(
                          (Map<String, dynamic> item) {
                            return DropdownMenuItem<String>(
                              value: item['id'].toString(),
                              child: Text(item['nama_kecamatan'].toString()),
                            );
                          },
                        ).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFF3B82F6), width: 2),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Phone Number Field
                    _buildFormField(
                      label: 'Nomor Handphone',
                      icon: Icons.phone_rounded,
                      child: TextField(
                        controller: _phoneNumberController,
                        decoration: _getInputDecoration('Contoh: 628123456789'),
                        keyboardType: TextInputType.phone,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    _buildFormField(
                      label: 'Alamat Email',
                      icon: Icons.email_rounded,
                      child: TextField(
                        controller: _emailController,
                        decoration:
                            _getInputDecoration('Contoh: nama@email.com'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Location Field
                    _buildFormField(
                      label: 'Lokasi Kejadian',
                      icon: Icons.place_rounded,
                      child: TextField(
                        controller: _locationController,
                        decoration: _getInputDecoration(
                          _locationFetched
                              ? 'Lokasi berhasil didapatkan'
                              : 'Tekan tombol untuk mendapatkan lokasi',
                        ).copyWith(
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _locationFetched
                                  ? Colors.green
                                  : const Color(0xFF3B82F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isLocationLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      _locationFetched
                                          ? Icons.check_circle
                                          : Icons.my_location,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: _getCurrentLocation,
                                  ),
                          ),
                        ),
                        readOnly: true,
                      ),
                    ),

                    if (_locationFetched) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: _openMap,
                          icon: const Icon(Icons.map_rounded, size: 18),
                          label: const Text('Lihat di Peta'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            backgroundColor:
                                const Color(0xFF3B82F6).withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Photo Field
                    _buildFormField(
                      label: 'Foto Sampah',
                      icon: Icons.camera_alt_rounded,
                      child: GestureDetector(
                        onTap: _showImageSourceSelection,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _photoSelected
                                      ? Colors.green
                                      : const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _photoSelected
                                      ? Icons.check_circle
                                      : Icons.add_a_photo,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _photoSelected
                                      ? 'Foto berhasil diambil'
                                      : 'Tap untuk mengambil foto',
                                  style: TextStyle(
                                    color: _photoSelected
                                        ? Colors.green
                                        : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_photoSelected && _image != null) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_image!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Description Field
                    _buildFormField(
                      label: 'Deskripsi Tambahan',
                      icon: Icons.description_rounded,
                      child: TextField(
                        controller: _deskripsiController,
                        decoration: _getInputDecoration(
                            'Jelaskan kondisi sampah secara detail...'),
                        maxLines: 4,
                        textAlignVertical: TextAlignVertical.top,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

// Helper method untuk membuat form field yang konsisten
  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

// Helper method untuk input decoration yang konsisten
  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
