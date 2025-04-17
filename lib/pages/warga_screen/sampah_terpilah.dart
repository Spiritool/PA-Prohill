import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:dlh_project/pages/warga_screen/home.dart';

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

  Future<void> fetchData() async {
    await Future.wait([
      _fetchKecamatanData(),
      _fetchAlamatData(),
    ]);
  }

  Future<void> _fetchKecamatanData() async {
    const String url = "https://jera.kerissumenep.com/api/kecamatan";
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
          Uri.parse(
              'https://jera.kerissumenep.com/api/alamat/get-by-user/$userId'),
          headers: {"Accept": "application/json"});

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data['success']) {
          setState(() {
            _alamatList = List<Map<String, dynamic>>.from(data['data'] ?? []);
          });
        } else {
          _showErrorDialog('Data Alamat Kosong atau Gagal Diambil');
        }
      } else {
        _showErrorDialog(
            'Terjadi kesalahan dalam pengambilan data. Status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
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
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('user_id');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://jera.kerissumenep.com/api/pengangkutan-sampah/store'),
      );

      request.fields['id_kecamatan'] = _pilihKecamatan!;
      request.fields['id_alamat'] = _pilihAlamat!;
      request.fields['id_user_warga'] = userId.toString();
      request.fields['deskripsi'] = _deskripsi;

      var file = await http.MultipartFile.fromPath('foto_sampah', _image!.path);
      request.files.add(file);

      var response = await request.send();

      if (response.statusCode == 201) {
        _showSuccessDialog('Data berhasil dikirim');
      } else {
        _showErrorDialog(
            'Gagal mengirimkan Data. Status: ${response.statusCode}');
      }
    } catch (e) {
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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Sampah Daur Ulang',
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
                color: const Color(
                    0xFFE0F2F7), // Warna latar belakang header (sesuaikan dengan foto)
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Sampah Daur Ulang',
                    style: TextStyle(
                      color: Colors.black, // Warna teks seperti di foto
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(
                              0, -15), // Nilai negatif untuk geser ke atas
                          child: Image.asset(
                            'assets/images/SampahDaurulang.png',
                            height: 100,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Sampah Daur Ulang Adalah sampah yang dipisahkan berdasarkan jenis sebelum dibuang, memudahkan pengelolaan dan mengurangi dampak lingkungan.",
                                style: TextStyle(
                                  color: Colors
                                      .black, // Warna teks seperti di foto
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 10),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data Laporan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _pilihKecamatan,
                          hint: const Text('Pilih Kecamatan'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _pilihKecamatan = newValue;
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
                        DropdownButtonFormField<String>(
                          value: _pilihAlamat,
                          hint: const Text('Pilih Alamat'),
                          onChanged: (String? newValue) {
                            setState(() {
                              _pilihAlamat = newValue;
                            });
                          },
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
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
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
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _deskripsi = value;
                          },
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
                  onPressed: () {
                    _submitForm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF64B5F6), // Warna tombol "Laporkan"
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
