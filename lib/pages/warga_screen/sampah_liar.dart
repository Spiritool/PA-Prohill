import 'dart:convert';
import 'dart:io';
import 'package:dlh_project/pages/warga_screen/home.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Add this for opening location in Google Maps

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
          title: const Text('Pilih Sumber Foto'),
          actions: [
            TextButton(
              child: const Text('Kamera'),
              onPressed: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.camera);
              },
            ),
            TextButton(
              child: const Text('Galeri'),
              onPressed: () {
                Navigator.of(context).pop();
                _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
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
              'http://10.251.134.25:8000/api/pengangkutan-sampah-liar/store'),
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Sampah Liar',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Sampah Liar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/images/trash.png',
                          height: 100,
                        ),
                        const SizedBox(width: 30),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sampah liar adalah sampah yang dibuang sembarangan, seperti di jalanan, area umum, dan tempat-tempat lainnya yang tidak diizinkan.",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Data Laporan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedKecamatanId,
                          hint: const Text('Pilih Kecamatan'),
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
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _phoneNumberController,
                          decoration: const InputDecoration(
                            labelText: 'No. HP ( Awali 62 )',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            labelText: 'Lokasi',
                            border: const OutlineInputBorder(),
                            suffixIcon: _isLocationLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(),
                                  )
                                : IconButton(
                                    icon: _locationFetched
                                        ? const Icon(Icons.check_circle,
                                            color: Colors.green)
                                        : const Icon(Icons.location_on),
                                    onPressed: _getCurrentLocation,
                                  ),
                            hintText: _locationFetched
                                ? 'Sudah mendapatkan lokasi Anda'
                                : 'Belum mendapatkan lokasi',
                            hintStyle: TextStyle(
                              color:
                                  _locationFetched ? Colors.green : Colors.red,
                            ),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 10),
                        if (_locationFetched)
                          TextButton(
                            onPressed: _openMap,
                            child: const Text('Lihat Lokasi'),
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Foto Sampah',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: _photoSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green)
                                  : const Icon(Icons.camera_alt),
                              onPressed: _showImageSourceSelection,
                            ),
                            hintText: _photoSelected
                                ? 'Sudah mendapatkan foto'
                                : 'Belum mendapatkan foto',
                            hintStyle: TextStyle(
                              color: _photoSelected ? Colors.green : Colors.red,
                            ),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 10),
                        if (_photoSelected && _image != null)
                          Image.file(
                            File(_image!.path),
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _deskripsiController,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            BottomAppBar(
              color: Colors.transparent,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 57, 87, 254),
                  ),
                  child: const Text(
                    'Laporkan!',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
